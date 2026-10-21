# 5. 用 catkin 构建一个 ROS 包

这里只有一个包 `add_demo`。复用 `add.h` 和 `add.cpp`，把普通程序入口改成 ROS 发布节点。

在本阶段的 `workspace` 目录构建：

```bash
cd workspace
source /opt/ros/noetic/setup.bash
catkin_make
source devel/setup.bash
```

终端 A：

```bash
source /opt/ros/noetic/setup.bash
roscore
```

终端 B：进入同一个 `workspace` 目录，再运行：

```bash
source /opt/ros/noetic/setup.bash
source devel/setup.bash
rosrun add_demo add_node
```

终端 C：

```bash
source /opt/ros/noetic/setup.bash
rostopic echo /lesson2/sum
```

应持续看到 `data: 3`。发布频率为每秒一次。三个终端分别用 Ctrl+C 结束。

本阶段需要已经配置好的 ROS 1 Noetic 环境。`package.xml` 声明依赖；`CMakeLists.txt` 声明要构建的节点。
