# URDF 与 tf2 课程讲稿

本课程面向已经学习 ROS 节点、话题、launch 与 catkin 的控制组新成员，采用 ROS 1 Noetic 的术语和接口。第一讲从 XML 开始，逐步写出底盘、车轮与雷达的 URDF 描述。第二讲先解决一个小车定位问题，再扩展到三维位姿和欧拉角。理解万向节锁后，用复数的平面旋转引入轴角与四元数，最后回到 tf2 的位姿计算。

语法示例采用一辆尺寸简化的教学小车，底盘坐标系为 `base_link`，雷达坐标系为 `lidar_link`。这些尺寸用于课堂推导。前序作业中的 SMB 工程作为实际阅读示例，其雷达帧使用 `rslidar` 等名称，参数以该工程实际展开的模型为准。

## 第一讲 从 XML 学习 URDF

### 1 XML 怎样记录机器人信息

前面运行仿真时，我们已经在 RViz 中看到过小车。接下来从描述文件入手，看程序怎样知道底盘的尺寸、车轮的位置，以及雷达安装在哪里。

URDF 的全称是 Unified Robot Description Format，即统一机器人描述格式。它使用 XML 记录机器人部件、部件连接和物理属性。先掌握 XML 的写法，再学习 URDF 规定的标签，就能逐步读懂模型文件。

XML 通过元素组织内容。一个元素通常由开始标签、内部内容和结束标签构成，标签上的属性进一步给出名称或数值。

```xml
<link name="base_link">
  <visual>
    <geometry>
      <box size="0.6 0.4 0.2"/>
    </geometry>
  </visual>
</link>
```

这里的 `link`、`visual`、`geometry` 和 `box` 都是元素名。`name="base_link"` 为 link 指定名称，`size="0.6 0.4 0.2"` 为长方体指定尺寸。`box` 内部没有其他内容，因此使用 `/>` 结束，这种写法称为自闭合标签。

XML 文档需要一个根元素，标签要正确嵌套并闭合，名称区分大小写，属性值需要引号。缩进用于帮助阅读，实际层次由标签决定。上面这段是模型内部的片段，完整 URDF 还需要在外面包上 `robot` 元素。

### 2 第一个 URDF：用长方体表示底盘

下面是一份完整的单底盘 URDF，可以保存为 `car.urdf`。文件声明机器人名为 `teaching_car`，包含一个名为 `base_link` 的 link。

```xml
<?xml version="1.0"?>
<robot name="teaching_car">
  <link name="base_link">
    <visual>
      <origin xyz="0 0 0" rpy="0 0 0"/>
      <geometry>
        <box size="0.6 0.4 0.2"/>
      </geometry>
      <material name="blue">
        <color rgba="0.1 0.4 0.8 1"/>
      </material>
    </visual>
  </link>
</robot>
```

`robot` 包住整份机器人描述，`link` 表示一个刚体并提供附着在它上面的局部坐标系。刚体建模忽略部件内部的形变。底盘与车轮可以相对转动，因此通常分成不同 link。

`visual` 描述显示外观。`box` 的三个数按 x、y、z 顺序给出完整边长，单位是米，所以这个底盘长 0.6 m、宽 0.4 m、高 0.2 m。`rgba` 的四项分别表示红、绿、蓝和不透明度，取值通常为 0 到 1。

其他常见几何体包括圆柱和球。圆柱使用 `radius` 与 `length`，球使用 `radius`。复杂外形可以通过 `mesh` 引用模型文件，但需要同时确认网格的单位、朝向和缩放。

### 3 origin 描述几何体怎样摆放

坐标系由一个原点和三根互相垂直的坐标轴组成。它可以附着在底盘、车轮或传感器上，原点由建模者选择。`base_link` 的名称只说明它承担车体参考系的角色，具体原点还要看模型定义。

上例中，visual 的 `origin` 为零，长方体中心与 `base_link` 原点重合。若改成下面的写法，长方体会沿 `base_link` 的正 z 方向移动 0.1 m。

```xml
<origin xyz="0 0 0.1" rpy="0 0 0"/>
```

`xyz` 表示平移，`rpy` 表示方向。这里先把 `rpy="0 0 0"` 理解为轴向一致，三个角的详细含义放到第二讲展开。URDF 的长度单位是米，旋转角单位是弧度。

visual 内的 origin 只决定外观相对于所属 link 的摆放。改变这个值后，`base_link` 坐标系本身仍保持原来的定义。后面 joint 中也会出现 origin，读取时要结合它所在的标签判断参考关系。

### 4 用 fixed joint 将雷达安装到底盘

现在给小车增加雷达。先定义雷达自身的 link，再用 joint 把它连接到底盘。下面的内容放在前面同一个 `robot` 内，与 `base_link` 并列。

```xml
<link name="lidar_link">
  <visual>
    <geometry>
      <cylinder radius="0.05" length="0.06"/>
    </geometry>
    <material name="gray">
      <color rgba="0.3 0.3 0.3 1"/>
    </material>
  </visual>
</link>

<joint name="base_to_lidar" type="fixed">
  <parent link="base_link"/>
  <child link="lidar_link"/>
  <origin xyz="0.2 0 0.3" rpy="0 0 0"/>
</joint>
```

`parent` 指定父 link，`child` 指定子 link。这个 joint 说明雷达原点位于底盘原点前方 0.2 m、上方 0.3 m，坐标轴与底盘同向。`fixed` 表示这对 link 的相对位姿保持不变。

小车行驶时，底盘与雷达一起移动，雷达相对于底盘的安装关系仍然固定。第二讲会用到的装配变换，就来自这里的 joint origin 或对应的实际标定结果。

