#include <cstdio>
#include <cstring>
#include <cuda.h>
#include <stdio.h>

#define CUDA_CALL(call)                                                        \
  do {                                                                         \
    CUresult res = (call);                                                     \
    if (res != CUDA_SUCCESS) {                                                 \
      const char *errStr;                                                      \
      cuGetErrorString(res, &errStr);                                          \
      fprintf(stderr,                                                          \
              "[CUDA ERROR] %s (%d)\n  File: %s\n  Line: %d\n  Call: %s\n",    \
              errStr, res, __FILE__, __LINE__, #call);                         \
      exit(EXIT_FAILURE);                                                      \
    }                                                                          \
  } while (0)

// PTX 内核代码 (SM 8.6 Ampere 架构)
const char *ptxKernel = R"(
// PTX 版本声明 (必须与设备兼容)
.version 7.8             // 对应 CUDA 11.x 及更高版本
.target sm_86             // 指定 Ampere 架构 (SM 8.6)
.address_size 64          // 64位地址空间

// 向量加法内核定义
.visible .entry vectorAdd(
    // 参数列表 (指针用 .u64，标量用 .u32)
    .param .u64 _A,       // 输入数组 A 的全局内存指针
    .param .u64 _B,       // 输入数组 B 的全局内存指针
    .param .u64 _C,       // 输出数组 C 的全局内存指针
    .param .u32 _N        // 数组长度
) {
    // 寄存器声明
    .reg .pred  %p<2>;    // 谓词寄存器 (用于条件判断)
    .reg .b32   %r<8>;    // 32位整数寄存器
    .reg .b64   %rd<10>;  // 64位地址寄存器
    .reg .f32   %f<4>;    // 32位浮点寄存器

    // 1. 加载参数到寄存器
    ld.param.u64    %rd1, [_A];     // 加载指针 A
    ld.param.u64    %rd2, [_B];     // 加载指针 B
    ld.param.u64    %rd3, [_C];     // 加载指针 C
    ld.param.u32    %r1, [_N];      // 加载数组长度 N

    // 2. 计算全局线程ID (blockIdx.x * blockDim.x + threadIdx.x)
    mov.u32         %r2, %tid.x;    // threadIdx.x
    mov.u32         %r3, %ctaid.x;  // blockIdx.x
    mov.u32         %r4, %ntid.x;   // blockDim.x
    mad.lo.s32      %r5, %r3, %r4, %r2;  // 计算全局索引

    // 3. 检查数组越界 (if (idx >= N) return)
    setp.ge.u32     %p1, %r5, %r1;  // 比较 idx >= N
    @%p1 bra        L_END;          // 若为真则跳转到结束

    // 4. 计算数组元素地址 (ptr = base + idx * sizeof(float))
    mul.wide.s32    %rd4, %r5, 4;   // idx * 4 (float占4字节)
    add.s64         %rd5, %rd1, %rd4;  // A + offset
    add.s64         %rd6, %rd2, %rd4;  // B + offset
    add.s64         %rd7, %rd3, %rd4;  // C + offset

    // 5. 从全局内存加载数据
    ld.global.f32   %f1, [%rd5];    // 加载 A[idx]
    ld.global.f32   %f2, [%rd6];    // 加载 B[idx]

    // 6. 执行加法运算
    add.f32         %f3, %f1, %f2;  // C[idx] = A[idx] + B[idx]

    // 7. 存储结果到全局内存
    st.global.f32   [%rd7], %f3;    // 存储 C[idx]

L_END:
    ret;                            // 内核结束
}
)";

