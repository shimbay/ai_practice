import torch
import numpy as np


data = np.random.rand(3, 4)
print(data)

expected = torch.softmax(torch.from_numpy(data), 1).numpy()


def softmax0(data):
    m = np.max(data, -1)
    d = np.zeros(data.shape[:-1])
    for k in range(data.shape[-1]):
        d += np.exp(data[:, k] - m)

    res = np.zeros(data.shape)
    for k in range(data.shape[-1]):
        res[:, k] = np.exp(data[:, k] - m) / d
    return res


got0 = softmax0(data)
print(got0)
np.testing.assert_allclose(expected, got0)


def softmax1(data):
    last_m = data[:, 0]
    last_d = np.ones(data.shape[:-1])

    for k in range(1, data.shape[-1]):
        new_last_m = np.maximum(last_m, data[:, k])
        last_d = last_d * np.exp(last_m - new_last_m) + np.exp(data[:, k] - new_last_m)
        last_m = new_last_m

    res = np.zeros(data.shape)
    for k in range(data.shape[-1]):
        res[:, k] = np.exp(data[:, k] - last_m) / last_d
    return res


got1 = softmax1(data)
print(got1)
np.testing.assert_allclose(expected, got1)
