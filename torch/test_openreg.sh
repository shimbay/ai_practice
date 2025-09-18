#! /bin/bash

WS=$(realpath $(dirname "${BASH_SOURCE[0]}"))

cd ${WS}/open_registration_extension

# bear -- \
python3 setup.py develop

cd ${WS}

python3 torch_backend.py
