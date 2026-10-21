# 2. 多文件手工编译

三个文件放在同一目录：`main.cpp` 调用函数，`add.h` 声明函数，`add.cpp` 实现函数。

先用一条命令：

```bash
g++ main.cpp add.cpp -o demo
./demo
```

再拆成编译和链接：

```bash
g++ -c main.cpp
g++ -c add.cpp
g++ main.o add.o -o demo
./demo
```

输出 `3`。故意只执行 `g++ main.o -o missing_demo`，观察缺少 `add` 实现时的链接报错；加入 `add.o` 后恢复。
