import types

import torch

from .common import AXERA_BACKEND

# Create our python implementation dict so that the C++ module
# can access it during its initialization and also register aten impls.
from ._aten_impl import impl_factory as impl_factory  # noqa: F401


# Load the C++ Module
import pytorch_openreg._C  # isort:skip # type: ignore[import] # noqa: F401


def _create_module():
    module = types.ModuleType("_OpenRegMod")

    def is_available():
        return True

    def is_initialized():
        return module._initialized

    def _lazy_init():
        if is_initialized():
            return
        pytorch_openreg._C._init()
        module._initialized = True

    module.is_available = is_available  # type: ignore[assignment]

    module._initialized = False  # type: ignore[assignment]
    module._lazy_init = _lazy_init  # type: ignore[assignment]
    module.is_initialized = is_initialized  # type: ignore[assignment]

    return module


# Set all the appropriate state on PyTorch
torch.utils.rename_privateuse1_backend(AXERA_BACKEND)
torch._register_device_module(AXERA_BACKEND, _create_module())
torch.utils.generate_methods_for_privateuse1_backend(for_storage=True)
