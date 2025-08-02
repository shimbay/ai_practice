import axnn.language as axl
import axnn.ops as axops
import axnn.n2n as axn2n
import axnn.c2c as axc2c


# 假设输入在所有的
def demo_1(a: axl.Tensor, b: axl.Tensor):
    x_block_size = 16
    y_block_size = 16

    with axl.Kernel(a.shape[0] // x_block_size, a.shape[1] // y_block_size) as (
        x_id,
        y_id,
    ):
        a_tile = a[
            x_block_size * x_id : x_block_size * (x_id + 1),
            y_block_size * y_id : y_block_size * (y_id + 1),
        ]
        b_tile = b[
            x_block_size * x_id : x_block_size * (x_id + 1),
            y_block_size * y_id : y_block_size * (y_id + 1),
        ]

        with axl.Chip() as (chip_id, chip_num):
            per_chip_size = a_tile.shape[0] // chip_num
            cur_chip_a_tile = a_tile[
                per_chip_size * chip_id : per_chip_size * (chip_id + 1)
            ]
            cur_chip_b_tile = b_tile[
                per_chip_size * chip_id : per_chip_size * (chip_id + 1)
            ]

            cur_chip_output = axl.create_tensor_like(
                cur_chip_b_tile, mem=axl.MemoryType.DDR
            )

            with axl.Core() as (core_id, core_num):
                per_core_size = cur_chip_a_tile.shape[0] // core_num
                cur_core_a_tile = cur_chip_a_tile[
                    per_core_size * core_id, per_core_size * (core_id + 1)
                ]
                cur_core_b_tile = cur_chip_b_tile[
                    per_core_size * core_id, per_core_size * (core_id + 1)
                ]

                a_local = axl.create_tensor_like(
                    cur_core_a_tile, mem=axl.MemoryType.OCM
                )
                axops.load(cur_core_a_tile, a_local)

                b_local = axl.create_tensor_like(
                    cur_core_b_tile, mem=axl.MemoryType.OCM
                )
                axops.load(cur_core_b_tile, b_local)

                r_local = axl.create_tensor_like(
                    cur_core_b_tile, mem=axl.MemoryType.OCM
                )

                a_broadcast_shape = a_local.shape
                a_broadcast_shape[0] *= core_num
                a_broadcast = axl.create_tensor(
                    a_broadcast_shape, a_local.dtype, mem=axl.MemoryType.OCM
                )

                # axnn.n2n only work in axnn.language.Core Context
                axn2n.all_gather(a_local, a_broadcast, core_id=core_id)

                axops.add(a_broadcast, b_local, r_local)

                axops.store(r_local, cur_chip_output)

            # axnn.c2c only work in axnn.language.Chip Context
            axc2c.all_reduce(cur_chip_output, cur_chip_output, chip_id=chip_id)
