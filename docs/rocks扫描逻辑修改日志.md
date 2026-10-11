# Rocks 逐个扫描修复：详细修改日志

日期：2026-09-16  
项目：Game / Godot  
涉及文件：`game/assets/script/main.gd`、`game/assets/script/rock1.gd`

## 1. 修改目标与范围

目标：扫描一块石头时，仅更新该石头的研究状态；切换到其他石头时，显示对应的状态，并避免重复获得科技点。

本次修改保留共用研究界面的结构，为每个石头实例增加独立状态，并在信号回调中传递石头身份。没有修改石头场景、材质、模型或地形资源。

本文“修改前”的代码来自本次修复开始时读取的工作区内容，并非 Git HEAD；“修改后”的代码来自导出文档时的工作区文件。原有的其他未提交修改不属于本日志范围。

## 2. 问题原因

原来的 `for rock in $rocks.get_children()` 用于遍历石头并连接区域信号，本身没有批量修改所有石头。实际问题发生在连接之后：

1. 每块石头都连接到同一个回调，但回调仅收到进入区域的物体 `a`，无法识别信号来自哪块石头。
2. 点击 Research 只修改共用 Label 和按钮，没有保存单块石头的扫描状态。
3. 进入下一块石头范围时，只重新显示按钮，没有恢复初始文字，因此沿用上一块石头的研究提示。
4. 离开再进入后仍可再次点击加分，因为没有防止重复研究的状态判断。

因此，“所有都变化”在当前代码中表现为共用界面状态串用，而不是循环直接修改了所有石头的材质或外观。

## 3. 改动总览

| 修改位置 | 修改之前 | 修改之后 | 作用 |
| --- | --- | --- | --- |
| `rock1.gd` 实例状态 | 无研究状态 | `researched: bool = false` | 每块石头独立记录是否研究 |
| 主场景目标记录 | 无当前目标 | `current_rock` | 确定按钮操作哪块石头 |
| 区域内目标记录 | 无范围列表 | `nearby_rocks` | 支持检测范围重叠时切换目标 |
| 初始提示 | 未保存 | `research_prompt` | 未研究石头恢复场景中的初始文字 |
| 信号连接 | 仅传递进入或离开的物体 | `.bind(rock)` 额外传递石头 | 识别信号来源 |
| 进入区域 | 直接打开共用界面 | 选择石头并按状态刷新界面 | 消除界面状态串用 |
| 点击研究 | 每次调用加 5 分 | 校验目标、状态和界面后加分 | 每块石头只加分一次 |
| 离开区域 | 无条件关闭界面 | 仅在当前目标离开时切换或关闭 | 避免其他区域干扰当前界面 |
| 关闭界面 | 仅隐藏界面 | 隐藏并恢复鼠标捕获 | 恢复游戏鼠标控制 |

## 4. 完整代码前后对比

### main.gd：修改前

```gdscript
extends Node3D
@onready var research_ui = $CanvasLayer/research_ui
@onready var rocks = $rocks
@onready var research_button_do = $CanvasLayer/research_ui/do
@onready var label_do = $CanvasLayer/research_ui/Label
@onready var research_button_notdo = $"CanvasLayer/research_ui/not do"
var tech_point: int = 0

func body_enter(a):
	if a.name == "rover":
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		research_ui.visible = true
		research_button_do.visible = true
		print("进")

func body_exist(a):
	if a.name == "rover":
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		research_ui.visible = false
		print("出")

func button_do_clicked():
	tech_point += 5
	print(tech_point)
	label_do.text =  "doing the research, blablabla"
	research_button_do.visible = false

func button_exist_clicked():
	research_ui.visible = false

func _ready():
	research_ui.visible = false
	for rock in $rocks.get_children():
		var area = rock.get_node_or_null("area3d")
		if area:
			area.body_entered.connect(body_enter)
			area.body_exited.connect(body_exist)
	research_button_do.pressed.connect(button_do_clicked)
	research_button_notdo.pressed.connect(button_exist_clicked)
```


### main.gd：修改后

