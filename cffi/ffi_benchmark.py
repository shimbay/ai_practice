# ffi_benchmark.py
import timeit
import ctypes
import numpy as np
from cffi import FFI
import cython
import os

# 准备测试数据
N = 100000
a = np.random.rand(N)
b = np.random.rand(N)
out = np.empty_like(a)

# 1. 纯Python实现作为基准
def py_add(a, b):
    return a + b


def py_add_array(a, b, out):
    for i in range(len(a)):
        out[i] = a[i] + b[i]


# 2. ctypes测试
lib = ctypes.CDLL("./libfib.so")
lib.fib.argtypes = [ctypes.c_int]
lib.fib.restype = ctypes.c_int

lib.add.argtypes = [ctypes.c_double, ctypes.c_double]
lib.add.restype = ctypes.c_double

# 数组处理需要特殊处理
_add_array = lib.add_array
_add_array.argtypes = [
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.POINTER(ctypes.c_double),
    ctypes.c_int,
]


def ctypes_add(a, b):
    return lib.add(a, b)


def ctypes_add_array(a, b, out):
    _add_array(
        a.ctypes.data_as(ctypes.POINTER(ctypes.c_double)),
        b.ctypes.data_as(ctypes.POINTER(ctypes.c_double)),
        out.ctypes.data_as(ctypes.POINTER(ctypes.c_double)),
        len(a),
    )


# 3. CFFI测试
ffi = FFI()
ffi.cdef(
    """
    int fib(int n);
    double add(double a, double b);
    void add_array(double *in1, double *in2, double *out, int length);
"""
)
cffi_lib = ffi.dlopen("./libfib.so")


def cffi_add(a, b):
    return cffi_lib.add(a, b)


def cffi_add_array(a, b, out):
    a_ptr = ffi.cast("double *", a.ctypes.data)
    b_ptr = ffi.cast("double *", b.ctypes.data)
    out_ptr = ffi.cast("double *", out.ctypes.data)
    cffi_lib.add_array(a_ptr, b_ptr, out_ptr, len(a))


# 4. Cython测试 (需要先编译)
# 保存为 fib_cython.pyx 然后编译
"""
# fib_cython.pyx
cdef extern from "fib.c":
    int fib(int n)
    double add(double a, double b)
    void add_array(double *in1, double *in2, double *out, int length)

def cython_fib(n):
    return fib(n)

def cython_add(a, b):
    return add(a, b)

def cython_add_array(double[::1] a, double[::1] b, double[::1] out):
    add_array(&a[0], &b[0], &out[0], len(a))
"""
# 需要先编译Cython模块，这里假设已编译为fib_cython.so
try:
    import fib_cython

    HAS_CYTHON = True
except ImportError:
    HAS_CYTHON = False

# 测试函数
def benchmark():
    number = 1000
    n = 20  # 斐波那契测试参数

    print(f"=== 单次调用测试 (n={number}次) ===")

    # 测试fib函数
    print("\nFibonacci测试 (fib(20)):")

    t = timeit.timeit(lambda: lib.fib(n), number=number)
    print(f"ctypes:    {t*1e6/number:.2f} μs per call")

    t = timeit.timeit(lambda: cffi_lib.fib(n), number=number)
    print(f"CFFI:      {t*1e6/number:.2f} μs per call")

    # 测试简单加法
    print("\n简单加法测试 (1.2 + 3.4):")

    t = timeit.timeit(lambda: ctypes_add(1.2, 3.4), number=number)
    print(f"ctypes:    {t*1e6/number:.2f} μs per call")

    t = timeit.timeit(lambda: cffi_add(1.2, 3.4), number=number)
    print(f"CFFI:      {t*1e6/number:.2f} μs per call")

    t = timeit.timeit(lambda: py_add(1.2, 3.4), number=number)
    print(f"Pure Python: {t*1e6/number:.2f} μs per call")

    # 测试数组处理
    print(f"\n数组加法测试 ({N}个元素):")

    t = timeit.timeit(lambda: ctypes_add_array(a, b, out), number=10)
    print(f"ctypes:    {t*1e3/10:.2f} ms per call")

    t = timeit.timeit(lambda: cffi_add_array(a, b, out), number=10)
    print(f"CFFI:      {t*1e3/10:.2f} ms per call")

    t = timeit.timeit(lambda: py_add_array(a, b, out), number=10)
    print(f"Pure Python: {t*1e3/10:.2f} ms per call")


if __name__ == "__main__":
    benchmark()
