import torch
import triton
import triton.language as tl


@triton.jit
def matmul_split_k_kernel(
    a_ptr,
    b_ptr,
    c_ptr,
    M,
    N,
    K,
    stride_am,
    stride_ak,
    stride_bk,
    stride_bn,
    stride_cm,
    stride_cn,
    BLOCK_SIZE_M: tl.constexpr,
    BLOCK_SIZE_N: tl.constexpr,
    BLOCK_SIZE_K: tl.constexpr,
):
    # 三维网格划分：pid_m 对应 M 维度，pid_n 对应 N 维度，pid_s 对应 Split-K 维度
    pid_m = tl.program_id(0)
    pid_n = tl.program_id(1)
    pid_s = tl.program_id(2)

    # 计算当前 Split-K 块的范围
    k_off = pid_s * BLOCK_SIZE_K
    m_off = pid_m * BLOCK_SIZE_M
    n_off = pid_n * BLOCK_SIZE_N

    # 使用块指针加载 A 和 B 的矩阵块
    a_block_ptr = tl.make_block_ptr(
        base=a_ptr,
        shape=(M, K),
        strides=(stride_am, stride_ak),
        offsets=(m_off, k_off),
        block_shape=(BLOCK_SIZE_M, BLOCK_SIZE_K),
        order=(1, 0),  # 行优先存储
    )
    b_block_ptr = tl.make_block_ptr(
        base=b_ptr,
        shape=(K, N),
        strides=(stride_bk, stride_bn),
        offsets=(k_off, n_off),
        block_shape=(BLOCK_SIZE_K, BLOCK_SIZE_N),
        order=(1, 0),
    )

    # 加载数据并自动处理边界填充
    a = tl.load(a_block_ptr, boundary_check=(0, 1), padding_option="zero")
    b = tl.load(b_block_ptr, boundary_check=(0, 1), padding_option="zero")

    # 计算矩阵乘积
    acc = tl.dot(a, b)

    # 计算目标矩阵 C 的指针和掩码
    offs_m = m_off + tl.arange(0, BLOCK_SIZE_M)
    offs_n = n_off + tl.arange(0, BLOCK_SIZE_N)
    c_ptrs = c_ptr + offs_m[:, None] * stride_cm + offs_n[None, :] * stride_cn
    mask = (offs_m[:, None] < M) & (offs_n[None, :] < N)

    # 使用原子操作累加结果
    tl.atomic_add(c_ptrs, acc, mask=mask)


def matmul_split_k(
    a: torch.Tensor, b: torch.Tensor, block_m=64, block_n=64, block_k=32
):
    assert a.shape[1] == b.shape[0], "矩阵维度不匹配"
    M, K = a.shape
    _, N = b.shape
    c = torch.zeros((M, N), device=a.device, dtype=a.dtype)

    # 计算 Split-K 参数
    split_k = (K + block_k - 1) // block_k
    grid = (
        triton.cdiv(M, block_m),
        triton.cdiv(N, block_n),
        split_k,
    )

    # 启动内核
    matmul_split_k_kernel[grid](
        a,
        b,
        c,
        M,
        N,
        K,
        a.stride(0),
        a.stride(1),
        b.stride(0),
        b.stride(1),
        c.stride(0),
        c.stride(1),
        BLOCK_SIZE_M=block_m,
        BLOCK_SIZE_N=block_n,
        BLOCK_SIZE_K=block_k,
    )
    return c


# 运行示例
torch.manual_seed(0)
a = torch.randn((512, 256), device="cuda", dtype=torch.float32)
b = torch.randn((256, 384), device="cuda", dtype=torch.float32)

# 使用 Triton Split-K 实现
triton_output = matmul_split_k(a, b)

# 使用 PyTorch 原生实现验证
torch_output = torch.matmul(a, b)

# 验证结果
print(f"最大绝对误差: {torch.max(torch.abs(triton_output - torch_output))}")
print(f"平均绝对误差: {torch.mean(torch.abs(triton_output - torch_output))}")
