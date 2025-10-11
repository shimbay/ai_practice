from abc import ABC, abstractmethod

import torch
from loguru import logger
from torch._higher_order_ops import wrap

AXERA_BACKEND = "axera"

ptr_t = int
device_id_t = int
stream_id_t = int
event_id_t = int
event_flag_t = int


class TorchBackendPythonInterface(ABC):
    @abstractmethod
    def hasPrimaryContext(
        self,
        device: device_id_t,
    ) -> bool:
        ...

    # Get the number of devices.  WARNING: This is REQUIRED to not raise
    # an exception.  If there is some sort of problem, e.g., driver error,
    # you should report that there are zero available devices.
    @abstractmethod
    def deviceCount(self) -> device_id_t:
        ...

    # Get the current device.
    @abstractmethod
    def getDevice(self) -> device_id_t:
        ...

    # Set the current device to device.
    @abstractmethod
    def setDevice(
        self,
        device: device_id_t,
    ):
        ...

    # Set the current device to device, without checking for errors
    # (so, e.g., this can be called from a destructor).
    @abstractmethod
    def uncheckedSetDevice(
        self,
        device: device_id_t,
    ):
        ...

    # Set the current device to device, and return the previous device.
    @abstractmethod
    def exchangeDevice(
        self,
        device: device_id_t,
    ) -> device_id_t:
        ...

    # malloc data on current device.
    @abstractmethod
    def malloc(
        self,
        size: int,
    ) -> ptr_t:
        ...

    # free data on current device.
    @abstractmethod
    def free(
        self,
        ptr: ptr_t,
    ) -> bool:
        ...

    # copy between data on current device.
    @abstractmethod
    def copyData(
        self,
        dest: ptr_t,
        src: ptr_t,
        count: int,
    ):
        ...

    @abstractmethod
    def isPinnedPtr(
        self,
        data: ptr_t,
    ) -> bool:
        ...

    # malloc data on host.
    @abstractmethod
    def hostMalloc(
        self,
        size: int,
    ) -> ptr_t:
        ...

    # free data on host.
    @abstractmethod
    def hostFree(
        self,
        ptr: ptr_t,
    ) -> bool:
        ...

    # copy between data on host.
    @abstractmethod
    def hostCopyData(
        self,
        dest: ptr_t,
        src: ptr_t,
        count: int,
    ):
        ...

    #  Return a new stream for a given device and priority. The stream will be
    #  copied and shared around, device backend should be able to correctly handle
    #  the lifetime of the stream.
    @abstractmethod
    def getNewStream(
        self,
        device: device_id_t,
        priority: int,
    ) -> stream_id_t:
        ...

    # Return true if all the work previously enqueued on the stream for
    # asynchronous execution has completed running on the device.
    @abstractmethod
    def queryStream(
        self,
        stream: stream_id_t,
        device: device_id_t,
    ) -> bool:
        ...

    # Get the current stream for a given device.
    @abstractmethod
    def getStream(
        self,
        device: device_id_t,
    ) -> stream_id_t:
        ...

    # Get a stream from the global pool for a given device.
    @abstractmethod
    def getStreamFromGlobalPool(
        self,
        device: device_id_t,
        is_high_priority: bool,
    ) -> stream_id_t:
        ...

    # Get the default stream for a given device.
    @abstractmethod
    def getDefaultStream(
        self,
        device: device_id_t,
    ) -> stream_id_t:
        ...

    # Set a stream to be the thread local current stream for its device.
    # Return the previous stream for that device. You are NOT required
    # to set the current device to match the device of this stream.
    @abstractmethod
    def exchangeStream(
        self,
        stream: stream_id_t,
        device: device_id_t,
    ) -> stream_id_t:
        ...

    # Wait (by blocking the calling thread) until all the work previously
    # enqueued on the stream has completed running on the device.
    @abstractmethod
    def synchronizeStream(
        self,
        stream: stream_id_t,
        device: device_id_t,
    ):
        ...

    # Wait (by blocking the calling thread) until all the work previously
    # enqueued on the device has been completed.
    @abstractmethod
    def synchronizeDevice(
        self,
        device: device_id_t,
    ):
        ...

    # Increments the event's version and enqueues a job with this version
    # in the stream's work queue. When the stream process that job
    # it notifies all streams waiting on / blocked by that version of the
    # event to continue and marks that version as recorded.
    @abstractmethod
    def record(
        self,
        event: ptr_t,  # event pointer
        stream: stream_id_t,
        device: device_id_t,
        flags: event_flag_t,
    ):
        ...

    # Ensure the caching allocator (if any) is aware that the given DataPtr is
    # being used on the given stream, and that it should thus avoid recycling the
    # DataPtr until all work on that stream is done.
    @abstractmethod
    def recordDataPtrOnStream(
        self,
        data: ptr_t,
        device: device_id_t,
        stream: stream_id_t,
        flags: event_flag_t,
    ):
        ...

    # Destroys the given event.
    @abstractmethod
    def destroyEvent(
        self,
        event: event_id_t,
        device: device_id_t,
    ):
        ...

    # Wait (by blocking the calling thread) until all the work previously
    # recorded on the event has completed running on the device.
    @abstractmethod
    def synchronizeEvent(
        self,
        event: event_id_t,
    ):
        ...

    # Returns true if (and only if)
    #  (1) the event has never been scheduled to be recorded
    #  (2) the current version is marked as recorded.
    # Returns false otherwise.
    @abstractmethod
    def queryEvent(
        self,
        event: event_id_t,
    ) -> bool:
        ...

    # Fetch the elapsed time between two recorded events.
    @abstractmethod
    def elapsedTime(
        self,
        e1: event_id_t,
        e2: event_id_t,
        device: device_id_t,
    ) -> float:
        ...

    # Does nothing if the event has not been scheduled to be recorded.
    # If the event was previously enqueued to be recorded, a command
    # to wait for the version of the event that exists at the time of this call
    # is inserted in the stream's work queue.
    # When the stream reaches this command it will stop processing
    # additional commands until that version of the event is marked as recorded.
    @abstractmethod
    def block(
        self,
        event: event_id_t,
        stream: stream_id_t,
        device: device_id_t,
    ):
        ...


