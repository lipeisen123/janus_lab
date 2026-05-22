# 技术栈清单

> 从 `cpu/` 项目实际代码和配置中提取，按类别列出。

---

## 编程语言

| 技术 | 项目中的角色 |
|------|-------------|
| **Verilog** (IEEE 1364-2001) | 所有 19 个 `.v` 文件的主体语言，描述 CPU 硬件电路的行为和结构 |
| **Makefile** (GNU Make) | 构建自动化脚本，编排编译、仿真、波形查看、清理的流程 |
| **RISC-V Assembly** (RV32I) | `prog.hex` 的源语言（手工转换为机器码），用于编写 CPU 测试程序 |

---

## 硬件描述语言特性（Verilog 子集）

| 特性 | 项目中的角色 |
|------|-------------|
| **`wire` / `reg` 信号** | 全部模块间通信——wire 是连线，reg 是寄存器 |
| **`always @(posedge clk)`** | 描述时序逻辑：每个时钟上升沿触发（寄存器写、PC更新） |
| **`always @(*)`** | 描述组合逻辑：输入变化自动重算（ALU、控制信号、立即数） |
| **`assign`** | 连续赋值语句，用于组合逻辑连线 |
| **`$readmemh`** | 仿真时把 `prog.hex` 加载到指令存储器 |
| **`$dumpfile` / `$dumpvars`** | 生成 `.vcd` 波形文件供 GTKWave 查看 |
| **`define / localparam** | 定义常量（opcode、ALU操作码、状态编码） |

---

## 仿真与验证工具

| 工具 | 类型 | 项目中的角色 |
|------|------|-------------|
| **Icarus Verilog** (`iverilog`) | 仿真编译器 | 把 `.v` 源码编译为 `vvp` 可执行文件 |
| **vvp** | 仿真运行时 | 执行编译后的仿真，输出波形和日志 |
| **Verilator** | 仿真编译器（备选） | 将 Verilog 编译为 C++ 再运行，速度更快 |
| **GTKWave** | 波形查看器 | 打开 `.vcd` 文件，以折线图展示所有信号的时序变化 |
| **Yosys** | 综合工具（进阶） | FPGA/ASIC 流程前端的 RTL 综合 |
| **SymbiYosys** | 形式验证（进阶） | 对有界模型检查（BMC）提供 SMT solver 驱动 |

---

## 形式验证技术

| 技术/概念 | 项目中的角色 |
|-----------|-------------|
| **合约 (Contracts)** | 13 条自然语言描述的 CPU 正确性规则，覆盖模块级、流水线级、ISA 级 |
| **断言 (Assertions)** | `$error` + `if` 条件检查，嵌入在 `checks/` 的测试 harness 中 |
| **Harness** | 将被测模块与断言包装在一起的 Verilog 测试壳 |
| **PASS/FAIL 协议** | 测试程序向地址 `0xFFFF_0000` 写 `1` (PASS) 或 `0` (FAIL)，testbench 监控该地址 |
| **Hoare 逻辑** | `{P} C {Q}` 三元组：前置条件 → 模块执行 → 后置条件，用于合约的设计框架 |
| **有界模型检查 (BMC)** | 在 k 个时钟周期内展开电路状态，检查是否出现坏状态 |
| **SMT-LIB** | 向 SMT solver 描述验证问题的标准文本格式（进阶扩展用） |

---

## 数据存储（硬件层面）

| 存储类型 | 实现位置 | 项目中的角色 |
|----------|---------|-------------|
| **IMEM (指令 ROM)** | `imem.v`，256 × 32 bit | 存放 CPU 要执行的程序指令 |
| **DMEM (数据 RAM)** | `dmem.v`，4096 × 8 bit | 存放程序运行时读写的数据 |
| **寄存器堆** | `regfile.v`，32 × 32 bit | CPU 内部的 32 个通用寄存器（x0–x31） |
| **流水线寄存器** | `pipeline_regs.v` × 4 | IF/ID、ID/EX、EX/MEM、MEM/WB 四级流水线之间的数据暂存 |
| **.vcd 波形文件** | `dump.vcd` | 仿真产生的信号变化时间线记录 |
| **.hex 程序文件** | `prog.hex` | 十六进制机器码，仿真时加载到 IMEM |

---

## 工程化工具

| 工具 | 项目中的角色 |
|------|-------------|
| **GNU Make** | 主构建工具：`make sim` 仿真、`make check-all` 跑全部验证 |
| **Makefile 目标** | 9 个 make 目标：sim、waves、check-all、check-alu、check-regfile、check-hazard、check-bug-golden、check-bug-inject、clean |
| **条件编译** | `ifdef USE_PIPELINED` / `ifdef INJECT_BUG` 控制单周期 vs 流水线、正确版 vs bug 版 |
| **Git** | （项目目录位于桌面，可接入版本管理） |

---

## 架构与设计模式

| 概念 | 项目中的角色 |
|------|-------------|
| **RISC-V RV32I** | 指令集架构标准：47 条基础整数指令，32 位固定长度编码 |
| **哈佛架构** | 指令存储器和数据存储器物理分离（IMEM ≠ DMEM），取值和数据读写互不冲突 |
| **5 级流水线** | IF → ID → EX → MEM → WB，五级同时工作，每周期可完成一条指令 |
| **两级控制解码** | `ctrl.v`（opcode → alu_op）→ `aluctrl.v`（alu_op + funct3/7 → alu_ctrl），控制信号分两级产生 |
| **读中写转发 (RDW)** | `regfile.v` 中：同周期内写入的新值在同一周期读回时直接返回，不等时钟 |
| **数据转发 (Forwarding)** | `forward_unit.v`：EX/MEM或MEM/WB阶段产出的结果直送 ALU 输入，跳过寄存器回写延迟 |
| **冒险检测 (Hazard Detection)** | `hazard_unit.v`：检测 load-use 冲突（停顿一周期）和控制流冲突（刷新错误路径指令） |
| **停顿优先级 > 刷新** | 同时出现 load-use 和分支预测命中时，停顿优先，避免丢弃需要重取的指令 |
| **NOP 气泡** | 流水线刷新时插入 `ADDI x0, x0, 0`（全零编码），无副作用 |
| **x0 硬连线为零** | 第 0 号寄存器始终返回 0，写入被丢弃 — RISC-V 规范的签名特性 |
| **JALR LSB 清零** | 跳转目标地址计算为 `(rs1 + imm) & ~1`，保证目标地址对齐 |
| **Top-Down Specification** | 合约生成不只从模块实现推导，还参考调用方期望和 ISA 规范（来自 FM-Agent 方法论） |
| **合约 → 断言 → 测试 → 证据** | 验证流水线：自然语言规则 → Verilog 断言 → 定向/随机测试 → 可复现 bug 报告 |