```gdscript
extends Node3D
@onready var research_ui = $CanvasLayer/research_ui
@onready var rocks = $rocks
@onready var research_button_do = $CanvasLayer/research_ui/do
@onready var label_do = $CanvasLayer/research_ui/Label
@onready var research_button_notdo = $"CanvasLayer/research_ui/not do"
var tech_point: int = 0
var current_rock: Node3D = null
var nearby_rocks: Array[Node3D] = []
var research_prompt: String

func body_enter(a, rock: Node3D):
	if a.name == "rover":
		if not nearby_rocks.has(rock):
			nearby_rocks.append(rock)
		current_rock = rock
		show_current_research()
		print("进")

func body_exist(a, rock: Node3D):
	if a.name == "rover":
		nearby_rocks.erase(rock)
		if current_rock == rock:
			current_rock = null
			if not nearby_rocks.is_empty():
				current_rock = nearby_rocks.back()
				show_current_research()
			else:
				button_exist_clicked()
		print("出")

func show_current_research():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	research_ui.visible = true
	research_button_do.visible = not current_rock.researched
	label_do.text = "doing the research, blablabla" if current_rock.researched else research_prompt

func button_do_clicked():
	if current_rock == null or current_rock.researched or not research_ui.visible:
		return
	current_rock.researched = true
	tech_point += 5
	print(tech_point)
	show_current_research()

func button_exist_clicked():
	research_ui.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _ready():
	research_ui.visible = false
	research_prompt = label_do.text
	for rock in rocks.get_children():
		var area = rock.get_node_or_null("area3d")
		if area:
			area.body_entered.connect(body_enter.bind(rock))
			area.body_exited.connect(body_exist.bind(rock))
	research_button_do.pressed.connect(button_do_clicked)
	research_button_notdo.pressed.connect(button_exist_clicked)
```


### main.gd：差异视图

以下 `-` 表示删除，`+` 表示新增。

```diff
--- before/main.gd
+++ after/main.gd
@@ -5,36 +5,56 @@
 @onready var label_do = $CanvasLayer/research_ui/Label
 @onready var research_button_notdo = $"CanvasLayer/research_ui/not do"
 var tech_point: int = 0
+var current_rock: Node3D = null
+var nearby_rocks: Array[Node3D] = []
+var research_prompt: String
 
-func body_enter(a):
+func body_enter(a, rock: Node3D):
 	if a.name == "rover":
-		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
-		research_ui.visible = true
-		research_button_do.visible = true
+		if not nearby_rocks.has(rock):
+			nearby_rocks.append(rock)
+		current_rock = rock
+		show_current_research()
 		print("进")
 
-func body_exist(a):
+func body_exist(a, rock: Node3D):
 	if a.name == "rover":
-		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
-		research_ui.visible = false
+		nearby_rocks.erase(rock)
+		if current_rock == rock:
+			current_rock = null
+			if not nearby_rocks.is_empty():
+				current_rock = nearby_rocks.back()
+				show_current_research()
+			else:
+				button_exist_clicked()
 		print("出")
 
+func show_current_research():
+	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
+	research_ui.visible = true
+	research_button_do.visible = not current_rock.researched
+	label_do.text = "doing the research, blablabla" if current_rock.researched else research_prompt
+
 func button_do_clicked():
+	if current_rock == null or current_rock.researched or not research_ui.visible:
+		return
+	current_rock.researched = true
 	tech_point += 5
 	print(tech_point)
-	label_do.text =  "doing the research, blablabla"
-	research_button_do.visible = false
+	show_current_research()
 
 func button_exist_clicked():
 	research_ui.visible = false
+	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
 
 func _ready():
 	research_ui.visible = false
-	for rock in $rocks.get_children():
+	research_prompt = label_do.text
+	for rock in rocks.get_children():
 		var area = rock.get_node_or_null("area3d")
 		if area:
-			area.body_entered.connect(body_enter)
-			area.body_exited.connect(body_exist)
+			area.body_entered.connect(body_enter.bind(rock))
+			area.body_exited.connect(body_exist.bind(rock))
 	research_button_do.pressed.connect(button_do_clicked)
 	research_button_notdo.pressed.connect(button_exist_clicked)
```


### rock1.gd：修改前

```gdscript
extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		print("true")
	
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is VehicleBody3D:
		print("false")
```


