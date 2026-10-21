# 4. 用 CMake 描述程序

三个程序文件继续复用，只增加三行 `CMakeLists.txt`。

```bash
cmake -S . -B build
cmake --build build
./build/demo
```

输出 `3`。第一条命令配置并生成构建系统，第二条命令执行构建。

演示项目增加文件时，把新 `.cpp` 加到 `add_executable(...)` 的文件列表中。这里先集中认识目标名称和源文件列表。
