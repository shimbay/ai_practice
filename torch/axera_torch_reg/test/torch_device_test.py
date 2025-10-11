import logging
import time

import torch
from loguru import logger

import axera_simulator
import axera_torch_reg
from axera_simulator.common import axera_runtime as rt


def test_device_tensor():
    logger.warning(f"host to device 0 memcpy")
    h_0 = torch.rand(4, 4)
    d0_0 = h_0.to("axera")
    d0_1 = h_0.to("axera")

    logger.warning(f"device add.out, device compare")
    d0_2 = d0_0 + d0_1
    assert torch.equal((h_0 * 2).to(d0_2.device), d0_2)

    logger.warning(f"device add_, device compare")
    d0_1.add_(d0_0)
    assert torch.equal((h_0 * 2).to(d0_1.device), d0_1)

    logger.warning("device 0 to host memcpy")
    h_1 = d0_0.to("cpu")

    assert torch.equal(h_0, h_1)

    logger.warning("host to device 1 memcpy")
    d1_0 = h_1.to("axera:1")

    logger.warning("device 1 to host slice memcpy")
    h_2 = torch.rand(2, 2)
    d1_0[:2, :2] = h_2

    assert torch.equal(d1_0[:2, :2].cpu(), h_2)

    d1_1 = h_2.to(d1_0.device)

    assert torch.equal(d1_0[:2, :2], d1_1)
    assert torch.equal(d1_0[2:, 2:].cpu(), d0_0[2:, 2:].cpu())


def test_stream():
    # stream 0 timer
    t0_start, t0_end, t1_start, t1_end = 0, 0, 0, 0
    # stream 1 timer
    t2_start, t2_end, t3_start, t3_end = 0, 0, 0, 0

    s0_0 = torch.Stream(device="axera")
    s0_1 = torch.Stream(device="axera")
    e0_0 = torch.Event(device="axera", enable_timing=True)
    e0_1 = torch.Event(device="axera", enable_timing=True)

    with s0_0:
        assert s0_0.query()

        def _():
            nonlocal t0_start, t0_end
            t0_start = time.time()
            time.sleep(0.3)
            t0_end = time.time()

        rt.launch(_, s0_0.device_index, s0_0.stream_id)
        e0_0.record(s0_0)

        assert not s0_0.query()

        with s0_1:

            def _():
                nonlocal t2_start, t2_end
                t2_start = time.time()
                time.sleep(0.1)
                t2_end = time.time()

            rt.launch(_, s0_1.device_index, s0_1.stream_id)

            s0_1.wait_stream(s0_0)

            def _():
                nonlocal t3_start, t3_end
                t3_start = time.time()
                time.sleep(0.1)
                t3_end = time.time()

            rt.launch(_, s0_1.device_index, s0_1.stream_id)

        def _():
            nonlocal t1_start, t1_end
            t1_start = time.time()
            time.sleep(0.2)
            t1_end = time.time()

        rt.launch(_, s0_0.device_index, s0_0.stream_id)
        e0_1.record(s0_0)

        # async launch
        assert (
            t0_end == 0 and t1_end == 0 and t2_end == 0 and t3_end == 0
        ), f"{t0_end=}, {t1_end=}, {t2_end=}, {t3_end=}"

        s0_0.synchronize()
        s0_1.synchronize()

        assert (
            t0_end > 0 and t1_end > 0 and t0_end > 0 and t1_end > 0
        ), f"{t0_end=}, {t1_end=}, {t2_end=}, {t3_end=}"

        assert (
            t0_start < t0_end < t1_start < t1_end
            and t2_start < t2_end < t3_start < t3_end
        ), f"{t0_start=}, {t0_end=}, {t1_start=}, {t1_end}, {t2_start=}, {t2_end=}, {t3_start=}, {t3_end}"

        assert t2_start < t0_end, f"{t2_start=}, {t0_end=}"
        assert t3_start > t0_end, f"{t3_start=}, {t0_end=}"

        logger.info(
            f"{t0_start=}, {t0_end=}, {t1_start=}, {t1_end=}, {t2_start=}, {t2_end=}, {t3_start=}, {t3_end=}"
        )

        cost_ms = e0_0.elapsed_time(e0_1)
        assert 200 < cost_ms < 202, f"{cost_ms=}"


try:
    test_device_tensor()
    test_stream()
except Exception as e:
    raise e
finally:
    rt.stop()
