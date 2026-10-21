# 3. 用 Makefile 保存命令

三个程序文件与上一阶段相同，只增加一个 `Makefile`。每条命令前使用 TAB。

```bash
make
./demo
make
```

输出 `3`。第二次 `make` 无需重新编译。

```bash
touch add.cpp
make
```

观察只重新编译 `add.cpp`，然后链接。再 `touch add.h`，观察两个 `.cpp` 都重新编译。