_DEVICE_IMPL = None


def set_impl(impl: TorchBackendPythonInterface):
    global _DEVICE_IMPL
    _DEVICE_IMPL = impl


def impl_factory(name):
    fn = getattr(_DEVICE_IMPL, name)

    def wrapper(*args, **kwargs):
        logger.info(f"Calling hook [{name}]")
        for i, arg in enumerate(args):
            logger.info(f"  args {i}: {to_str(arg)}")
        for k, v in kwargs.items():
            logger.info(f"  kwargs {k}: {to_str(v)}")
        res = fn(*args, *kwargs)
        logger.info(f"  return: {to_str(res)}")
        return res

    return wrapper


_OP_IMPL = {}


def to_str(a) -> str:
    if isinstance(a, torch.Tensor):
        return f"Tensor(shape={a.shape}, dtype={a.dtype}, stride={a.stride()}, device={a.device}, storage_ptr={a.untyped_storage().data_ptr()}, offset={a.storage_offset()})"
    else:
        return str(a)


def torch_tensor_desc(t: torch.Tensor) -> str:
    return ""


def torch_op(op_name: str, ns: str = "aten"):
    def decorator(fn):
        if ns not in _OP_IMPL:
            _OP_IMPL[ns] = torch.library.Library(ns, "IMPL")

        def wrapper(*args, **kwargs):
            logger.info(f"Calling op [{op_name}]")
            for i, arg in enumerate(args):
                logger.info(f"  args {i}: {to_str(arg)}")
            for k, v in kwargs.items():
                logger.info(f"  kwargs {k}: {to_str(v)}")
            res = fn(*args, **kwargs)
            logger.info(f"  return: {to_str(res)}")
            return res

        lib = _OP_IMPL[ns]
        lib.impl(op_name, wrapper, dispatch_key="PrivateUse1")

        fn.op_name = op_name

        return fn

    return decorator
