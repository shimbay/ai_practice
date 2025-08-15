import torch
import numpy as np


Q = 4
D = 128
N = 32

q = np.random.rand(Q, D)
k = np.random.rand(N, D)
v = np.random.rand(N, D)


expected = (
    torch.softmax(torch.tensor(q) @ torch.transpose(torch.tensor(k), 0, 1), dim=1) @ v
).numpy()


def flash_attention(q, k, v):
    BR = 2
    BC = 4
    TR = q.shape[0] // BR
    TC = k.shape[0] // BC

    output = np.zeros_like(q)
    for r_idx in range(0, TR):
        previous_m = np.ones((BR, 1)) * np.finfo(np.float32).min
        previous_exp_sum = np.zeros((BR, 1))
        _q = q[r_idx * BR : (r_idx + 1) * BR, :]

        for c_idx in range(0, TC):
            _k = k[c_idx * BC : (c_idx + 1) * BC, :]
            _v = v[c_idx * BC : (c_idx + 1) * BC, :]

            # [BR, D] bf16 @ [D, BC] bf16 -> [BR, BC] fp32
            _p = _q @ np.transpose(_k)
            # sum([BR, BC + 1] fp32) -> [BR] fp32
            new_m = np.max(
                np.concatenate((previous_m, _p), axis=-1),
                axis=-1,
                keepdims=True,
            )

            # [BR] fp32 - [BR] fp32 -> [BR] fp32
            # exp([BR] fp32) -> [BR] fp32
            scale = np.exp(previous_m - new_m)
            # [BR] fp32 * [BR] fp32 -> [BR] fp32
            scaled_previous_exp_sum = previous_exp_sum * scale

            # [BR, BC] fp32 - [BR] fp32 -> [BR, BC] fp32
            # exp([BR, BC] fp32) -> [BR, BC] fp32
            _p = np.exp(_p - new_m)
            # sum([BR, BC + 1]) fp32 -> [BR] fp32
            new_exp_sum = np.sum(
                np.concatenate((scaled_previous_exp_sum, _p), axis=-1),
                axis=-1,
                keepdims=True,
            )

            # [BR, D] * [BR] fp32 -> [BR, D] fp32
            output[r_idx * BR : (r_idx + 1) * BR, :] *= scale
            # [BR, BC] bf16 @ [BC, D] bf16 -> [BR, D] fp32
            # [BR, D] + [BR, D] fp32 -> [BR, D] fp32
            output[r_idx * BR : (r_idx + 1) * BR, :] += _p @ _v

            previous_m = new_m
            previous_exp_sum = new_exp_sum

        output[r_idx * BR : (r_idx + 1) * BR, :] /= previous_exp_sum

    return output


got = flash_attention(q, k, v)
np.testing.assert_allclose(expected, got)
