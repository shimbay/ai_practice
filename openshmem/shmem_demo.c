#include <shmem.h>
#include <stdio.h>

#define N 5

int main(void) {
  int pe, npes;
  int *target;
  int source[N];

  // 初始化 OpenSHMEM 环境
  shmem_init();

  // 获取当前 PE 编号和总 PE 数量
  pe = shmem_my_pe();
  npes = shmem_n_pes();

  // 对称数据分配 (在所有 PE 上都分配)
  target = (int *)shmem_malloc(sizeof(int) * N);

  // 初始化数据
  for (int i = 0; i < N; i++) {
    source[i] = pe * 100 + i; // 每个 PE 初始化不同的值
    target[i] = -1;           // 初始化为 -1
  }

  // 同步所有 PE，确保内存分配和初始化完成
  shmem_barrier_all();

  // PE 0 从所有其他 PE 收集数据
  if (pe == 0) {
    printf("PE 0: Starting data collection...\n");

    for (int src_pe = 0; src_pe < npes; src_pe++) {
      // 从 src_pe 获取数据到本地的 target 数组
      shmem_int_get(target, source, N, src_pe);

      printf("PE 0: Received from PE %d: ", src_pe);
      for (int i = 0; i < N; i++) {
        printf("%d ", target[i]);
      }
      printf("\n");
    }
  }

  // 另一个示例：PE 0 向所有其他 PE 广播数据
  shmem_barrier_all();

  if (pe == 0) {
    int broadcast_data = 999;
    printf("\nPE 0: Broadcasting data to all PEs...\n");

    // 将数据广播到所有 PE 的 target[0] 位置
    for (int dest_pe = 0; dest_pe < npes; dest_pe++) {
      shmem_int_put(&target[0], &broadcast_data, 1, dest_pe);
    }
  }

  // 同步以确保广播完成
  shmem_barrier_all();

  // 所有 PE 打印接收到的广播数据
  printf("PE %d: Received broadcast data: %d\n", pe, target[0]);

  // 释放对称内存
  shmem_free(target);

  // 结束 OpenSHMEM
  shmem_finalize();

  return 0;
}
