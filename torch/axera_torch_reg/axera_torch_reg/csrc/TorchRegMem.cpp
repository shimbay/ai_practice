#include "TorchReg.h"

#include <ATen/EmptyTensor.h>
#include <ATen/TensorIterator.h>
#include <ATen/native/DispatchStub.h>
#include <ATen/native/UnaryOps.h>
#include <ATen/native/quantized/AffineQuantizer.h>
#include <ATen/native/transformers/attention.h>
#include <ATen/native/transformers/sdp_utils_cpp.h>
#include <ATen/ops/as_strided_cpu_dispatch.h>
#include <ATen/ops/quantize_per_tensor_native.h>
#include <ATen/ops/resize_native.h>
#include <ATen/ops/set_cpu_dispatch.h>
#include <ATen/ops/set_native.h>
#include <ATen/ops/view_native.h>

#include <c10/core/Allocator.h>

#include <torch/csrc/jit/serialization/pickler.h>
#include <torch/library.h>

namespace axera_torch_reg {
namespace {

struct DeviceAllocator final : at::Allocator {
  DeviceAllocator() = default;

  at::DataPtr allocate(size_t nbytes) override {
    py::gil_scoped_acquire acquire;
    auto curr_device_idx = get_method("getDevice")().cast<c10::DeviceIndex>();
    auto curr_device =
        c10::Device(c10::DeviceType::PrivateUse1, curr_device_idx);
    void *data = nullptr;
    if (nbytes > 0) {
      data =
          reinterpret_cast<void *>(get_method("malloc")(nbytes).cast<ptr_t>());
      TORCH_CHECK(data, "Failed to allocator ", nbytes, " bytes on device.");
    }
    return {data, data, &ReportAndDelete<kFreeMethod>, curr_device};
  }

  at::DeleterFnPtr raw_deleter() const override {
    return &ReportAndDelete<kFreeMethod>;
  }

