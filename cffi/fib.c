// fib.c - 斐波那契计算函数用于性能测试
#include <stdint.h>

int32_t fib(int32_t n) {
  if (n < 2)
    return n;
  return fib(n - 1) + fib(n - 2);
}

double add(double a, double b) { return a + b; }

void add_array(double *in1, double *in2, double *out, int length) {
  for (int i = 0; i < length; i++) {
    out[i] = in1[i] + in2[i];
  }
}
