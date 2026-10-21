# RoboMaster 新生课可用的 Agent Skills 实践

检索日期：2026-10-21

## 结论

首课建议用三个实践串起「学习、查资料、动手验证」：Matt Pocock 的 `teach` 展示如何让学习任务跨会话延续；Upstash Context7 CLI 展示如何让 Agent 查当前库文档；OpenAI 的 `jupyter-notebook` 展示如何把代码练习做成可运行的实验或教程。若课程会延伸到 STM32 固件测试，可把 Firmware Forge 的 `embedded-test-engineer` 留作进阶例子。

这几项有作者原始 `SKILL.md` 或实现文档可查。它们能证明作者写了哪些流程、文件和工具，不能单独证明模型因此一定更聪明或完成率更高。本次没有安装、调用或运行任何外部项目，也没有找到这些实践之间的独立对照评测。

## 首课推荐

### 1. Matt Pocock 的 `teach`

来源：作者的 [`teach/SKILL.md`](https://github.com/mattpocock/skills/blob/main/skills/productivity/teach/SKILL.md) 和[使用说明](https://github.com/mattpocock/skills/blob/main/docs/productivity/teach.md)。

具体能力：把学习组织成一个有状态的工作目录，包含学习目标 `MISSION.md`、来源清单 `RESOURCES.md`、单页 HTML 课程、速查资料、学习记录和可复用组件。技能说明要求课程围绕一个可达成的学习目标，引用高可信资料，并用回忆练习、间隔复习和交错练习帮助学生巩固。

课堂演示：给出一段带数组边界问题的 C 代码，先说明学生已经掌握的知识，再让 Agent 为「读懂循环边界并能自己修复」生成一节短课。学生完成小测后，下一次会话在同一目录继续课程。课程中的 C 代码应能编译或通过小测试，讲义链接应打开到原始资料。

依赖与兼容性：作者文档采用 `/teach` 命令和工作目录约定。该仓库的 frontmatter 含 `disable-model-invocation` 字段。OpenCode 或其他 DeepSeek 接入 harness 是否能识别该字段和命令，需在课程所用宿主上先验证。技能本身会生成 HTML 和若干 Markdown 文件。

证据级别：作者原始技能与作者维护的使用说明已阅读。使用说明公开记录了具体局限：第一次对话缺少已有学习记录，可能高估学生起点；作者报告测验正确答案出现位置偏向 A；技能不会自动安排复习时间，也不能稳定判断何时结束。上述属于作者维护记录与用户案例，未由本次独立复现，也不构成对照评测。

首课适配度：高。它贴近「AI 如何辅助学习」主题，且能形成可带走的课程材料。教师需要先给出学生已有知识、目标和一手资料，并亲自检查测验选项与答案。

### 2. Upstash Context7 CLI 的 `context7-cli`

来源：Upstash 的 [`context7-cli/SKILL.md`](https://github.com/upstash/context7/blob/master/skills/context7-cli/SKILL.md)、[CLI 文档](https://github.com/upstash/context7/blob/master/docs/clients/cli.mdx)和[CLI 实现入口](https://github.com/upstash/context7/blob/master/packages/cli/src/index.ts)。

具体能力：按两步查库文档。先用 `ctx7 library` 把库名解析成 Context7 的库 ID 和版本，再把该 ID 交给 `ctx7 docs` 查询 API 用法和示例。官方文档还说明了 CLI 加 skill 与 MCP 两种接入方式。CLI 加 skill 可用于 OpenCode，技能会引导 Agent 在需要时调用命令，不要求 MCP 客户端。

课堂演示：让学生问一个容易因版本不同而出错的 API 问题，例如「CMake 中为可执行目标链接库的当前写法是什么」。先看模型直接回答，再让它通过 Context7 查资料，核对库 ID、版本和原始文档链接。CMake、ROS、STM32 HAL 等条目是否已被当前索引收录，本次没有逐一验证，课堂前应实际查询，必要时换成已能解析的库。

依赖与兼容性：官方 CLI 文档要求 Node.js 22.13 或更新版本。基础文档查询通常无需登录，登录会提高请求限额；执行 `ctx7 setup` 需要登录或传入 API Key。官方文档列出 `ctx7 setup --cli --opencode`。使用在线索引需要网络连接。文档还说明 CLI 会收集匿名使用数据，并提供关闭选项。

证据级别：已阅读作者技能、官方 CLI 文档和命令注册入口。公开实现与文档能证明其查询步骤、接入方式和前置条件。本次没有实际请求文档服务，也没有比较它对代码正确率的提升。

首课适配度：高。它可以展示一个技能如何把模型引向可核对的资料来源。演示时应把回答与文档版本、链接、代码示例一起检查，索引暂未覆盖的库要明确标出。

### 3. OpenAI 的 `jupyter-notebook`

来源：OpenAI [`jupyter-notebook/SKILL.md`](https://github.com/openai/skills/blob/main/skills/.curated/jupyter-notebook/SKILL.md)、[教程模板说明](https://github.com/openai/skills/blob/main/skills/.curated/jupyter-notebook/references/tutorial-patterns.md)、[质量检查表](https://github.com/openai/skills/blob/main/skills/.curated/jupyter-notebook/references/quality-checklist.md)和[模板生成脚本](https://github.com/openai/skills/blob/main/skills/.curated/jupyter-notebook/scripts/new_notebook.py)。

具体能力：先区分教程与实验，再用随附模板和 Python 脚本生成 `.ipynb`。技能要求代码按小步组织，说明预期结果，并在环境允许时从头到尾执行 Notebook。脚本读取模板、更新标题、生成文件；目标文件已存在时会拒绝覆盖，除非明确传入 `--force`。

课堂演示：让 Agent 生成一个电机编码器数据小实验，分单元展示原始信号、滑动平均滤波和误差曲线。学生调整窗口大小，重跑所有单元，观察延迟与平滑效果的变化。评价点是输出是否来自已执行单元，参数是否显式记录，Notebook 能否从头运行。

依赖与兼容性：此技能原生面向 Codex，示例路径使用 `$CODEX_HOME/skills`，模板脚本示例要求 `uv` 与 Python 3.12。Notebook 运行需要 Jupyter kernel 和相关 Python 包。用于 OpenCode 等其他宿主前，需确认技能目录扫描规则，并按实际安装位置调整脚本路径；原文没有声称对所有宿主都完成适配。

证据级别：已阅读技能、模板说明、检查表和模板生成脚本。来源证实了脚手架与检查流程，未提供模型学习效果的对照数据。本次没有运行该脚本或生成 Notebook。

首课适配度：高，适合展示「要求模型生成可运行的学习材料，再亲自改参数验证」。它以 Python 实验为主，对 C/C++ 固件语法的直接帮助有限。

## RoboMaster 固件进阶候选

### Firmware Forge 的 `embedded-test-engineer`

来源：[项目首页](https://github.com/Fz2hOpenSource/firmware-forge)、作者的 [`embedded-test-engineer/SKILL.md`](https://github.com/Fz2hOpenSource/firmware-forge/blob/main/embedded-test-engineer/SKILL.md)、[项目使用说明](https://github.com/Fz2hOpenSource/firmware-forge/blob/main/docs/workbench-usage.md)和[设计理念](https://github.com/Fz2hOpenSource/firmware-forge/blob/main/docs/design-philosophy.md)。

具体能力：针对 Cortex-M 与 STM32 项目，讨论主机单元测试、HAL 测试接缝、stub/fake/mock 选择、采样数据回放、误差容限、时序测试和 HIL 覆盖。技能明确区分 PC 单元测试、驱动测试、仿真和硬件测试能提供的证据，也给出状态图检查脚本的输入格式与限制。

课堂演示：提供一个传感器原始计数到工程单位的纯 C 函数和少量记录样本，让 Agent 设计主机测试，覆盖正常值、上下限和异常值。学生检查每条测试保护了什么行为，再讨论这些测试没有验证的硬件时序与传感器精度。

依赖与兼容性：项目当前支持 Codex 与 DSH。作者说明运行离线 Python 工具需要 Python 3.10 以上；技能的主机测试设计可以不连接设备，实际 HIL 仍需目标硬件和既有测试环境。OpenCode 兼容性未由项目文档确认。

证据级别：已阅读原始技能、项目首页和作者维护文档。文档中列出专门的测试技能和检查工具，也列有行为场景、技术审查记录。本次未运行工具或核验作者记录中的命令输出，没有独立的模型效果评测。

首课适配度：中。它与 RoboMaster 固件开发最接近，测试证据分层值得讲；不过涉及 HAL、回放、误差容限等前置概念，建议放在新生已能编译简单 C 程序之后。

## 推荐顺序与选用判断

1. 讲「学习」时先演示 `teach`，但首条任务里明确学生基础，并核验题目答案。
2. 讲「代码资料核对」时用 Context7 CLI。它对 OpenCode 的 CLI 加 skill 接入有官方说明，适合接在模型调用与工具使用之后。
3. 讲「把学习结果变成程序」时用 `jupyter-notebook`，让学生看到生成、执行、改参数、再次执行的完整过程。
4. 进入 STM32/FreeRTOS 阶段后，再评估 `embedded-test-engineer`，先确认队内 harness 的技能发现规则。

本次检索到的嵌入式材料主要证明作者设计了哪些流程和工具，未提供与无 skill 基线的独立对照。因此课程中可以把它们作为可检查的工作流示例来讨论，不应把作者自述的流程效果讲成通用性能结论。

## 检查范围与未完成验证

1. 已查看上文逐项链接的原始 `SKILL.md`、作者文档或实现入口。
2. 已查看当前 Markdown 文件清单与目标目录状态。`research` 目录此前不存在，目标文件此前不存在。
3. 未安装技能或 CLI，未运行外部脚本，未访问 API Key、GitHub 凭证或硬件。
4. 课前仍需在实际 DeepSeek harness 上验证 `teach` 和 `jupyter-notebook` 的发现方式，以及 Context7 对队内所用 C/C++、CMake、ROS 文档的索引覆盖。
