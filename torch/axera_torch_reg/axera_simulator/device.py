import threading
import time
from dataclasses import dataclass, field
from functools import partial
from threading import Event, Lock, Thread
from typing import Callable, List, OrderedDict, Set, Tuple

import numpy as np
import torch
from loguru import logger

DEFAULT_DEVICE_WORKER = -1
DEVICE_MEMORY_SIZE = 1 << 30
DEVICE_WORKER_NUM = 4


@dataclass
class DeviceDaemon:
    index: int
    memory_base: int = 0
    memory: torch.Tensor = field(init=False)
    # dict[start, size]
    allocated_memory: dict[int, int] = field(default_factory=OrderedDict)

    l: Lock = field(default_factory=Lock)
    # List[Tuple[time, stream, priority, task, signal]]
    taskq: List[Tuple[float, int, int, Callable, Event]] = field(default_factory=list)
    running_stream: Set[int] = field(default_factory=set)

    running: bool = True
    workers: List[Thread] = field(default_factory=list)

    def _run(self, worker_id):
        while self.running:
            s = None
            t = None
            sig = None

            with self.l:
                for i, item in enumerate(self.taskq):
                    _time, _stream, _priority, _task, _sig = item
                    if _stream in self.running_stream:
                        continue

                    t = _task
                    s = _stream
                    sig = _sig
                    self.taskq.pop(i)
                    self.running_stream.add(s)
                    break

            if s is None or t is None or sig is None:
                time.sleep(0.01)
                continue

            logger.info(f"worker: {self.index}:{worker_id}, stream: {s}, task: {t}")

            try:
                t()
            except Exception as e:
                raise e
            finally:
                sig.set()
                with self.l:
                    self.running_stream.remove(s)

    def __post_init__(self):
        for i in range(DEVICE_WORKER_NUM):
            t = Thread(target=partial(self._run, i))
            self.workers.append(t)
            t.start()
        self.memory = torch.zeros(DEVICE_MEMORY_SIZE, dtype=torch.int8)
        self.memory_base = (self.index + 1) * DEVICE_MEMORY_SIZE

    def stop(self):
        self.running = False

    @staticmethod
    def ptr_device(ptr: int) -> int:
        return int(ptr / DEVICE_MEMORY_SIZE) - 1

    def memory_view(self, t: torch.Tensor) -> torch.Tensor:
        assert t.device.type == "axera"
        assert t.device.index == self.index

        t_int8_view = t.view(torch.int8)
        view = torch.as_strided(
            self.memory,
            size=t_int8_view.shape,
            stride=t_int8_view.stride(),
            storage_offset=t_int8_view.untyped_storage().data_ptr()
            + t_int8_view.storage_offset()
            - self.memory_base,
        ).view(t.dtype)
        return view

    def submit(
        self, task: Callable, stream: int = 0, priority: int = 0
    ) -> threading.Event:
        assert task is not None
        assert stream is not None

        sig = threading.Event()

        with self.l:
            logger.info(f"submit device {self.index}, stream: {stream}, task: {task}")
            self.taskq.append((time.time(), stream, priority, task, sig))
            self.taskq.sort(
                key=lambda x: -x[1]
                * (np.iinfo(np.int64).max - np.int64(x[0] * 1000000))
            )

        return sig

    def query_stream(self, stream: int) -> bool:
        with self.l:
            if stream in self.running_stream:
                return False
            for _, _s, _, _, _ in self.taskq:
                if _s == stream:
                    return False
            return True

    def malloc(self, size: int) -> int:
        last_end = 0
        for cur_start, cur_size in self.allocated_memory.items():
            if cur_start - last_end >= size:
                break
            last_end = cur_start + cur_size
        self.allocated_memory[last_end] = size
        return last_end + self.memory_base

    def free(self, ptr: int):
        ptr -= self.memory_base
        assert ptr in self.allocated_memory, f"illegal ptr {ptr}"
        del self.allocated_memory[ptr]