### rock1.gd：修改后

```gdscript
extends Node3D

var researched: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is VehicleBody3D:
		print("true")
	
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is VehicleBody3D:
		print("false")
```


### rock1.gd：差异视图

以下 `-` 表示删除，`+` 表示新增。

```diff
--- before/rock1.gd
+++ after/rock1.gd
@@ -1,4 +1,6 @@
 extends Node3D
+
+var researched: bool = false
 
 
 # Called when the node enters the scene tree for the first time.
```


## 5. 每项变更的逻辑

### 5.1 每块石头独立保存研究状态

在 `rock1.gd` 中增加：

```gdscript
var researched: bool = false
```

这是普通实例变量，不是静态变量。同一石头场景实例化多次后，每个实例各有自己的值。扫描 A 时设置 `A.researched = true`，不会修改 B 的值。

该文件原有 `_ready()` 及区域进出打印函数保持原样；这些函数只输出日志，不负责界面更新。

### 5.2 将信号来源绑定到回调

修改前：

```gdscript
area.body_entered.connect(body_enter)
area.body_exited.connect(body_exist)
```

修改后：

```gdscript
area.body_entered.connect(body_enter.bind(rock))
area.body_exited.connect(body_exist.bind(rock))
```

区域信号原本传入物体 `a`，绑定的 `rock` 追加在其后，因此回调签名同步变为 `body_enter(a, rock: Node3D)` 与 `body_exist(a, rock: Node3D)`。

所有石头仍可共用回调函数，但每次执行都有明确的石头身份。循环仅负责连接信号，实际研究操作在按钮回调中执行。

### 5.3 明确当前操作目标

进入区域时，先将石头加入 `nearby_rocks`，并通过 `has()` 防止重复加入；随后将它赋给 `current_rock`，调用 `show_current_research()`。

当前选择规则是“最近进入范围的石头优先”，不是按距离选择，也不是按场景树顺序自动连续扫描。

### 5.4 根据当前石头状态刷新界面

新增 `show_current_research()`，集中负责显示界面、显示鼠标、更新按钮和文字：

- 未研究：显示 Research 按钮，文字恢复为 `research_prompt`。
- 已研究：隐藏 Research 按钮，文字使用原来的 `doing the research, blablabla`。

`research_prompt` 在 `_ready()` 中从 `label_do.text` 保存，因此无需在脚本中重复硬编码场景的初始提示。共用界面现在是当前石头状态的展示窗口，不再承担所有石头的状态存储。

### 5.5 研究只作用于当前石头，并且只计分一次

按钮回调先进行三项检查：

```gdscript
if current_rock == null or current_rock.researched or not research_ui.visible:
    return
```

没有目标、目标已研究或界面已关闭时，直接返回。检查通过后，先设置当前石头的 `researched = true`，再执行 `tech_point += 5`，最后刷新界面。

先写入状态可让后续重复调用被阻止。按钮隐藏之外，逻辑层也有重复保护。`tech_point` 仍是主场景统一管理的总科技点数。

### 5.6 正确处理重叠检测区域

退出任意石头区域时，先从 `nearby_rocks` 移除它：

- 退出的不是当前石头：不更改当前界面和目标。
- 退出的是当前石头，列表仍有其他石头：选取列表末尾的石头，并刷新界面。
- 退出的是当前石头，列表已空：清空目标并关闭界面。

例如，先进入 A，再进入 B，当前目标为 B。此时离开 A 不会关闭 B 的界面；若先离开 B，而 A 仍在范围内，则切回 A。

### 5.7 关闭界面时恢复鼠标控制

`button_exist_clicked()` 原来只隐藏界面，现在额外调用：

```gdscript
Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
```

手动关闭以及离开最后一块石头范围时，均使用这段关闭逻辑。手动关闭不会清除范围列表或研究状态，也不会自动研究下一块石头。

## 6. 典型操作流程

