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
        r_m = np.ones((BR, 1)) * np.finfo(np.float32).min
        r_exp_sum = np.zeros((BR, 1))
        _q = q[r_idx * BR : (r_idx + 1) * BR, :]

        for c_idx in range(0, TC):
            _k = k[c_idx * BC : (c_idx + 1) * BC, :]
            _v = v[c_idx * BC : (c_idx + 1) * BC, :]

            _p = _q @ np.transpose(_k)
            new_m = np.max(
                np.concatenate((r_m, _p), axis=-1),
                axis=-1,
                keepdims=True,
            )

            _p = np.exp(_p - new_m)
            new_exp_sum = np.sum(
                np.concatenate((r_exp_sum * np.exp(r_m - new_m), _p), axis=-1),
                axis=-1,
                keepdims=True,
            )

            scale = np.exp(r_m - new_m) / new_exp_sum * r_exp_sum
            output[r_idx * BR : (r_idx + 1) * BR, :] = (
                output[r_idx * BR : (r_idx + 1) * BR, :] * scale
                + (_p / new_exp_sum) @ _v
            )

            r_m = new_m
            r_exp_sum = new_exp_sum

    return output


got = flash_attention(q, k, v)
np.testing.assert_allclose(expected, got)
