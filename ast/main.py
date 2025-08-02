# https://eli.thegreenplace.net/2025/decorator-jits-python-as-a-dsl/

import ast
import astpretty
import dis
import functools
import inspect

from dataclasses import dataclass
from enum import Enum
from typing import Any


class ASTJITError(RuntimeError):
    pass


class BytecodeJITError(RuntimeError):
    pass


class _ExprCodeEmitter(ast.NodeVisitor):
    def __init__(self):
        self.args = []
        self.return_expr = None
        self.op_map = {
            ast.Add: Op.ADD,
            ast.Sub: Op.SUB,
            ast.Mult: Op.MUL,
            ast.Div: Op.DIV,
        }

    def visit(self, node: ast.AST) -> Any:
        method_name = "visit_" + node.__class__.__name__
        base = f"method name: {method_name}"
        if isinstance(node, ast.FunctionDef):
            print(f"{base}, {node.name}, {[arg.arg for arg in node.args.args]}")
        elif isinstance(node, ast.Name):
            print(f"{base}, {node.id}")
        elif isinstance(node, ast.Call):
            print(f"{base}, {type(node.func)}")
        elif isinstance(node, ast.Load) or isinstance(node, ast.Store):
            print(f"{base}, {node.__dict__}")
        else:
            print(f"{base}")

        return super().visit(node)

    # def visit_FunctionDef(self, node):
    #     self.args = [arg.arg for arg in node.args.args]
    #     if len(node.body) != 1 or not isinstance(node.body[0], ast.Return):
    #         raise ASTJITError("Function must consist of a single return statement")
    #     self.visit(node.body[0])

    # def visit_Return(self, node):
    #     self.return_expr = self.visit(node.value)

    # def visit_Name(self, node):
    #     try:
    #         idx = self.args.index(node.id)
    #     except ValueError:
    #         raise ASTJITError(f"Unknown variable {node.id}")
    #     return VarExpr(node.id, idx)

    # def visit_Constant(self, node):
    #     return ConstantExpr(node.value)

    # def visit_BinOp(self, node):
    #     left = self.visit(node.left)
    #     right = self.visit(node.right)
    #     try:
    #         op = self.op_map[type(node.op)]
    #         return BinOpExpr(left, right, op)
    #     except KeyError:
    #         raise ASTJITError(f"Unsupported operator {node.op}")


class Expr:
    pass


@dataclass
class ConstantExpr(Expr):
    value: float


@dataclass
class VarExpr(Expr):
    name: str
    arg_idx: int


class Op(Enum):
    ADD = "+"
    SUB = "-"
    MUL = "*"
    DIV = "/"


@dataclass
class BinOpExpr(Expr):
    left: Expr
    right: Expr
    op: Op


def astjit(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        source = inspect.getsource(func)

        with open("ast_parse.txt", "w+") as f:
            f.write(astpretty.pformat(ast.parse(source), indent="  "))

        if kwargs:
            raise ASTJITError("Keyword arguments are not supported")
        tree = ast.parse(source)

        emitter = _ExprCodeEmitter()
        emitter.visit(tree)
        return 1

    return wrapper


def bytecodejit(func):
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        if kwargs:
            raise BytecodeJITError("Keyword arguments are not supported")

        _emit_exprcode(func)
        return 2

    return wrapper


def _emit_exprcode(func):
    dis.dis(func)
    # bc = func.__code__
    # stack = []
    # for inst in dis.get_instructions(func):
    #     match inst.opname:
    #         case "LOAD_FAST":
    #             idx = inst.arg
    #             stack.append(VarExpr(bc.co_varnames[idx], idx))
    #         case "LOAD_CONST":
    #             stack.append(ConstantExpr(inst.argval))
    #         case "BINARY_OP":
    #             right = stack.pop()
    #             left = stack.pop()
    #             match inst.argrepr:
    #                 case "+":
    #                     stack.append(BinOpExpr(left, right, Op.ADD))
    #                 case "-":
    #                     stack.append(BinOpExpr(left, right, Op.SUB))
    #                 case "*":
    #                     stack.append(BinOpExpr(left, right, Op.MUL))
    #                 case "/":
    #                     stack.append(BinOpExpr(left, right, Op.DIV))
    #                 case _:
    #                     raise BytecodeJITError(f"Unsupported operator {inst.argval}")
    #         case "RETURN_VALUE":
    #             if len(stack) != 1:
    #                 raise BytecodeJITError("Invalid stack state")
    #             return stack.pop()
    #         case "RESUME" | "CACHE":
    #             # Skip nops
    #             pass
    #         case _:
    #             raise BytecodeJITError(f"Unsupported opcode {inst.opname}")


def wrapper(func):
    def _w(*args, **kwargs):
        return func(*args, **kwargs)

    return _w


@wrapper
def acc(x, n):
    return x + n


# @astjit
@bytecodejit
def some_expr(a, b, c):

    with open("abc") as f:
        if a == 1:
            a += 1
        else:
            a -= 1

    for i in range(b):
        b = acc(b, i)
        c = acc(c, i)

    return b / (a + 2) - c * (b - a)


some_expr(1, 2, 3)
