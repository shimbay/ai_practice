import torch
from loguru import logger

from axera_torch_reg.interface import torch_op

from .common import axera_runtime as rt


def device_mem_view(t: torch.Tensor) -> torch.Tensor:
    return rt.device(t.device.index).memory_view(t)


def get_device_stream(t: torch.Tensor):
    return t.device.index, rt.devices[t.device.index].cur_stream


def host_fallback(op_name: str, *args):
    logger.info(f"host fallback, op: {op_name}")
    op = getattr(torch.ops.aten, op_name)
    _args = []
    for arg in args:
        if isinstance(arg, torch.Tensor) and arg.device.type == "axera":
            _args.append(arg.to("cpu"))
        else:
            _args.append(arg)
    return op(*_args)


@torch_op("_copy_from")
def copy_from(src: torch.Tensor, dst: torch.Tensor):
    if src.device.type == dst.device.type:
        assert src.device.type == "axera"
        if src.device.index == dst.device.index:
            raise NotImplementedError()
        else:
            raise NotImplementedError()
    elif src.device.type == "axera":
        d, s = get_device_stream(src)
        rt.synchronizeStream(s, d)
        src_view = device_mem_view(src)
        dst[:] = src_view[:]
    elif dst.device.type == "axera":
        d, s = get_device_stream(dst)
        rt.synchronizeStream(s, d)
        dst_view = device_mem_view(dst)
        dst_view[:] = src[:]
    else:
        raise RuntimeError(f"illegal device type, from: {src.device}, to: {dst.device}")


@torch_op("equal")
def equal(a: torch.Tensor, b: torch.Tensor):
    if a.device.type != b.device.type:
        raise NotImplementedError()
    elif a.device.index != b.device.index:
        raise NotImplementedError()
    else:
        r = torch.zeros(1, dtype=torch.bool).to(a.device.index)

        def device_memcpy_kernel():
            _a = device_mem_view(a)
            _b = device_mem_view(b)
            _r = device_mem_view(r)

            _r[0] = torch.equal(_a, _b)

        rt.launch(device_memcpy_kernel, device=a.device.index)
        return r.cpu()[0]


@torch_op("add.out")
def add_out(a: torch.Tensor, b: torch.Tensor, out: torch.Tensor, alpha: float = 1):
    if a.device.type != b.device.type:
        return host_fallback("add.out", a, b, out, alpha)
    elif a.device.index != b.device.index:
        return host_fallback("add.out", a, b, out, alpha)
    else:

        def device_add_kernel():
            _a = device_mem_view(a)
            _b = device_mem_view(b)
            _out = device_mem_view(out)

            _out[:] = torch.add(_a, _b, alpha=alpha)

        rt.launch(device_add_kernel, device=a.device.index)
        return out


@torch_op("add_")
def add(self: torch.Tensor, other: torch.Tensor, alpha: float = 1):
    if self.device.type != other.device.type:
        return host_fallback("add_", self, other, alpha)
    elif self.device.index != other.device.index:
        return host_fallback("add_", self, other, alpha)
    else:

        def device_add_kernel():
            _self = device_mem_view(self)
            _other = device_mem_view(other)

            _self.add(_other, alpha=alpha)

        rt.launch(device_add_kernel, device=self.device.index)
        return self
