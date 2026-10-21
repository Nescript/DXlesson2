# CMake 与 catkin 简单 Demo

五个阶段统一计算 `1 + 2`，输出 `3`。

| 阶段 | 程序文件 | 主要操作 |
| --- | --- | --- |
| [1. 单文件](demos/01_single_file/README.md) | `main.cpp` | `g++ main.cpp -o demo` |
| [2. 多文件手工编译](demos/02_multi_manual/README.md) | `main.cpp`、`add.cpp`、`add.h` | 一条命令，再拆成编译与链接 |
| [3. Makefile](demos/03_makefile/README.md) | 同上，加一个 Makefile | `make`，观察局部重编 |
| [4. CMake](demos/04_cmake/README.md) | 同上，加三行 CMake 配置 | 配置、构建、运行 |
| [5. catkin](demos/05_catkin/README.md) | 一个 ROS 包、一个发布节点 | 发布 `/lesson2/sum`，输出 `data: 3` |

每个阶段只看自己的目录，命令见对应 README。

程序中只用一个 `add()` 函数。普通 C++ 文件平铺在阶段目录中，ROS 包中的程序文件也放在同一层。

运行环境为 Ubuntu、G++、GNU Make、CMake 3.16。最后一段使用已配置的 ROS 1 Noetic。

教师可在课程根目录验证：

```bash
bash scripts/verify_cpp.sh
bash scripts/verify_ros.sh
```

本次仅调整 Demo 及运行说明。原课件和 `docs` 中的课程大纲、讲稿继续保留；新 Demo 的路径与命令以本页和各阶段 README 为准。
