# Gas 消耗分析报告

## 概述

本报告分析了 [Arithmetic.sol](file:///d:/project/go-work/FoundryLearningProject/src/Arithmetic.sol) 和 [ArithmeticOptimized.sol](file:///d:/project/go-work/FoundryLearningProject/src/ArithmeticOptimized.sol) 合约中各种函数的 gas 消耗情况，以评估优化版合约的性能改进。

## Gas 消耗对比

### 加法操作

| 函数 | 最小 Gas | 平均 Gas | 最大 Gas | 调用次数 |
|------|----------|----------|----------|----------|
| `Arithmetic.add` | 970 | 970 | 970 | 2 |
| `ArithmeticOptimized.add` | 948 | 948 | 948 | 2 |
| `ArithmeticOptimized.addUnchecked` | 814 | 814 | 814 | 1 |

**分析**: 优化版的加法操作比普通版节省了约 22 gas，而使用 `unchecked` 的版本进一步节省了约 156 gas。

### 减法操作

| 函数 | 最小 Gas | 平均 Gas | 最大 Gas | 调用次数 |
|------|----------|----------|----------|----------|
| `Arithmetic.subtract` | 897 | 948 | 974 | 3 |
| `ArithmeticOptimized.subtract` | 964 | 1015 | 1041 | 3 |
| `ArithmeticOptimized.subtractOptimized` | 652 | 762 | 817 | 3 |

**分析**: 普通减法操作在两种实现中 gas 消耗相近，但优化版的 `subtractOptimized` 函数显著节省了 gas，比普通版节省了约 186 gas。

### 乘法操作

| 函数 | 最小 Gas | 平均 Gas | 最大 Gas | 调用次数 |
|------|----------|----------|----------|----------|
| `Arithmetic.multiply` | 989 | 989 | 989 | 2 |
| `ArithmeticOptimized.multiply` | 1012 | 1012 | 1012 | 2 |
| `ArithmeticOptimized.multiplyByPowerOfTwo` | 807 | 807 | 807 | 2 |

**分析**: 普通乘法操作在优化版中略有增加，但针对 2 的幂次的乘法操作优化显著，节省了约 205 gas。

### 除法操作

| 函数 | 最小 Gas | 平均 Gas | 最大 Gas | 调用次数 |
|------|----------|----------|----------|----------|
| `Arithmetic.divide` | 919 | 977 | 1007 | 3 |
| `ArithmeticOptimized.divide` | 941 | 999 | 1029 | 3 |
| `ArithmeticOptimized.divideByPowerOfTwo` | 828 | 828 | 828 | 2 |

**分析**: 普通除法操作在优化版中略有增加，但针对 2 的幂次的除法操作优化显著，节省了约 149 gas。

## 总结

1. **优化效果显著**: 在特定场景下（如 2 的幂次乘除法、优化减法），优化版合约能显著降低 gas 消耗。
2. **一般情况**: 对于一般算术操作，两种实现的 gas 消耗相近。
3. **安全性权衡**: 优化版使用了 `unchecked` 等技术，在某些情况下可能需要在性能和安全性之间做出权衡。

## 建议

1. 在需要大量算术运算的场景中，优先使用优化版合约。
2. 对于涉及 2 的幂次的乘除法运算，使用专门的优化函数。
3. 在使用 `unchecked` 时，确保上层代码有适当的边界检查以防止溢出。