| 步骤 | 操作 | A 状态 | B 状态 | 总科技点 | 界面结果 |
| --- | --- | --- | --- | --- | --- |
| 1 | 开始运行 | 未研究 | 未研究 | 0 | 初始隐藏 |
| 2 | 进入 A 范围 | 未研究 | 未研究 | 0 | 显示初始提示与 Research 按钮 |
| 3 | 点击 Research | 已研究 | 未研究 | 5 | 显示研究提示并隐藏按钮 |
| 4 | 再次调用研究回调 | 已研究 | 未研究 | 5 | 状态不变，不重复加分 |
| 5 | 进入 B 范围 | 已研究 | 未研究 | 5 | 恢复初始提示与 Research 按钮 |
| 6 | 研究 B | 已研究 | 已研究 | 10 | 仅更新 B 状态 |
| 7 | 返回 A 范围 | 已研究 | 已研究 | 10 | 显示 A 已研究状态，不可重复加分 |

## 7. 验证记录

验证环境：本机 Godot `4.7.1.stable`，使用 headless 模式。

### 7.1 脚本检查

执行：

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path game --check-only --script res://assets/script/main.gd --log-file /tmp/rocks-check.log
```

结果：退出码为 0，主脚本检查通过。

### 7.2 行为回归验证

使用临时脚本 `/tmp/test_rocks.gd` 创建最小主场景节点、两个带实际 `rock1.gd` 脚本的石头、区域和研究界面，加载实际 `main.gd`，通过发送区域信号和按钮事件检查逻辑。

| 检查项 | 断言内容 | 结果 |
| --- | --- | --- |
| 状态独立 | 扫描 A 后，A 为已研究，B 仍未研究 | 通过 |
| 首次计分 | 扫描 A 后总分为 5 | 通过 |
| 重复保护 | 再调用研究回调，总分仍为 5 | 通过 |
| 切换提示 | 进入 B 后恢复初始文字，按钮可见 | 通过 |
| 非当前区域退出 | 当前为 B 时退出 A，B 界面仍显示 | 通过 |
| 第二块独立计分 | 扫描 B 后总分为 10 | 通过 |
| 最后区域退出 | 退出 B 后目标为空、界面隐藏 | 通过 |
| 重新进入 | 再进入 A 时研究按钮隐藏，再调用不加分 | 通过 |

最终测试退出码为 0，输出：

```text
PASS: independent research, repeat protection, overlap exit, revisit
```

首次运行临时测试时，测试节点尚未完成 `_ready()` 就访问按钮，导致空引用。调整测试脚本，等待节点就绪后重新运行，以上断言全部通过。这一调整只涉及临时测试脚本。

运行时还输出了一条 macOS 系统证书读取错误 `get_system_ca_certificates`；该日志未阻止测试完成，测试中的研究逻辑断言均通过。

测试脚本位于临时目录，不属于正式项目文件。尚未在完整地形场景中进行人工驾驶、真实物理区域触发及视觉效果验证；“退出当前石头后回退到另一块仍在范围内的石头”已实现，但该分支没有在此次断言脚本中直接覆盖。

## 8. 当前实现边界

- 状态仅在本次运行期间保存，没有新增存档；重新创建场景实例后恢复为未研究。
- 研究仍为点击后立即标记完成并加分，没有新增计时、动画或异步扫描过程。原有提示文字被保留。
- 仅名称为 `rover` 的物体会触发主场景研究交互，沿用原有判断规则。
- 参与交互的石头需要提供 `area3d` 子节点和 `researched` 属性；当前 `rock1.tscn` 的实例符合这一结构。
- 当前目标选择依据区域进入顺序；没有新增最近距离选择或目标列表界面。
- 当前实现针对固定存在的石头，尚未增加运行中删除石头时的引用清理逻辑。
- 手动关闭界面后，现有逻辑没有新增原地重新打开的快捷键；再次进入区域可重新显示界面。

## 9. 建议的人工验收步骤

1. 运行使用 `main.gd` 的场景，驾驶 rover 进入第一块石头范围，确认出现初始研究提示。
2. 点击 Research，确认科技点增加 5，按钮隐藏。
3. 离开并进入第二块石头范围，确认显示初始提示，仍可独立研究。
4. 返回第一块石头，确认按钮保持隐藏，不再重复获得科技点。
5. 在两个检测范围重叠的区域，分别验证退出非当前目标与退出当前目标的行为。
6. 点击关闭按钮，确认界面隐藏、鼠标恢复游戏控制。