这里也能看到两种树的区别：XML 嵌套组织文件内容，link 与 joint 的名称引用组织机器人连接。两个 link 在 XML 中并列书写，依然可以通过 joint 建立父子关系。

### 5 用可动 joint 描述车轮

雷达固定在底盘上，车轮则需要转动。我们继续定义一个左前轮，并让它通过 continuous joint 连接到底盘。示例车轮半径为 0.1 m，宽度为 0.04 m。

```xml
<link name="left_front_wheel">
  <visual>
    <geometry>
      <cylinder radius="0.1" length="0.04"/>
    </geometry>
  </visual>
</link>

<joint name="left_front_wheel_joint" type="continuous">
  <parent link="base_link"/>
  <child link="left_front_wheel"/>
  <origin xyz="0.2 0.24 -0.1" rpy="-1.57079632679 0 0"/>
  <axis xyz="0 0 1"/>
</joint>
```

圆柱的局部轴沿 z 方向，joint 的安装旋转把这根轴转到车体的左右方向。`axis` 在关节局部坐标系中表达，因此这里的 `0 0 1` 需要和 origin 的方向一起阅读。车轮的实时转角再叠加到安装关系上，决定它当前的姿态。

四个轮子可以采用相同写法，再分别调整名称和安装位置。前后轮通过 x 的正负区分，左右轮通过 y 的正负区分。车轮尺寸、安装位置和关节名称都需要与所采用的小车模型一致。

常见关节类型可以按运动方式理解：`fixed` 固定相对位姿，`continuous` 允许绕一根轴连续旋转，`revolute` 表示有角度范围的转动，`prismatic` 表示有行程范围的直线移动。后两类还需要位置上下限，限制字段的单位随关节类型变化。

URDF 规定关节允许怎样运动，当前角度或位移需要另外提供。给车轮填写 continuous，只完成了运动关系的描述，电机控制与状态测量还需要相应节点。

### 6 外观、碰撞和惯性分别怎样写

目前的小车模型主要用于理解外观和运动学。需要进行碰撞或动力学计算时，还会用到 `collision` 和 `inertial`。

`visual` 决定看到什么，`collision` 提供碰撞计算的几何体，`inertial` 提供质量、质心和转动惯量。它们可以采用不同的几何细节。例如车轮外观引用精细网格，碰撞体使用圆柱，以减少碰撞计算量。

下面是一个质量为 10 kg、尺寸为 0.6 × 0.4 × 0.2 m 的均匀长方体惯性片段。它用于解释字段，并采用质心位于 link 原点、惯性轴与长方体边平行的假设。

```xml
<inertial>
  <origin xyz="0 0 0" rpy="0 0 0"/>
  <mass value="10"/>
  <inertia ixx="0.166666667" ixy="0" ixz="0"
           iyy="0.333333333" iyz="0" izz="0.433333333"/>
</inertial>
```

`mass` 的单位为 kg，惯量单位为 kg·m²。惯量同时取决于质量分布和参考轴，实际模型应使用 CAD、测量结果或满足假设的几何公式。

几类 origin 的参考关系可以集中记住：visual、collision 和 inertial 内的 origin 都相对所属 link，joint origin 相对父 link，表示关节零位的安装关系。外观位置、质心位置与机械连接点可以各自选择，读取时需要分别确认。

### 7 URDF 连接树与名称

普通 URDF 的 link 和 joint 组成一棵树，每个非根 link 只有一个父关节，连接中没有闭环。我们的示例以 `base_link` 为根，雷达和四个车轮分别通过各自的 joint 连接到底盘。

link 名称需要唯一，joint 名称也需要唯一。joint 中引用的 parent 和 child 必须能在模型中找到。XML 标签正确闭合之后，还要继续检查这些引用和连接，才能确定机器人模型完整。

关节名称也会出现在状态消息和控制器配置中。例如模型使用 `left_front_wheel_joint`，发布关节位置的消息就需要使用同一名称。名称是不同程序对应同一个部件的重要依据。

### 8 xacro 怎样减少重复

把四个轮子的 XML 分别写一遍后，会发现尺寸和结构重复了很多次。xacro 为 XML 增加参数、表达式和宏，使重复部件可以统一定义，再按位置和名称实例化。

使用 xacro 时，robot 需要声明相应命名空间。下面是参数与宏调用的一个小片段。

```xml
<robot name="teaching_car"
       xmlns:xacro="http://www.ros.org/wiki/xacro">
  <xacro:property name="wheel_radius" value="0.1"/>
  <xacro:property name="half_track" value="0.24"/>

  <xacro:macro name="wheel" params="name x y">
    <link name="${name}">
      <visual>
        <geometry>
          <cylinder radius="${wheel_radius}" length="0.04"/>
        </geometry>
      </visual>
    </link>
    <joint name="${name}_joint" type="continuous">
      <parent link="base_link"/>
      <child link="${name}"/>
      <origin xyz="${x} ${y} -0.1" rpy="-1.57079632679 0 0"/>
      <axis xyz="0 0 1"/>
    </joint>
  </xacro:macro>

  <xacro:wheel name="left_front_wheel" x="0.2" y="${half_track}"/>
  <xacro:wheel name="right_front_wheel" x="0.2" y="${-half_track}"/>
</robot>
```

这个片段展示语法，使用时还要补上前面定义的 `base_link`。`property` 保存模型内部的数值，`${...}` 引用属性或计算表达式。`macro` 定义重复结构，调用时传入名称和位置，就会生成对应的 link 与 joint。

