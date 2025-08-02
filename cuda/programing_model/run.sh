#! /bin/bash

nvcc -o driver_api_sample driver_api_sample.cu -lcuda
./driver_api_sample