  void copy_data(void *dest, const void *src, std::size_t count) const final {
    py::gil_scoped_acquire acquire;
    get_method("copyData")(reinterpret_cast<ptr_t>(dest),
                           reinterpret_cast<ptr_t>(src), count);
  }
};

static DeviceAllocator global_torchreg_alloc;
REGISTER_ALLOCATOR(c10::DeviceType::PrivateUse1, &global_torchreg_alloc);

// Empty op needs C++ code and cannot be handled by python side fallback
at::Tensor empty_torchreg(c10::IntArrayRef size,
                          std::optional<c10::ScalarType> dtype_opt,
                          std::optional<c10::Layout> layout_opt,
                          std::optional<c10::Device> device_opt,
                          std::optional<bool> pin_memory_opt,
                          std::optional<c10::MemoryFormat> memory_format_opt) {
  const auto device = c10::device_or_default(device_opt);
  const auto dtype = c10::dtype_or_default(dtype_opt);
  TORCH_CHECK(device.is_privateuseone());
  TORCH_CHECK(c10::layout_or_default(layout_opt) == c10::Layout::Strided,
              "Non strided layout not supported");
  TORCH_CHECK(!c10::pinned_memory_or_default(pin_memory_opt),
              "Pin memory can only be on CPU");
  const c10::DeviceGuard device_guard(device);
  constexpr c10::DispatchKeySet pu1_dks(c10::DispatchKey::PrivateUse1);
  return at::detail::empty_generic(size, &global_torchreg_alloc, pu1_dks, dtype,
                                   memory_format_opt);
}

at::Tensor empty_strided_torchreg(c10::IntArrayRef size,
                                  c10::IntArrayRef stride,
                                  std::optional<c10::ScalarType> dtype_opt,
                                  std::optional<c10::Layout> layout_opt,
                                  std::optional<c10::Device> device_opt,
                                  std::optional<bool> pin_memory_opt) {
  const auto device = c10::device_or_default(device_opt);
  const auto dtype = c10::dtype_or_default(dtype_opt);
  TORCH_CHECK(device.is_privateuseone());
  TORCH_CHECK(c10::layout_or_default(layout_opt) == c10::Layout::Strided,
              "Non strided layout not supported");
  TORCH_CHECK(!c10::pinned_memory_or_default(pin_memory_opt),
              "Pin memory can only be on CPU");
  const c10::DeviceGuard device_guard(device);
  constexpr c10::DispatchKeySet pu1_dks(c10::DispatchKey::PrivateUse1);
  return at::detail::empty_strided_generic(size, stride, &global_torchreg_alloc,
                                           pu1_dks, dtype);
}

at::Tensor as_strided_torchreg(const at::Tensor &self, c10::IntArrayRef size,
                               c10::IntArrayRef stride,
                               std::optional<int64_t> storage_offset_) {
  // Metadata-only change so we re-use the cpu impl
  return at::cpu::as_strided(self, size, stride, storage_offset_);
}

const at::Tensor &
resize__torchreg(const at::Tensor &self, c10::SymIntArrayRef size,
                 ::std::optional<at::MemoryFormat> memory_format) {
  return at::native::resize_(self, C10_AS_INTARRAYREF_SLOW(size),
                             memory_format);
}

at::Tensor &set_source_Storage_storage_offsetset_torchreg(
    at::Tensor &result, at::Storage storage, int64_t storage_offset,
    c10::IntArrayRef size, c10::IntArrayRef stride) {
  return at::cpu::set_(result, storage, storage_offset, size, stride);
}

} // namespace

// Using the simplest way to obtain continuous Tensor data and process it.
// This is a demo for using operand API, and you can add more complex logic
// for input and output tensor based on your custom device kernel.
void abs_kernel(at::TensorIteratorBase &iter) {
  // Abs only have a input tensor and a output tensor.
  auto &output_operand = iter.operand(0);
  auto &input_operand = iter.operand(1);
  auto &output_tensor_base = output_operand.tensor_base();
  auto &input_tensor_base = input_operand.tensor_base();
  TORCH_CHECK(!input_operand.original_tensor_base().defined(),
              "input original tensor is defined.");
  TORCH_CHECK(!output_operand.original_tensor_base().defined(),
              "output original tensor is defined.");
  // For easy test, only accept contiguous input tensor for calculate.
  auto memory_format = input_tensor_base.suggest_memory_format();
  TORCH_CHECK(input_tensor_base.is_contiguous(memory_format),
              "Input tensor need be contiguous.");
  // Add necessary restrictions to ensure the security of the demo.
  TORCH_CHECK(input_tensor_base.sizes() == output_tensor_base.sizes(),
              "Intput and output tensor size are not equal.");
  // Common dtype is calculate in TensorIteratorBase.
  TORCH_CHECK(iter.common_dtype() == at::ScalarType::Float,
              "Only support float type.")
  // Using for loop for abs calculate.
  auto abs_function = [](float *output_ptr, const float *input_ptr,
                         const int64_t NUM) {
    for (int64_t i = 0; i < NUM; ++i) {
      *(output_ptr + i) = std::abs(*(input_ptr + i));
    }
  };
  // To simplify the logic of the test demo code,
  // we only use contiguous tensor to calculate on device side.
  // And using input tensor memory format.
  if (iter.is_contiguous()) {
    // Add for will_resize flag check. You can convert to differernt
    // tensor memory format when will_resize is True.
    // If TensorIteratorConfig resize_outputs_ flag is true, and there are two
    // situations:
    // 1) Out tensor is undefined, and TensorIterator set will_resize to true;
    // 2) Out tensor is defined and tensor size is not equal to input tensor
    // size;
    //    TensorIterator set will_resize to true, and call
    //    set_output_raw_strided to resize output tensor.
    // When output operand will_resize flag is ture, dummy
    // device can convert tensor to dummy device preferred memory format.
    // Here we don't convert tensor memory format, because it will become
    // complex when dummy device want keep same memory format for training
    // network.
    TORCH_CHECK(output_operand.will_resize,
                "output operand will_resize flag need be True.");
    abs_function((float *)iter.data_ptr(0), (float *)iter.data_ptr(1),
                 iter.numel());
  } else {
    // Stride copy is not support for foo device, using cpu device instead.
    // For abs op, the last situation is: output tensor is not contiguous with
    // operand will_resize is False.
    TORCH_CHECK(!output_operand.will_resize,
                "output operand will_resize is True.");
    // Get a contiguous tensor with input memory format.
    at::Tensor output =
        at::empty(output_tensor_base.sizes(),
                  input_tensor_base.options().memory_format(memory_format));
    // For structured op which inheried from TensorIteratorBase, maybe you need
    // to call set_output_raw_strided function to update output stored in op
    // sturctured. abs op is no need to do this.
    output_operand.exchange_tensor(
        c10::MaybeOwned<at::TensorBase>::owned(std::in_place, output));
    abs_function((float *)output_operand.tensor_base().mutable_data_ptr(),
                 (float *)iter.data_ptr(1), iter.numel());
    // Copy tensor base to original tensor base, and keep same scalar type and
    // stride with cpu and gpu.
    if (output_operand.original_tensor_base().defined() &&
        !output_operand.original_tensor_base().is_same(
            output_operand.tensor_base())) {
      output_operand.original_tensor().copy_(output_operand.tensor());
      output_operand.restore_original_tensor();
    }
  }
}
// This is a demo for using operand API, and you can add more complex logic
// for input and output tensor based on your custom device kernel.

/* Notes:
 *
 * TorchReg is currently designed to simulate device memory through multiple
 * subprocesses on purpose to ensure we don't mistakenly poke at the "device's
 * memory" from the main process. And be able to simulate the same thing that
 * happens with other accelerators: any metadata-only change is cpu-only
 * (main process), any data change must go through to the device (other process)
 * and any data transfer between the two is expensive (serializing the whole
 * Tensor).
 *
 * Currently, for the efficiency of IPC, most operations are to pass the Tensor
 * metadata, and only a small number of operations involving copy will serialize
 * and pass the Tensor body by custom pickler provided by torch.multiprocess.
 *
 * Therefore, in principle, only operations related to Metadata modification can
 * be directly implemented at the C++ level and registered in PrivateUse1; but
 * if memory access is involved, the relevant operations must be implemented at
 * the Python level, otherwise invalid memory access will result.
 */

TORCH_LIBRARY_IMPL(aten, PrivateUse1, m) {
  m.impl("empty.memory_format", empty_torchreg);
  m.impl("empty_strided", empty_strided_torchreg);
  m.impl("view", at::native::view);
  m.impl("view.dtype", at::native::view_dtype);
  m.impl("as_strided", as_strided_torchreg);
  m.impl("resize_", resize__torchreg);
  m.impl("set_.source_Storage", at::native::set_);
  m.impl("set_.source_Storage_storage_offset",
         set_source_Storage_storage_offsetset_torchreg);
}

struct TorchRegBackendMeta : public c10::BackendMeta {
  TorchRegBackendMeta(int version_number, int format_number)
      : version_number_(version_number), format_number_(format_number) {}

