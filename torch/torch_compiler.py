import warnings
import os

os.environ["ATEN_CPU_CAPABILITY"] = "default"

from torch.compiler import allow_in_graph

warnings.simplefilter(action="ignore", category=FutureWarning)

import torch
import torch._dynamo
import torch.nn as nn
import torch.nn.functional as F

# torch/onnx/_internal/onnxruntime.py
from torch.fx import GraphModule

from torch._functorch.aot_autograd import aot_module_simplified

# from torch._decomp import core_aten_decompositions
from torch._decomp import get_decompositions

# from torch.fx.experimental.proxy_tensor import decompose

from torch.ao.quantization.quantize_pt2e import (
    prepare_qat_pt2e,
    convert_pt2e,
)


# custom op impl
@torch.library.custom_op("ax_op::custom_op", mutates_args=())
def custom_op(x: torch.Tensor) -> torch.Tensor:
    return F.softmax(x, dim=-1)


# custom op shape inference
@custom_op.register_fake
def _(x):
    return x

class GridSampleConcatConv(nn.Module):
    def __init__(
        self,
        in_channels_per_input: int,
        out_channels: int,
        kernel_size: int,
        mode: str = "bilinear",
        padding_mode: str = "zeros",
        align_corners: bool = False,
    ):
        super().__init__()
        total_channels = 4 * in_channels_per_input
        self.conv = nn.Conv2d(total_channels, out_channels, kernel_size, padding=(1, 1))
        self.mode = mode
        self.padding_mode = padding_mode
        self.align_corners = align_corners

    def forward(self, inputs, grids):
        assert len(inputs) == 4 and len(grids) == 4

        sampled = [
            F.grid_sample(
                x,
                grid,
                mode=self.mode,
                padding_mode=self.padding_mode,
                align_corners=self.align_corners,
            )
            for x, grid in zip(inputs, grids)
        ]

        x = torch.cat(sampled, dim=1)

        x = self.conv(x)

        x = F.interpolate(x, scale_factor=0.5, mode="bilinear")

        x = F.softmax(x, dim=1)

        x = torch.cos(x)

        torch.cos_(x)

        return x


model = GridSampleConcatConv(
    in_channels_per_input=16,
    out_channels=256,
    kernel_size=3,
)


batch_size = 1
inputs = [torch.randn(batch_size, 16, 256, 256) for _ in range(4)]
grids = [torch.randn(batch_size, 64, 64, 2) for _ in range(4)]

onnx_model = torch.onnx.export(model, (inputs, grids), dynamo=True)


from torch.export.exported_program import default_decompositions

decompositions = default_decompositions()
decompositions = {k: v for k, v in decompositions.items() if not "upsample" in str(k)}


"""
torch export + decompositions
"""

ep = torch.export.export_for_training(
    model,
    (inputs, grids),
    strict=True,
)
ep.module().print_readable()

ep = ep.run_decompositions(decompositions)
ep.module().print_readable()


"""
torch backend
"""


def toy_backend_aten_ir(gm: GraphModule, sample_inputs):
    # from torch.onnx._internal.onnxruntime import torch_compile_backend
    from torch._dynamo.backends.common import aot_autograd

    def my_compiler(gm: GraphModule, sample_inputs):
        print("AOTAutograd produced a fx Graph in Aten IR:")
        gm.print_readable()
        return gm.forward

    gm.print_readable()
    # Invoke AOTAutograd
    return aot_autograd(
        fw_compiler=my_compiler,
        decompositions=decompositions,
    )(gm, sample_inputs)


torch._dynamo.reset()
fn = torch.compile(
    backend=toy_backend_aten_ir,
    # backend="onnxrt",
    dynamic=False,
    fullgraph=True,
)(model)
out = fn(inputs, grids)

# from torch._dispatch.python import all_py_loaded_overloads

# for op in all_py_loaded_overloads():
#     print(op)
