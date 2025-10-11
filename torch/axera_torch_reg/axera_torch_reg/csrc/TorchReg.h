#pragma once

#include <string>
#include <torch/csrc/utils/pybind.h>

namespace axera_torch_reg {

static std::string PackageName = "axera_torch_reg";
static constexpr char kFreeMethod[] = "free";
static constexpr char kHostFreeMethod[] = "hostFree";

using ptr_t = uint64_t;

void set_impl_factory(PyObject *factory);
py::function get_method(const char *name);

template <const char *name> static void ReportAndDelete(void *ptr) {
  if (!ptr || !Py_IsInitialized()) {
    return;
  }

  py::gil_scoped_acquire acquire;

  PyObject *type = nullptr, *value = nullptr, *traceback = nullptr;
  // Always stash, this will be a no-op if there is no error
  PyErr_Fetch(&type, &value, &traceback);

  TORCH_CHECK(get_method(name)(reinterpret_cast<ptr_t>(ptr)).cast<bool>(),
              "Failed to free memory pointer at ", ptr);

  // If that user code raised an error, just print it without raising it
  if (PyErr_Occurred()) {
    PyErr_Print();
  }

  // Restore the original error
  PyErr_Restore(type, value, traceback);
}

#define REGISTER_PRIVATEUSE1_SERIALIZATION(FOR_SERIALIZATION,                  \
                                           FOR_DESERIALIZATION)                \
  static int register_serialization() {                                        \
    torch::jit::TensorBackendMetaRegistry(                                     \
        c10::DeviceType::PrivateUse1, FOR_SERIALIZATION, FOR_DESERIALIZATION); \
    return 0;                                                                  \
  }                                                                            \
  static const int _temp = register_serialization();

} // namespace axera_torch_reg