  int version_number_{-1};
  int format_number_{-1};
};

void for_serialization(const at::Tensor &t,
                       std::unordered_map<std::string, bool> &m) {
  auto meta_ptr = t.unsafeGetTensorImpl()->get_backend_meta();

  if (meta_ptr != nullptr) {
    auto o_meta_ptr = dynamic_cast<TorchRegBackendMeta *>(meta_ptr);
    if (o_meta_ptr->version_number_ == 1) {
      m["version_number"] = true;
    }
    if (o_meta_ptr->format_number_ == 29) {
      m["format_number"] = true;
    }
  }
}

void for_deserialization(const at::Tensor &t,
                         std::unordered_map<std::string, bool> &m) {
  int version_number{-1};
  int format_number{-1};

  if (m.find("version_number") != m.end()) {
    version_number = 1;
  }
  if (m.find("format_number") != m.end()) {
    format_number = 29;
  }

  c10::intrusive_ptr<c10::BackendMeta> meta{std::unique_ptr<c10::BackendMeta>(
      new TorchRegBackendMeta(version_number, format_number))};
  t.unsafeGetTensorImpl()->set_backend_meta(meta);
}

REGISTER_PRIVATEUSE1_SERIALIZATION(&for_serialization, &for_deserialization)
} // namespace axera_torch_reg
namespace at::native {
REGISTER_PRIVATEUSE1_DISPATCH(abs_stub, &axera_torch_reg::abs_kernel);
} // namespace at::native
