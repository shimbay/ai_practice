import functools
from dataclasses import dataclass
from enum import Enum, auto
from typing import List, Tuple


def jit(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        return func(*args, **kwargs)

    return wrapper


class MemoryType(Enum):
    DDR = auto()
    OCM = auto()


class DataType(Enum):
    FP32 = auto()


@dataclass
class Tensor:
    shape: List[int]
    dtype: DataType
    mem: MemoryType

    def __getitem__(self, v):
        return self


def create_tensor(shape: List[int], dtype: DataType, mem: MemoryType) -> Tensor:
    return Tensor(shape=shape, dtype=dtype, mem=mem)


def create_tensor_like(x: Tensor, mem: MemoryType) -> Tensor:
    return Tensor(shape=x.shape, dtype=x.dtype, mem=mem)


class Kernel:
    def __init__(self, *args):
        pass

    def __enter__(self):
        return 1, 1

    def __exit__(self, exc_type, exc_value, traceback):
        pass


class Core:
    def __init__(self):
        pass

    def __enter__(self):
        return 1, 4

    def __exit__(self, exc_type, exc_value, traceback):
        pass


class Chip:
    def __init__(self):
        pass

    def __enter__(self):
        return 1, 2

    def __exit__(self, exc_type, exc_value, traceback):
        pass


class Pipelined:
    def __init__(self, num_stage=0):
        self.num_stage = num_stage

    def __enter__(self):
        pass

    def __exit__(self, exc_type, exc_value, traceback):
        pass
