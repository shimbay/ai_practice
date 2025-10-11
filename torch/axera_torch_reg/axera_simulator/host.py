import threading
import time
from dataclasses import dataclass, field
from typing import Callable, Dict, OrderedDict, override

import torch

from axera_simulator.device import DeviceDaemon
from axera_torch_reg.interface import *

HOST_MEMORY_SIZE = 1 << 30
DEVICE_NUM = 4
DEFAULT_DEVICE = 0

PRIORITY_RANGE = range(0, 2)
# every priority has a stream pool
STREAM_POOL_SIZE = 32
DEFAULT_STREAM = 0


@dataclass
class Event:
    flag: int
    time: float = 0
    sig: threading.Event = field(default_factory=threading.Event)

    def record(self):
        self.time = time.time() * 1000
        self.sig.set()


@dataclass
class DeviceInfo:
    daemon: DeviceDaemon

    cur_stream: int = DEFAULT_STREAM
    default_stream: int = DEFAULT_STREAM

    stream_pool_counter: Dict[int, int] = field(default_factory=dict)

    def __post_init__(self):
        for p in PRIORITY_RANGE:
            self.stream_pool_counter[p] = -1


@dataclass
class HostDaemon(TorchBackendPythonInterface):
    device_num: int

    cur_device: int = DEFAULT_DEVICE
    devices: Dict[int, DeviceInfo] = field(default_factory=OrderedDict)

    memory: torch.Tensor = field(init=False)
    allocated_memory: Dict[int, int] = field(default_factory=OrderedDict)

    events: Dict[int, Event] = field(default_factory=dict)

    def __post_init__(self):
        self.memory = torch.zeros(HOST_MEMORY_SIZE, dtype=torch.int8)
        for i in range(self.device_num):
            self.devices[i] = DeviceInfo(
                daemon=DeviceDaemon(
                    index=i,
                ),
            )

    def launch(
        self,
        fn: Callable,
        device: int = -1,
        stream: int = -1,
        priority: int = 0,
    ) -> threading.Event:
        _device = self.devices[self.cur_device if device == -1 else device]
        _stream = _device.cur_stream if stream == -1 else stream

        return _device.daemon.submit(fn, _stream, priority)

    def stop(self):
        for d in self.devices.values():
            d.daemon.stop()

    def device(self, device: int) -> DeviceDaemon:
        return self.devices[device].daemon

    @override
    def hasPrimaryContext(
        self,
        device: int,
    ) -> bool:
        return True

    @override
    def deviceCount(self) -> device_id_t:
        return self.device_num

    @override
    def getDevice(self) -> device_id_t:
        return device_id_t(self.cur_device)

    @override
    def setDevice(
        self,
        device: device_id_t,
    ):
        self.cur_device = device if device != -1 else DEFAULT_DEVICE

    @override
    def uncheckedSetDevice(
        self,
        device: device_id_t,
    ):
        self.setDevice(device)

    @override
    def exchangeDevice(
        self,
        device: device_id_t,
    ) -> device_id_t:
        old_device = self.cur_device
        self.cur_device = device
        return old_device

    @override
    def malloc(
        self,
        size: int,
    ) -> ptr_t:
        ptr = self.devices[self.cur_device].daemon.malloc(size)
        return ptr_t(ptr)

    @override
    def free(
        self,
        ptr: ptr_t,
    ) -> bool:
        self.devices[DeviceDaemon.ptr_device(ptr)].daemon.free(ptr)
        return True

    @override
    def copyData(
        self,
        dest: ptr_t,
        src: ptr_t,
        count: int,
    ):
        device = self.devices[self.cur_device]
        device_memory = device.daemon.memory

        def _():
            device_memory[dest : dest + count] = device_memory[src : src + count]

        device.daemon.submit(_, stream=device.cur_stream)

    @override
    def isPinnedPtr(
        self,
        data: ptr_t,
    ) -> bool:
        return True

    @override
    def hostMalloc(
        self,
        size: int,
    ) -> ptr_t:
        last_end = 0
        for cur_start, cur_size in self.allocated_memory.items():
            if cur_start - last_end >= size:
                break
            last_end = cur_start + cur_size
        self.allocated_memory[last_end] = size
        return ptr_t(last_end)

    @override
    def hostFree(
        self,
        ptr: ptr_t,
    ) -> bool:
        assert ptr in self.allocated_memory
        del self.allocated_memory[ptr]
        return True

    @override
    def hostCopyData(
        self,
        dest: ptr_t,
        src: ptr_t,
        count: int,
    ):
        self.memory[dest : dest + count] = self.memory[src : src + count]

    @override
    def getNewStream(
        self,
        device: device_id_t,
        priority: int,
    ) -> stream_id_t:
        assert priority in PRIORITY_RANGE

        _device = self.devices[device if device != -1 else self.cur_device]
        _device.stream_pool_counter[priority] += 1
        return stream_id_t(_device.stream_pool_counter[priority] % STREAM_POOL_SIZE)

    @override
    def queryStream(
        self,
        stream: stream_id_t,
        device: device_id_t,
    ) -> bool:
        _device = self.devices[device if device != -1 else self.cur_device]

        return _device.daemon.query_stream(stream)

    @override
    def getStream(
        self,
        device: device_id_t,
    ) -> stream_id_t:
        _device = self.devices[device if device != -1 else self.cur_device]

        return stream_id_t(_device.cur_stream)

    @override
    def getStreamFromGlobalPool(
        self,
        device: device_id_t,
        is_high_priority: bool,
    ) -> stream_id_t:
        priority = 1 if is_high_priority else 0

        return self.getNewStream(device, priority)

    @override
    def getDefaultStream(
        self,
        device: device_id_t,
    ) -> stream_id_t:
        _device = self.devices[device if device != -1 else self.cur_device]
        return stream_id_t(_device.default_stream)

    @override
    def exchangeStream(
        self,
        stream: stream_id_t,
        device: device_id_t,
    ) -> stream_id_t:
        _device = self.devices[device if device != -1 else self.cur_device]
        cur_stream = _device.cur_stream
        _device.cur_stream = stream
        return stream_id_t(cur_stream)

    @override
    def synchronizeStream(
        self,
        stream: stream_id_t,
        device: device_id_t,
    ):
        _device = self.devices[device if device != -1 else self.cur_device]

        def _():
            pass

        _device.daemon.submit(_, stream=stream).wait()

    @override
    def synchronizeDevice(
        self,
        device: device_id_t,
    ):
        _device = self.devices[device if device != -1 else self.cur_device]

        def _():
            pass

        sigs = []
        for stream_id in range(len(PRIORITY_RANGE) * STREAM_POOL_SIZE):
            sig = _device.daemon.submit(_, stream=stream_id)
            sigs.append(sig)

        [sig.wait() for sig in sigs]

    @override
    def record(
        self,
        event: ptr_t,  # event pointer
        stream: stream_id_t,
        device: device_id_t,
        flags: event_flag_t,
    ):
        import ctypes

        device_index = device if device != -1 else self.cur_device
        _device = self.devices[device_index]
        event_ptr = ctypes.cast(event, ctypes.POINTER(ctypes.c_int64))

        if event_ptr.contents.value == 0:
            e = Event(flag=flags)
            self.events[id(e)] = e
            event_ptr.contents.value = id(e)
        else:
            e = self.events[event_ptr.contents.value]

        def _():
            e.record()

        _device.daemon.submit(_, stream, stream % STREAM_POOL_SIZE)

    @override
    def recordDataPtrOnStream(
        self,
        data: ptr_t,
        device: device_id_t,
        stream: stream_id_t,
        flags: event_flag_t,
    ):
        pass

    @override
    def destroyEvent(
        self,
        event: event_id_t,
        device: device_id_t,
    ):
        self.events.pop(event)

    @override
    def synchronizeEvent(
        self,
        event: event_id_t,
    ):
        self.events[event].sig.wait()

    @override
    def queryEvent(
        self,
        event: event_id_t,
    ) -> bool:
        return event in self.events

    @override
    def elapsedTime(
        self,
        e1: event_id_t,
        e2: event_id_t,
        device: device_id_t,
    ) -> float:
        _e1 = self.events[e1]
        _e2 = self.events[e2]
        return _e2.time - _e1.time

    @override
    def block(
        self,
        event: event_id_t,
        stream: stream_id_t,
        device: device_id_t,
    ):
        e = self.events[event]
        _device = self.devices[device if device != -1 else self.cur_device]
        if e.time != 0:
            return

        def _():
            e.sig.wait()

        _device.daemon.submit(_, stream, stream % STREAM_POOL_SIZE)
