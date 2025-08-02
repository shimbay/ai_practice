#include <cstdio>
#include <cstdlib>
#include <nccl.h>

#define NCCLCHECK(cmd)                                                         \
  do {                                                                         \
    ncclResult_t r = cmd;                                                      \
    if (r != ncclSuccess) {                                                    \
      printf("NCCL error: %s\n", ncclGetErrorString(r));                       \
      MPI_Abort(MPI_COMM_WORLD, 1);                                            \
    }                                                                          \
  } while (0)

int main(int argc, char *argv[]) {
  // 1. 初始化 MPI
  MPI_Init(&argc, &argv);
  int mpi_rank, mpi_size;
  MPI_Comm_rank(MPI_COMM_WORLD, &mpi_rank);
  MPI_Comm_size(MPI_COMM_WORLD, &mpi_size);

  // 2. 生成并广播 ncclUniqueId
  ncclUniqueId id;
  if (mpi_rank == 0) {
    // 只有 Rank 0 生成 uniqueId
    NCCLCHECK(ncclGetUniqueId(&id));
    printf("Rank 0: Generated ncclUniqueId (IP:port encoded in binary)\n");
  }

  // 广播 id 到所有进程
  MPI_Bcast(&id, sizeof(id), MPI_BYTE, 0, MPI_COMM_WORLD);
  printf("Rank %d: Received ncclUniqueId\n", mpi_rank);

  // 3. 打印部分调试信息（可选）
  // 注意：ncclUniqueId 是二进制结构，直接打印无意义，需解析
  if (mpi_rank == 0) {
    printf("ncclUniqueId (hex dump, contains IP and port):\n");
    for (int i = 0; i < sizeof(id); i++) {
      printf("%02x ", ((unsigned char *)&id)[i]);
    }
    printf("\n");
  }

  // 4. 后续可基于 id 初始化 NCCL 通信域
  // ncclComm_t comm;
  // NCCLCHECK(ncclCommInitRank(&comm, mpi_size, id, mpi_rank));

  MPI_Finalize();
  return 0;
}
