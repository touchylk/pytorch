#include <ATen/AccumulateType.h>
#include <ATen/Context.h>
#include <ATen/Dispatch.h>
#include <ATen/native/cuda/Loops.cuh>
#include <ATen/native/cuda/Reduce.cuh>
#include <ATen/native/DispatchStub.h>
#include <ATen/native/TensorIterator.h>
#include <ATen/native/ReduceOps.h>
#include <limits>


namespace at { namespace native {

template <typename scalar_t, typename acc_t=scalar_t>
void sum_kernel_impl(TensorIterator& iter) {
  gpu_reduce_kernel<scalar_t>(iter, []GPU_LAMBDA(acc_t a, acc_t b) -> acc_t {
    return a + b;
  });
}

template <typename scalar_t, typename acc_t=scalar_t>
void prod_kernel_impl(TensorIterator& iter) {
  gpu_reduce_kernel<scalar_t>(iter, []GPU_LAMBDA(acc_t a, acc_t b) -> acc_t {
    return a * b;
  }, 1);
}

static void sum_kernel_cuda(TensorIterator& iter) {
  if (iter.type().scalarType() == kHalf) {
    return sum_kernel_impl<at::Half, float>(iter);
  }
  AT_DISPATCH_ALL_TYPES(iter.type(), "sum", [&]() {
    sum_kernel_impl<scalar_t>(iter);
  });
}

static void prod_kernel_cuda(TensorIterator& iter) {
  if (iter.type().scalarType() == kHalf) {
    return prod_kernel_impl<at::Half, float>(iter);
  }
  AT_DISPATCH_ALL_TYPES(iter.type(), "prod", [&]() {
    prod_kernel_impl<scalar_t>(iter);
  });
}

REGISTER_DISPATCH(sum_stub, &sum_kernel_cuda);
REGISTER_DISPATCH(prod_stub, &prod_kernel_cuda);

}} // namespace at::native
