from onnxscript import script
import onnx
import numpy as np

# We use ONNX opset 15 to define the function below.
from onnxscript import opset15 as op
from onnxscript import FLOAT

# We use the script decorator to indicate that the following function is meant
# to be translated to ONNX.
# @script()
# def MatmulAdd(X, Wt, Bias):
#     return op.MatMul(X, Wt) + Bias
#
#
# x = np.array([[0, 1], [2, 3]], dtype=np.float32)
# wt = np.array([[0, 1], [2, 3]], dtype=np.float32)
# bias = np.array([0, 1], dtype=np.float32)
# result = MatmulAdd(x, wt, bias)
# print(result)


@script()
def MatmulAddModel(X, Wt, Bias):
    x = 1 + 2
    return op.MatMul(X[:x], Wt) + Bias[:x]


model = MatmulAddModel.to_model_proto()  # returns an onnx.ModelProto
onnx.save(model, "test.onnx")
