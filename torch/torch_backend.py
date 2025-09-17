import torch
import logging
import warnings

import pytorch_openreg

logging.basicConfig(level=logging.DEBUG)
warnings.simplefilter(action="ignore", category=FutureWarning)


def main():
    stream = torch.Stream(device="axera:0")
    stream.synchronize()

    stream = torch.Stream(device="axera:1")
    stream.synchronize()

    x = torch.empty(3, 3)
    print(f"a: {x.device}")

    torch.set_default_device("axera:1")
    print(f"set default device")

    x = torch.empty(3, 3)
    print(f"b: {x.device}")

    x = torch.empty(3, 3, device="axera")
    print(f"c: {x.device}")


if __name__ == "__main__":
    main()