模型需要接收外部配置时，可以使用 `arg`，通过 `$(arg 参数名)` 读取。多个文件之间还可以用 `xacro:include` 组织定义。xacro 最终展开为普通 URDF，ROS 中使用模型的程序读取展开后的描述。

### 9 回到 SMB 的几个模型片段

现在再看前序作业的 SMB 文件，就可以直接识别其中的 link、joint、origin 和宏调用。它的底盘尺寸为 0.605 × 0.410 × 0.197 m，四个车轮通过 wheel 宏生成，前缀 LF、RF、LH、RH 分别表示左前、右前、左后、右后。[SMB 作业包](https://ethz.ch/content/dam/ethz/special-interest/mavt/robotics-n-intelligent-systems/rsl-dam/ROS2021/lec3/smb_common_v2.zip)

下面节选 wheel 宏中的连接字段，省略了动力学和控制相关内容。

```xml
<joint name="${prefix}_WHEEL_JOINT" type="${wheel_joint_type}">
  <parent link="${base_link_name}"/>
  <child link="${prefix}_WHEEL"/>
  <origin xyz="${X} ${Y} ${wheelHeight - chassisHeight/2.0}"
          rpy="-${0.5*PI} 0 0"/>
  <axis xyz="0 0 1"/>
</joint>
```

读这个片段时，先找父子 link，再看安装位姿，最后结合局部 axis 理解转轴方向。宏参数 `prefix` 同时参与 link 与 joint 命名，因此每次调用会生成不同的部件。

SMB 的非仿真分支还直接定义了 `base_to_rslidar`，其 origin 为 `xyz="0 0 0.31"`、`rpy="0 0 4.71238"`。仿真分支则调用外部 VLP-16 宏。实际使用时要确认分支、消息 frame_id 和展开结果，课堂小车的 `0.2 0 0.3` 参数单独用于本稿的推导。

### 10 模型怎样进入 ROS

URDF 或展开后的 xacro 通常通过 `robot_description` 提供给 ROS 节点。`robot_state_publisher` 读取模型，再结合 `JointState` 中的关节位置，计算各个 link 之间的坐标关系。固定连接使用 `/tf_static`，可动连接通过 `/tf` 更新。[robot_state_publisher 官方实现](https://github.com/ros/robot_state_publisher)

`JointState` 的 `name` 与 `position` 按项配对，时间戳说明状态属于哪个时刻。状态可以来自 GUI、编码器或仿真接口。RViz 的 RobotModel 使用模型外观与 TF 显示机器人。

到这里，我们已经能够读懂小车由哪些部件组成、部件怎样安装、哪些关节能够运动。这一讲先完成机器人描述的学习。接下来换一个问题：如果定位程序已经知道雷达在环境中的位姿，怎样利用刚才写出的安装关系，求出车体在环境中的位姿？

## 第二讲 从坐标变换理解 tf2 与三维姿态

### 1 小车、雷达与世界坐标系

第二讲先用俯视图讨论小车，暂时只考虑平面运动。定义世界坐标系 W、车体坐标系 B 和雷达坐标系 L。W 用于描述环境中的位置，B 固定在车体上，L 固定在雷达上。

在 ROS 中，B 可以取 `base_link`，L 可以取 `lidar_link`。本讲的 W 表示所选环境参考系，代码示例取 `map`。实际工程也可能在 `odom` 中做计算，使用时要服从定位系统的帧定义。

按照 ROS 常用机体约定，x 向前、y 向左、z 向上，坐标系采用右手系。沿正轴观察旋转方向时，要同时明确观察视角。对于正 z 朝上的平面小车，从上方看，正 yaw 表现为逆时针旋转。[REP 103](https://github.com/ros-infrastructure/rep/blob/master/rep-0103.rst)

一个点在雷达系中写成 `(1, 0)`，表示它位于雷达正 x 方向一米处。若雷达原点与底盘原点不同，或者雷达轴向与底盘轴向不同，这个点在车体系中的坐标就需要重新计算。

### 2 坐标变换先解决平移和旋转

先看只有平移的情况。若雷达在车体前方 0.2 m，雷达与车体同向，那么雷达系中的点 `(1, 0)` 在车体系中就是 `(1.2, 0)`。这个结果同时包含雷达前方的一米距离和雷达自身的安装偏移。

再增加旋转。如果雷达的正 x 轴指向车体正 y，那么雷达前方一米换到车体系中，就沿车体正 y 方向。加上车体正 x 方向 0.2 m 的安装偏移后，结果成为 `(0.2, 1)`。

把这两步合在一起，点坐标满足：

$$
{}^B\boldsymbol p={}^BR_L\,{}^L\boldsymbol p+{}^B\boldsymbol t_L
$$

左上标说明数值在哪个坐标系中表达。旋转矩阵 `R` 把雷达的轴向换成车体的轴向，平移 `t` 表示雷达原点在车体系中的位置。同一个物理点保持原位，我们改变了描述它的参考系。

### 3 已知雷达位姿，为什么能够求车体位姿

现在把注意力从一个目标点转到整台小车。假设激光定位程序通过扫描匹配，已经估计出雷达在世界系中的位置和朝向。雷达又刚性安装在车体上，装配关系已经通过模型或标定给出。两份信息结合后，就可以恢复车体在世界系中的位姿。

这里需要完整的雷达位姿。只给出雷达原点的世界坐标时，朝向仍然未知，车体可能以不同方向绕这个安装点摆放。加入雷达朝向和已知装配关系后，刚性连接的车体坐标系才能确定。

为统一记录平移和旋转，用 `T` 表示刚体变换。约定 ${}^AT_B$ 表示 B 坐标系在 A 中的位姿，同时把 B 中的点坐标转换到 A。这个约定会一直用于后面的公式和代码。

我们已知的安装关系是 ${}^BT_L$，已知的定位结果是 ${}^WT_L$，要求的车体位姿是 ${}^WT_B$。三者满足：

$$
{}^WT_L={}^WT_B\,{}^BT_L
$$

这个等式表示，先按雷达到车体的关系换算，再按车体到世界的关系换算，可以得到雷达到世界的完整关系。将安装关系求逆，就得到本讲的核心计算：

$$
\boxed{{}^WT_B={}^WT_L\,({}^BT_L)^{-1}}
$$

这里的逆变换把装配关系反向使用。右侧先作用，两个相邻变换中间的参考系需要对应。求出车体位姿后，还可以代回前一个等式，检查能否恢复原来的雷达位姿。

### 4 一个转过九十度的小车例子

回到第一讲的教学小车。雷达在车体前方 0.2 m、上方 0.3 m，雷达轴向与车体一致。先只看俯视图，平面安装参数为位置 `(0.2, 0)`、角度 `0`。

设定位程序给出雷达的世界坐标为 `(5, 3)` m，雷达正 x 相对世界正 x 旋转了 90°。因为安装轴向一致，车体也朝向世界正 y。车体到雷达的前向 0.2 m，此时在世界系中沿正 y。

因此，车体原点在世界系中的位置为：

$$
\boldsymbol p^W_B
=\begin{bmatrix}5\\3\end{bmatrix}
-R_z(\pi/2)\begin{bmatrix}0.2\\0\end{bmatrix}
=\begin{bmatrix}5\\2.8\end{bmatrix}
$$

结果是车体位于 `(5, 2.8)` m，yaw 为 90°。减去的安装偏移需要先转到世界轴向，因此这次变化落在 y 分量上。若继续沿世界 x 减去 0.2 m，就会把车体系的安装方向和世界系混在一起。

再考虑雷达安装时额外转了 90°，即雷达正 x 指向车体正 y，而安装位置仍为车体前方 0.2 m。对于相同的雷达世界位姿，车体 yaw 就是 0°，车体位置为 `(4.8, 3)` m。这个比较说明，安装朝向会同时参与车体朝向和位置的计算。

这两个结果都只讨论平面分量。沿用完整三维安装高度、并假定其余角度为零时，还需要按同一关系处理 z。例如雷达高度为 0.3 m，车体参考原点的高度就为 0。

> 配图建议：在同一俯视图中画出 W、B、L 三组坐标轴，标出雷达定位结果和车体到雷达的 0.2 m 偏移。第二张图只改变安装朝向，让学生比较恢复的车体位姿。

### 5 tf2 在这个问题中承担什么工作

激光定位算法根据测量与地图估计雷达位姿，URDF 或标定提供装配关系，tf2 管理和使用这些已知变换。变换的组合、求逆、缓存与按时间查询，都可以通过 tf2 相关接口完成。

tf2 收到的是带帧名和时间戳的坐标关系。它可以沿连通路径取得两个参考系之间的变换，也可以把关系反向使用。名称本身不包含安装尺寸，程序需要先有模型、标定或定位计算提供数值。

数学上列出多份已知关系，用于推导和核对。发布到 TF 时，还要让每个子帧保持明确的父帧和发布来源。这个定位例子可以采用下面的分工：

| 关系或数据 | 来源与用途 |
| --- | --- |
| 雷达在世界系中的位姿消息 | 定位程序提供，作为车体位姿换算的输入 |
| `base_link` 到 `lidar_link` | robot_state_publisher 根据固定 joint 提供 |
| 世界系到 `base_link` | 换算节点输出，交给 TF 或其他应用使用 |

这样，雷达定位结果先作为输入消息使用，TF 中保留世界系、车体和雷达的连通关系。如果实际系统已经通过 `map`、`odom` 和 `base_link` 建立定位链，就沿该系统的分工接入，避免让同一子帧同时出现冲突的父关系。

### 6 从平面例子扩展到六个自由度

刚才的俯视图只用了 x、y 和 yaw。小车经过斜坡时，还会出现高度变化、俯仰和滚转。雷达自身也可能带有倾斜安装角，平面描述就需要扩展到三维。

自由刚体在三维空间中有六个自由度：沿三个方向的平移，以及三个独立的旋转变化。位置常用 x、y、z 表达，姿态可以用 roll、pitch、yaw 表达，合起来构成位姿。

从平面运动扩展时，可以先观察车体的三种姿态变化：转弯时改变偏航，经过坡面时出现俯仰，侧倾时出现滚转。下一节再给这三种变化配上轴名和明确的旋转顺序。

自由度描述允许独立变化的数量。三维位姿使用完整的平移和旋转表示，具体机构仍然受到约束。例如固定安装的雷达相对于车体没有可动自由度，单个车轮关节则主要允许绕轮轴转动。

### 7 欧拉角先规定绕什么轴、按什么顺序转动

前面用一个 yaw 表达平面小车的朝向。进入三维后，可以用三个按约定顺序排列的旋转角表达姿态，这类表示称为欧拉角。本课使用的 roll、pitch、yaw 属于其中一种常见约定，简称 RPY。

先明确坐标系。世界系 W 用作外部参考，车体系 B 随小车一起移动和转动。平移决定两个原点的相对位置，旋转决定两组坐标轴的相对方向。两个原点可以重合，轴向仍然不同，因此位置和姿态需要分别描述。

ROS 常用右手系。右手拇指指向坐标轴正方向，其余手指弯曲的方向表示正旋转。本课保持 x 向前、y 向左、z 向上的约定，RPY 的轴名对应关系为：

| 参数 | 中文名称 | 对应轴 |
| --- | --- | --- |
| roll，记为 φ | 滚转 | x |
| pitch，记为 θ | 俯仰 | y |
| yaw，记为 ψ | 偏航 | z |

接着确定旋转顺序。本课采用固定轴 XYZ 约定，依次绕参考系固定的 x、y、z 轴转动。用列向量计算时，矩阵从右向左作用：

$$
R(\phi,\theta,\psi)=R_z(\psi)R_y(\theta)R_x(\phi)
$$

例如先绕固定 x 转过 φ，物体的轴向已经改变，但下一次仍绕参考系固定的 y 轴转过 θ。最后再绕固定 z 轴转过 ψ，就得到最终姿态。URDF 的 `origin rpy` 和 tf2 的 `setRPY(roll, pitch, yaw)` 都按相应的固定轴 RPY 约定解释。[ROS Noetic 的 Quaternion 实现](https://github.com/ros/geometry2/blob/noetic-devel/tf2/include/tf2/LinearMath/Quaternion.h)

也可以使用随体轴描述同一个结果：先绕自身 z 轴转 ψ，再绕更新后的自身 y 轴转 θ，最后绕更新后的自身 x 轴转 φ。固定轴 XYZ 与随体轴 ZYX 在这组角度对应下得到相同旋转。阅读其他教程或动画时，需要同时核对参考轴、顺序和角度名称。

旋转顺序会影响结果。取一根初始指向正 y 的方向，先绕固定 x 转 90°，它变为正 z，再绕固定 z 转 90°仍为正 z。交换两步后，它先变为负 x，再绕固定 x 转动仍为负 x。两个结果不同，因此三个角度需要配合顺序才能表达完整含义。

这一组角度描述最终姿态，物体在现实中可以沿其他路径到达相同姿态。接下来讨论的万向节锁，也要从参数怎样表示最终姿态来理解。

### 8 万向节锁发生在姿态参数的表达中

普通位置下，小幅调整 roll、pitch、yaw，可以产生三个独立的局部姿态变化。但是在上述约定中，当 pitch 等于正或负 90°时，roll 与 yaw 的作用出现相关，两者无法继续作为独立的局部姿态参数使用。这就是欧拉角表示的万向节锁。

先看数学上发生了什么。将 pitch 固定为 90°，原来的三个角就满足：

$$
R_z(\psi)R_y(\pi/2)R_x(\phi)
=R_y(\pi/2)R_x(\phi-\psi)
$$

右侧只依赖 roll 与 yaw 的差。如果给两者同时增加相同角度，这个差保持不变，最终姿态也保持不变。具体来说，下面两组角度得到相同旋转：

$$
(\phi,\theta,\psi)=(0,\pi/2,0)
\quad\text{与}\quad
(\pi/6,\pi/2,\pi/6)
$$

因此，给出某个姿态后，无法在这个位置唯一地分别确定 roll 与 yaw。接近这个姿态时，物体的运动可能很平滑，反解出的角度却可能变化很大。直接对欧拉角分量做插值、差分或误差计算时，就需要关注这类情况。

万向架动画能帮助理解参数作用为什么会重合。三层环分别控制一项旋转，中间环转到特殊位置后，内外两项旋转沿同一轴线作用。两个控制量的效果出现重复，三个角对局部姿态变化的描述能力随之降低。

这里需要区分两组轴。车体坐标系自身的 x、y、z 三根轴始终互相垂直。动画中讨论的重合，涉及各层转动轴，数学上对应各角参数在当前姿态附近引起的瞬时旋转方向。自由刚体仍然能够在三维空间中改变姿态，这套欧拉角参数在特殊位置失去了独立性。

> 演示顺序：打开 [Gimbal Lock Demonstration](https://dmccreary.github.io/linear-algebra/sims/gimbal-lock-demo/)或[全屏演示](https://dmccreary.github.io/linear-algebra/sims/gimbal-lock-demo/main.html)，先观察一般位置下的三层环，再把 pitch 调到 90°，分别改变 yaw 和 roll，观察两者的转轴关系。随后回到上面的“只依赖角度差”公式，比较两组等价角度。
>
> 视频补充为 GuerrillaCG 的 [Euler (gimbal lock) Explained](https://www.youtube.com/watch?v=zc8b2Jo7mno)。素材采用的轴名和旋转顺序按其说明读取。本课严格奇异点为 pitch 等于正或负 90°，接近时的预警与严格奇异点分别理解。

机械万向架还受到实际转轴和限位约束。我们接下来引入四元数，关注计算中怎样表示和组合旋转，使姿态可以平滑经过这些欧拉角的特殊位置。

### 9 先用复数理解平面旋转

在给出四元数公式前，先回到熟悉的二维平面。平面中的向量 `(a, b)` 可以写成复数：

$$
z=a+bi,\qquad i^2=-1
$$

乘以 i 后，有：

$$
iz=i(a+bi)=-b+ai
$$

坐标从 `(a, b)` 变成 `(-b, a)`，恰好对应平面内逆时针转过 90°。例如正 x 方向的 `(1, 0)`，乘以 i 后得到正 y 方向的 `(0, 1)`。

若要旋转任意角度 α，可以乘以长度为一的复数：

$$
r_\alpha=\cos\alpha+i\sin\alpha
$$

展开乘法，结果为：

$$
r_\alpha z
=(a\cos\alpha-b\sin\alpha)
+i(a\sin\alpha+b\cos\alpha)
$$

两个分量与平面旋转矩阵的结果一致。由此可以看到，乘法本身能够实现旋转，复数的实部和虚部共同记录这次旋转。

三维旋转还要指定绕哪根轴转动。接下来先用轴与角描述旋转，再学习四元数怎样同时记录它们。

### 10 轴角描述三维旋转

只考虑绕固定参考点的姿态变化时，任意三维旋转都可以表示为绕某一根轴转过一定角度。用单位向量 `u` 指定轴的方向，用 α 指定转角，就得到轴角表示。

例如小车原地向左转 90°，旋转轴沿正 z，取 `u=(0, 0, 1)`，转角为 `α=π/2`。若小车沿某条倾斜轴改变姿态，u 就需要同时包含几个方向的分量。u 的长度取一，因为这里关心的是轴的方向。

观察一个随车体一起转动的方向向量，可以把它分为平行于 u 和垂直于 u 的两部分。平行分量保持不变，垂直分量在对应平面内转动。这个分解把三维旋转与上一节的平面旋转联系起来。

轴角仍然需要处理自身的特殊情况。例如零角度对应恒等旋转，此时轴方向可以任意选取。我们用它建立几何理解，再把旋转写成方便组合和计算的单位四元数。

### 11 四元数的四个分量分别表示什么

四元数由四个实数分量构成，可以写成：

$$
q=w+xi+yj+zk
$$

w 是标量部分，`(x, y, z)` 是向量部分。i、j、k 是满足特定乘法规则的代数单位，例如 `i²=j²=k²=-1`、`ij=k`、`ji=-k`。这些规则使四元数乘法一般不能交换顺序。

用单位四元数表示绕单位轴 u 转过 α 时，各分量取为：

$$
q=\cos\frac{\alpha}{2}
+\left(u_xi+u_yj+u_zk\right)\sin\frac{\alpha}{2}
$$

也就是：

$$
w=\cos\frac{\alpha}{2},\qquad
(x,y,z)=\boldsymbol u\sin\frac{\alpha}{2}
$$

向量部分记录旋转轴方向并带有角度信息，标量部分也参与角度表示。此处的 x、y、z 都属于旋转参数，与位置向量的分量分别存储。表示完整位姿时，仍然需要额外保存平移。

由于 u 是单位向量，这四项满足：

$$
w^2+x^2+y^2+z^2=1
$$

四个分量带有一个单位长度约束，仍然描述三个旋转自由度。ROS 消息按 x、y、z、w 保存分量，所以数学表达中写在前面的 w，在 ROS 的常用分量排列中位于最后。接下来解释公式里的半角。

### 12 半角与四元数旋转公式

要让四元数作用于三维向量，先将向量 `v=(v_x,v_y,v_z)` 写成标量部分为零的纯四元数：

$$
p=v_xi+v_yj+v_zk
$$

用单位四元数 q 旋转这个向量，计算规则为：

$$
p'=q\,p\,q^{-1}
$$

结果的标量部分仍为零，向量部分就是旋转后的方向。对于单位四元数，逆等于共轭，即 `q⁻¹=w−xi−yj−zk`。这里的左右两次相乘共同完成旋转，乘法顺序需要保持一致。[tf2 的 quatRotate 实现](https://github.com/ros/geometry2/blob/noetic-devel/tf2/include/tf2/LinearMath/Quaternion.h)

先看绕正 z 轴的例子。假设构造 `q=cos β+k sin β`，让它作用于正 x 单位方向 `p=i`，展开后得到：

$$
qiq^{-1}
=(\cos^2\beta-\sin^2\beta)i
+2\sin\beta\cos\beta\,j
=\cos(2\beta)i+\sin(2\beta)j
$$

可见向量实际转过的角度是 2β。希望物理旋转角为 α 时，就应取 `β=α/2`。对任意单位轴也采用相应的半角构造，这样便得到上一节的四元数公式。

例如绕正 z 轴转 90°，按 ROS 的分量顺序有：

$$
q=(x,y,z,w)=\left(0,0,\frac{\sqrt2}{2},\frac{\sqrt2}{2}\right)
$$

它将方向 `(1, 0, 0)` 变为 `(0, 1, 0)`，与平面小车向左转 90°的结果一致。绕其他轴旋转时，同一条 `p'=qpq⁻¹` 规则依然适用。

### 13 四元数怎样处理欧拉角的特殊姿态

欧拉角通过三次有顺序的轴旋转描述姿态。单位四元数直接保存整体旋转的参数，能够连续表示经过 pitch 为 90°附近的姿态变化，计算过程可以避免欧拉角在该处的参数退化。

如果把四元数重新转换成 RPY 显示，角度提取仍然面对同一套欧拉角的特殊位置。因此，程序可以使用四元数或旋转矩阵进行旋转组合，再按需要转换成便于人阅读的角度。

同一个旋转还对应 q 和 −q 两个单位四元数，因为：

$$
(-q)p(-q)^{-1}=qpq^{-1}
$$

所以比较旋转时，四个分量同时变号也可能表示相同姿态。插值和连续记录还需要关注这种等价性，采用合适的符号选择和旋转插值方法。

恒等旋转按 ROS 顺序写成 `(0, 0, 0, 1)`。全零四元数不能表示旋转，归一化也无法修复全零输入。数值计算中需要保证输入有效并保持单位长度，机械转轴的限位则继续由实际机构与控制处理。

### 14 在 ROS 中构造和传递四元数

`tf2::Quaternion` 用于旋转计算，`geometry_msgs::Quaternion` 用于消息传递。需要构造一个绕正 z 转 90°的姿态时，可以直接按轴角输入：

```cpp
constexpr double pi = 3.14159265358979323846;

tf2::Quaternion q;
q.setRotation(tf2::Vector3(0.0, 0.0, 1.0), pi / 2.0);
q.normalize();

geometry_msgs::Quaternion rotation = tf2::toMsg(q);
```

这里的 `setRotation` 接收旋转轴和物理转角，内部完成半角计算。若模型参数已经写成 RPY，也可以用 `q.setRPY(roll, pitch, yaw)` 构造同一个旋转。传入的角度都采用弧度，π rad 等于 180°。

四元数乘法用于组合旋转。在本稿的约定下，已知雷达世界姿态与安装姿态时，车体姿态满足 `q_W_B=q_W_L*q_B_L.inverse()`。完整定位例子还包含安装偏移，因此下一节将旋转与平移合在 Transform 中处理。

至此，RPY 的三个角、轴角的单位方向与转角、四元数的四个分量，都可以用来表达同一份旋转关系。它们的存储方式和计算规则各自明确，接入 tf2 时再按消息和接口要求转换。

### 15 三维变换的组合与求逆

现在可以用完整三维形式重新阅读前面的定位公式。刚体变换由旋转 `R` 和平移 `t` 构成，用齐次矩阵统一记录为：

$$
{}^AT_B=
\begin{bmatrix}
{}^AR_B & {}^A\boldsymbol t_B\\
0 & 1
\end{bmatrix}
$$

右上角的平移表示 B 原点在 A 中的位置，左上角的旋转表示 B 的轴向相对于 A 的方向。把点坐标扩展为 `(x, y, z, 1)` 后，就可以用这一个矩阵完成旋转和平移。

变换沿参考系连接进行组合，反向使用时需要求逆：

$$
{}^AT_C={}^AT_B\,{}^BT_C,
\qquad
({}^AT_B)^{-1}=
\begin{bmatrix}
R^T & -R^T\boldsymbol t\\
0 & 1
\end{bmatrix}
$$

逆旋转为转置 `Rᵀ`，逆变换的平移为 `−Rᵀt`。这解释了前面数值例子中为什么要先处理安装偏移的方向，再计算车体世界位置。[Noetic Transform 实现](https://github.com/ros/geometry2/blob/noetic-devel/tf2/include/tf2/LinearMath/Transform.h)

雷达安装存在滚转、俯仰或偏航时，仍然使用同一个关系 ${}^WT_B={}^WT_L({}^BT_L)^{-1}$。区别在于平面旋转扩展为完整三维旋转，位置也增加 z 分量。

### 16 用 tf2 恢复车体在世界系中的位姿

在 ROS 中，`geometry_msgs::PoseStamped` 用于携带位置、四元数姿态、参考系和时间戳。假设 `lidar_pose` 表示雷达在 `map` 中的完整位姿，Buffer 已经持续接收模型发布的安装变换，就可以按下面的核心步骤换算。

```cpp
auto mount = buffer.lookupTransform(
    "base_link", "lidar_link",
    lidar_pose.header.stamp, ros::Duration(0.1));

tf2::Transform T_W_L;
tf2::Transform T_B_L;
tf2::fromMsg(lidar_pose.pose, T_W_L);
tf2::fromMsg(mount.transform, T_B_L);

const tf2::Transform T_W_B = T_W_L * T_B_L.inverse();

geometry_msgs::PoseStamped base_pose;
base_pose.header = lidar_pose.header;
base_pose.pose.position.x = T_W_B.getOrigin().x();
base_pose.pose.position.y = T_W_B.getOrigin().y();
base_pose.pose.position.z = T_W_B.getOrigin().z();
base_pose.pose.orientation = tf2::toMsg(T_W_B.getRotation());
```

这里的 `lookupTransform(target, source, time, timeout)` 取 `base_link` 为 target、`lidar_link` 为 source，因此得到 ${}^BT_L$。随后显式求逆并组合，得到车体在世界系中的位姿。输出沿用输入的参考系和采集时间。[Buffer 查询接口](https://github.com/ros/geometry2/blob/noetic-devel/tf2_ros/include/tf2_ros/buffer.h)

这个片段放在节点已有的处理函数中使用，需要包含 tf2、tf2_ros 和 tf2_geometry_msgs 对应头文件。输入雷达位姿应明确描述雷达帧，四元数需要有效。Buffer 与 Listener 随节点持续存活，查询异常由调用处处理，查询失败时应跳过这次换算。

输出消息表示车体位姿。系统若需要把它加入 TF，可按已有发布分工填写 `header.frame_id` 为世界参考系、`child_frame_id` 为 `base_link`，再通过 broadcaster 发布。仅在消息上更改 frame_id，坐标数值不会自动完成换算。

### 17 同一套关系还能转换雷达目标点

车体位姿求出后，模型与定位关系就能连成从雷达到世界系的路径。此时还可以处理前序作业中的目标点：目标点原本属于雷达帧，程序可将它表达在车体系或世界系中。

点与位姿的物理含义需要分别确认。`PointStamped` 描述一个点，转换时需要旋转和平移。`PoseStamped` 还包括物体朝向。`Vector3Stamped` 常用于方向等按向量规律变换的量，其坐标换轴只使用旋转。

如果 `point_in_lidar` 是雷达帧中的点，程序要得到它在 `map` 中的坐标，就查询 target 为 `map`、source 为 `lidar_link` 的变换，再应用到这个点。

```cpp
auto transform = buffer.lookupTransform(
    "map", "lidar_link",
    point_in_lidar.header.stamp, ros::Duration(0.1));

geometry_msgs::PointStamped point_in_map;
tf2::doTransform(point_in_lidar, point_in_map, transform);
```

这里输入数据是点，前面定位例子的输入数据是雷达坐标系的完整位姿。两个任务使用同一套变换运算，所求对象与输入信息各自明确。[tf2_geometry_msgs 转换实现](https://github.com/ros/geometry2/blob/noetic-devel/tf2_geometry_msgs/include/tf2_geometry_msgs/tf2_geometry_msgs.h)

### 18 时间、查询与数据来源

位姿属于具体时刻。雷达在 t 时刻测量，定位和控制在稍后处理，换算时仍应保留 t。车体若以 1 m/s 行驶，处理延迟 0.1 s，期间就会移动约 0.1 m，混用时刻会把这段运动带入结果。

固定安装关系不随时间改变，雷达在世界系中的位姿则会随车体运动变化。`ros::Time(0)` 请求路径上最新共同可用的变换，`ros::Time::now()` 表示当前 ROS 时间。传感器数据通常按自身时间戳选择所需关系。

仿真使用 `use_sim_time` 时，消息与 TF 应采用一致的 ROS 时间来源。帧名错误、路径不连通、请求时刻超出缓存，都可能导致查询失败。timeout 给数据到达预留等待时间，缺失的安装关系或已经过期的历史还需要从对应来源处理。

最后回到完整的小车案例：URDF 描述零件与安装，关节状态补充可动部件状态，定位算法估计雷达或车体在环境中的位姿，tf2 按参考系和时间组织这些结果。先明确已知数据、所求对象与变换方向，再选择合适的消息和接口，公式与程序就能相互核对。

## 资料与教学素材

### 模型与 ROS 接口

1. [ROS 官方 URDF 教学工程](https://github.com/ros/urdf_tutorial/tree/ros1)：从基础几何、连接与可动关节学习 URDF，ROS 1 示例使用 ros1 分支。
2. [ETH Zürich ROS Course 2021 SMB 作业包](https://ethz.ch/content/dam/ethz/special-interest/mavt/robotics-n-intelligent-systems/rsl-dam/ROS2021/lec3/smb_common_v2.zip)：本稿 SMB 文件名、部件名和安装参数的来源。
3. [REP 103](https://github.com/ros-infrastructure/rep/blob/master/rep-0103.rst)：单位、右手系和机体轴向约定。
4. [Noetic geometry2 源码](https://github.com/ros/geometry2/tree/noetic-devel)：Transform、Quaternion、Buffer 与消息转换接口。
5. [robot_state_publisher 官方工程](https://github.com/ros/robot_state_publisher)：模型、关节状态与 TF 发布的职责。

### 参考文章与旋转约定

本稿参考 HighDefinition 的[《3D数学：欧拉角、万向锁、四元数》](https://www.cnblogs.com/HDDDDDD/p/15067619.html)，采用从欧拉角问题、复数平面旋转到三维旋转的递进方式。正文按 ROS 的右手系、固定轴 RPY 和列向量计算统一符号。

阅读参考文章时，需要留意其中部分段落的角名与公式变量对应不一致。本课始终使用 roll 绕 x、pitch 绕 y、yaw 绕 z，矩阵为 `Rz(yaw)Ry(pitch)Rx(roll)`。四元数使用四个实分量，并在表示旋转时满足单位长度约束。

推导补充可阅读 [Krasjet 的四元数教程](https://github.com/Krasjet/quaternion)与[万向节锁附篇](https://krasjet.github.io/quaternion/bonus_gimbal_lock.pdf)。固定轴与随体轴的描述需要与所选矩阵约定一起核对。

### 万向节锁视频与图示

1. [GuerrillaCG：Euler (gimbal lock) Explained](https://www.youtube.com/watch?v=zc8b2Jo7mno)：欧拉旋转与旋转顺序的视频补充，放在 RPY 之后使用。
2. [Dan McCreary：Gimbal Lock Demonstration](https://dmccreary.github.io/linear-algebra/sims/gimbal-lock-demo/)与[全屏演示](https://dmccreary.github.io/linear-algebra/sims/gimbal-lock-demo/main.html)：通过三层环观察中间角达到 90° 时的轴重合。
3. [pytransform3d：Euler Angles](https://dfki-ric.github.io/pytransform3d/user_guide/euler_angles.html)：固定轴 XYZ、RPY 与欧拉角奇异性的说明。
4. [UC Davis：Oliver Kreylos 的姿态表示说明](https://web.cs.ucdavis.edu/~okreylos/ResDev/Wiimote/Technology.html)：单位四元数、单位长度约束及同一朝向的两种等价表示。

## 补充推导 轴角与罗德里格公式

这部分用于已经熟悉点积、叉积的同学继续理解轴角旋转。设 u 为单位旋转轴，将向量 v 分解为平行与垂直于 u 的两部分：

$$
\boldsymbol v_\parallel=(\boldsymbol u\cdot\boldsymbol v)\boldsymbol u,
\qquad
\boldsymbol v_\perp=\boldsymbol v-\boldsymbol v_\parallel
$$

平行分量保持不变，垂直分量在平面内转过 α，所以有：

$$
\boldsymbol v'
=\boldsymbol v_\parallel
+\cos\alpha\,\boldsymbol v_\perp
+\sin\alpha\,(\boldsymbol u\times\boldsymbol v_\perp)
$$

代入前面的分解，并利用 u 与自身平行分量的叉积为零，可以整理为：

$$
\boldsymbol v'
=\cos\alpha\,\boldsymbol v
+(1-\cos\alpha)(\boldsymbol u\cdot\boldsymbol v)\boldsymbol u
+\sin\alpha\,(\boldsymbol u\times\boldsymbol v)
$$

这就是罗德里格旋转公式。将正文中的单位四元数代入 `p'=qpq⁻¹` 并展开，也会得到相同的三维向量结果。两种写法表达同一份轴角旋转，正文优先使用简单数值例子建立理解。
