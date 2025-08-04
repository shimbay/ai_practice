import torch
import torch.nn.functional as F
import math
from dataclasses import dataclass
from scipy.spatial.distance import cosine
from utils.nn import MoeMLP
from utils.nn import slice_linear_ic
from utils.nn import slice_linear_oc

import moe.modeling_qwen3_moe as qwen3_moe

torch.manual_seed(1)


@dataclass
class Config:
    hidden_size: int = 2048
    num_experts: int = 128
    num_experts_per_tok: int = 8
    moe_intermediate_size: int = 768
    norm_topk_prob: bool = True


cfg = Config()

m = qwen3_moe.Qwen3MoeSparseMoeBlock(cfg)

hidden_states = torch.rand(1, 12, cfg.hidden_size)
output_gt = m(hidden_states)[0].reshape(-1, cfg.hidden_size).detach()


# vectorization verison of MOE expert parallel
def expert_parallel(hidden_states: torch.Tensor, world_size: int):
    # [token_num, dim]
    hidden_states = hidden_states.view(-1, cfg.hidden_size)

    TOKEN_NUM = hidden_states.shape[0]
    MOE_KERNEL_BATCH_SIZE = 8
    TOPK = cfg.num_experts_per_tok
    EXPERT_NUM = cfg.num_experts
    EXPERT_NUM_PER_RANK = cfg.num_experts // world_size
    EXPERT_TILE_NUM = 4

    # [token_num, expert_num]
    router_logits = F.linear(hidden_states, m.gate.weight, m.gate.bias)
    # [token_num, expert_num]
    routing_weights = F.softmax(router_logits, dim=1)
    # [token_num, topk], [token_num, topk]
    routing_weights, selected_experts = torch.topk(routing_weights, TOPK, dim=-1)
    # [topk, token_num]
    transposed_selected_expert = selected_experts.transpose(0, 1)
    if cfg.norm_topk_prob:
        # [token_num, topk], [token_num, topk]
        routing_weights /= routing_weights.sum(dim=-1, keepdim=True)

    token_expert_weights = torch.zeros(
        (TOKEN_NUM, EXPERT_NUM), dtype=routing_weights.dtype
    )
    token_expert_weights.scatter_(
        1,
        selected_experts,
        routing_weights,
    )

    expert_token_map = torch.zeros((EXPERT_NUM, TOKEN_NUM), dtype=torch.int8)
    expert_token_map.scatter_(
        0,
        transposed_selected_expert,
        torch.ones_like(transposed_selected_expert, dtype=torch.int8),
    )

    all_rank_final_tokens = torch.zeros(
        (world_size, TOKEN_NUM, cfg.hidden_size), dtype=hidden_states.dtype
    )
    for rank in range(world_size):
        LOWER_EXPERT_IDX = rank * EXPERT_NUM_PER_RANK
        UPPER_EXPERT_IDX = (rank + 1) * EXPERT_NUM_PER_RANK
        cur_rank_experts = m.experts[LOWER_EXPERT_IDX:UPPER_EXPERT_IDX]

        # [token_num+1, dim]
        _hidden_states = torch.zeros(
            (TOKEN_NUM + 1, cfg.hidden_size), dtype=hidden_states.dtype
        )
        _hidden_states[:TOKEN_NUM, :] = hidden_states
        # [token_num+1, expert_num_per_rank]
        _token_expert_weights = torch.zeros(
            (TOKEN_NUM + 1, EXPERT_NUM_PER_RANK), dtype=routing_weights.dtype
        )
        _token_expert_weights[:TOKEN_NUM, :] = token_expert_weights[
            :, LOWER_EXPERT_IDX:UPPER_EXPERT_IDX
        ]
        # [expert_num_per_rank, token_num]
        _expert_token_map = expert_token_map[LOWER_EXPERT_IDX:UPPER_EXPERT_IDX, :]

        # [token_num+1, dim]
        _final_tokens = torch.zeros_like(_hidden_states, dtype=_hidden_states.dtype)

        for expert_idx in range(EXPERT_NUM_PER_RANK):
            token_idxs = _expert_token_map[expert_idx]
            effi_token_idxs = torch.nonzero(token_idxs, as_tuple=True)[0]
            effi_token_num = len(effi_token_idxs)

            # split expert to adapt the ocm size
            for t in range(EXPERT_TILE_NUM):
                # compile time computation
                expert = cur_rank_experts[expert_idx]
                ic_slicer = slice_linear_ic(t, EXPERT_TILE_NUM)
                oc_slicer = slice_linear_oc(t, EXPERT_TILE_NUM)
                expert_tile = MoeMLP(
                    gate_proj=oc_slicer(expert.gate_proj),
                    up_proj=oc_slicer(expert.up_proj),
                    down_proj=ic_slicer(expert.down_proj),
                )

                for b in range(math.ceil(effi_token_num / MOE_KERNEL_BATCH_SIZE)):
                    start = b * MOE_KERNEL_BATCH_SIZE
                    kernel_effi_token_num = min(
                        effi_token_num - start, MOE_KERNEL_BATCH_SIZE
                    )

                    kernel_token_idxs = torch.full(
                        (MOE_KERNEL_BATCH_SIZE,),
                        fill_value=TOKEN_NUM,
                        dtype=torch.int64,
                    )
                    kernel_token_idxs[:kernel_effi_token_num] = effi_token_idxs[
                        start : start + kernel_effi_token_num
                    ]

                    kernel_tokens = torch.index_select(
                        _hidden_states,
                        dim=0,
                        index=kernel_token_idxs,
                    )
                    kernel_expert_weights = torch.index_select(
                        _token_expert_weights,
                        dim=0,
                        index=kernel_token_idxs,
                    )[:, expert_idx].unsqueeze(dim=1)

                    kernel_tokens = expert_tile(kernel_tokens) * kernel_expert_weights

                    _final_tokens.index_add_(0, kernel_token_idxs, kernel_tokens)
        all_rank_final_tokens[rank] = _final_tokens[:TOKEN_NUM]
    final_tokens = torch.sum(all_rank_final_tokens, dim=0, keepdim=False)
    return final_tokens


# python3 -m moe.main
output = expert_parallel(hidden_states, 2).detach()
for i in range(output.shape[0]):
    print(f"{i}, {1-cosine(output[i], output_gt[i])}")
