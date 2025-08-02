# Load model directly
from transformers import AutoTokenizer, AutoModelForCausalLM

model = AutoModelForCausalLM.from_pretrained(
    "/data/sunyunbo/workspace/data/Qwen/Qwen3-30B-A3B"
)
print(type(model))
