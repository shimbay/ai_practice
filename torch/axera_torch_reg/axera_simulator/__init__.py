from axera_torch_reg.interface import set_impl

from .aten_impl import *
from .common import axera_runtime

set_impl(axera_runtime)
