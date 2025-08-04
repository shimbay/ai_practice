from typing import Optional, Union
import torch


class MoeMLP(torch.nn.Module):
    def __init__(self, gate_proj, up_proj, down_proj) -> None:
        super().__init__()

        self.gate_proj = gate_proj
        self.up_proj = up_proj
        self.down_proj = down_proj
        self.act_fn = torch.nn.SiLU()

    def forward(self, x):
        return self.down_proj(self.act_fn(self.gate_proj(x)) * self.up_proj(x))


def slice_dim_for_rank(rank: int, world_size: int):
    def impl(
        t: Union[torch.Tensor, torch.nn.Parameter], dim: int
    ) -> Union[torch.Tensor, torch.nn.Parameter]:
        slices = [slice(None)] * len(t.shape)
        slice_size = t.shape[dim] // world_size
        slices[dim] = slice(rank * slice_size, (rank + 1) * slice_size)
        return t[slices]

    return impl


def slice_linear_oc(rank: int, world_size: int):
    def impl(proj: torch.nn.Linear) -> torch.nn.Linear:
        o = torch.nn.Linear(proj.in_features, proj.out_features // world_size)
        o.weight = torch.nn.Parameter(
            slice_dim_for_rank(rank, world_size)(proj.weight, 0)
        )
        o.bias = None
        if proj.bias is not None:
            o.bias = torch.nn.Parameter(
                slice_dim_for_rank(rank, world_size)(proj.bias, 0)
            )
        return o

    return impl


def slice_linear_ic(rank: int, world_size: int):
    def impl(proj: torch.nn.Linear) -> torch.nn.Linear:
        o = torch.nn.Linear(proj.in_features // world_size, proj.out_features)
        o.weight = torch.nn.Parameter(
            slice_dim_for_rank(rank, world_size)(proj.weight, 1)
        )
        o.bias = proj.bias
        return o

    return impl