int main() {
  CUdevice cuDevice, cuDevice1;
  CUcontext cuContext, cuContext1;
  CUmodule cuModule;
  CUfunction cuFunction;
  CUstream cuStream;
  CUevent cuStartEvent, cuStopEvent;
  int N = 1024;
  size_t bytes = N * sizeof(float);

  // === 1. 初始化 CUDA 驱动 ===
  CUDA_CALL(cuInit(0));

  // === 2. 获取设备并创建上下文 ===
  CUDA_CALL(cuDeviceGet(&cuDevice, 0));
  CUDA_CALL(cuCtxCreate(&cuContext, 0, cuDevice));

  CUDA_CALL(cuDeviceGet(&cuDevice1, 1));
  CUDA_CALL(cuCtxCreate(&cuContext1, 0, cuDevice1));

  int canAccessPeer;
  cudaDeviceCanAccessPeer(&canAccessPeer, 0, 1);
  printf("can access result: %d\n", canAccessPeer);
  cudaDeviceCanAccessPeer(&canAccessPeer, 1, 0);
  printf("can access result: %d\n", canAccessPeer);

  printf("\n=======================\n");
  int smCount, warpSize, maxThreadsPerSM, maxThreadsPerBlock;
  CUDA_CALL(cuDeviceGetAttribute(
      &smCount, CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT, cuDevice));
  CUDA_CALL(
      cuDeviceGetAttribute(&warpSize, CU_DEVICE_ATTRIBUTE_WARP_SIZE, cuDevice));
  CUDA_CALL(cuDeviceGetAttribute(
      &maxThreadsPerSM, CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_MULTIPROCESSOR,
      cuDevice));
  CUDA_CALL(cuDeviceGetAttribute(&maxThreadsPerBlock,
                                 CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK,
                                 cuDevice));
  printf("Stream Multiprocessor num: %d\n", smCount);
  printf("Warp num per SM: %d\n", warpSize);
  printf("Max threads per SM: %d\n", maxThreadsPerSM);
  printf("Max threads per Block: %d\n", maxThreadsPerBlock);

  int maxGridDimX, maxGridDimY, maxGridDimZ;
  cuDeviceGetAttribute(&maxGridDimX, CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_X,
                       cuDevice);
  cuDeviceGetAttribute(&maxGridDimY, CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Y,
                       cuDevice);
  cuDeviceGetAttribute(&maxGridDimZ, CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Z,
                       cuDevice);
  printf("Max Grid Dimensions: (%d, %d, %d)\n", maxGridDimX, maxGridDimY,
         maxGridDimZ);

  printf("=======================\n\n");

  // === 3. 创建 Stream 和 Event ===
  CUDA_CALL(cuStreamCreate(&cuStream, CU_STREAM_NON_BLOCKING));
  CUDA_CALL(cuEventCreate(&cuStartEvent, CU_EVENT_DEFAULT));
  CUDA_CALL(cuEventCreate(&cuStopEvent, CU_EVENT_DEFAULT));

  // === 4. 加载 PTX 模块并获取内核 ===
  CUDA_CALL(cuModuleLoadData(&cuModule, ptxKernel));
  CUDA_CALL(cuModuleGetFunction(&cuFunction, cuModule, "vectorAdd"));

  // === 5. 分配主机和设备内存 ===
  float *h_A = (float *)malloc(bytes);
  float *h_B = (float *)malloc(bytes);
  float *h_C = (float *)malloc(bytes);
  for (int i = 0; i < N; i++) {
    h_A[i] = i;
    h_B[i] = i * 2;
  }

  CUdeviceptr d_A, d_B, d_C;
  CUDA_CALL(cuMemAlloc(&d_A, bytes));
  CUDA_CALL(cuMemAlloc(&d_B, bytes));
  CUDA_CALL(cuMemAlloc(&d_C, bytes));

  // === 6. 异步数据传输（主机→设备）===
  CUDA_CALL(cuMemcpyHtoDAsync(d_A, h_A, bytes, cuStream));
  CUDA_CALL(cuMemcpyHtoDAsync(d_B, h_B, bytes, cuStream));

  // === 7. 记录启动事件并执行内核 ===
  CUDA_CALL(cuEventRecord(cuStartEvent, cuStream));

  void *args[] = {&d_A, &d_B, &d_C, &N};
  CUDA_CALL(cuLaunchKernel(cuFunction, (N + 255) / 256, 1, 1, // Grid 维度
                           256, 1, 1,                         // Block 维度
                           0,         // 共享内存大小
                           cuStream,  // 绑定 Stream
                           args, NULL // 内核参数
                           ));

  // === 8. 记录结束事件并异步回传数据 ===
  CUDA_CALL(cuEventRecord(cuStopEvent, cuStream));
  CUDA_CALL(cuMemcpyDtoHAsync(h_C, d_C, bytes, cuStream));

  // === 9. 同步 Stream 并计算耗时 ===
  CUDA_CALL(cuStreamSynchronize(cuStream));
  float elapsedMs;
  CUDA_CALL(cuEventElapsedTime(&elapsedMs, cuStartEvent, cuStopEvent));

  // === 10. 验证结果 ===
  printf("VectorAdd completed in %.3f ms\n", elapsedMs);
  for (int i = 0; i < 20; i++) {
    printf("C[%d] = %.1f (A=%.1f + B=%.1f)\n", i, h_C[i], h_A[i], h_B[i]);
  }

  return 0;
}
