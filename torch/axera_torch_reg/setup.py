import distutils.command.clean
import shutil
from pathlib import Path

from setuptools import find_packages, setup
from torch.utils.cpp_extension import BuildExtension, CppExtension

PACKAGE_NAME = "axera_torch_reg"
VERSION = "1.0"

ROOT_DIR = Path(__file__).absolute().parent
CSRS_DIR = ROOT_DIR / PACKAGE_NAME / "csrc"
BUILD_DIR = ROOT_DIR / "build"

CXX_FLAGS = {
    "cxx": [
        "-g",
        "-Wall",
        "-Werror",
    ]
}


class clean(distutils.command.clean.clean):
    def run(self):
        distutils.command.clean.clean.run(self)

        for path in ROOT_DIR.glob("**/*.so"):
            path.unlink()

        build_dirs = [BUILD_DIR]
        for path in build_dirs:
            if path.exists():
                shutil.rmtree(str(path), ignore_errors=True)


if __name__ == "__main__":

    sources = list(CSRS_DIR.glob("*.cpp"))

    ext_modules = [
        CppExtension(
            name=f"{PACKAGE_NAME}._C",
            sources=sorted(str(s) for s in sources),
            include_dirs=[CSRS_DIR],
            extra_compile_args=CXX_FLAGS,
        )
    ]

    setup(
        name=PACKAGE_NAME,
        version=VERSION,
        author="",
        description="PyTorch out of tree registration",
        packages=find_packages(exclude=("test",)),
        package_data={PACKAGE_NAME: ["*.dll", "*.dylib", "*.so"]},
        install_requires=[
            "torch",
        ],
        ext_modules=ext_modules,
        python_requires=">=3.8",
        cmdclass={
            "build_ext": BuildExtension.with_options(no_python_abi_suffix=True),
            "clean": clean,
        },
    )
