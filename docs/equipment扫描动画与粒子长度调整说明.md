# equipment 扫描动画与粒子长度调整说明

## 修改目标

当前 `trail_camera.tscn` 的 research 过程较简略：点击 `Research` 后只立即修改石头状态并增加科技点，equipment 没有可见动作。

本次修改目标：

1. 点击 `Research` 后，让 `equipment` 平滑向下倾斜，模拟扫描设备对准地面 / 岩石。
2. 延长 `GPUParticles3D` 的粒子轨迹长度，使扫描光束看起来更长、更连续。
3. 让科技点结算发生在扫描动画完成后，而不是点击按钮瞬间完成。
4. 修复 UI 在“已研究石头”与“未研究石头”之间切换时提示文本没有恢复的问题。
4. 保留原有石头检测、UI 显示、鼠标模式和科技点逻辑。

## 涉及文件

```text
game/assets/script/main.gd
game/assets/scene/equipment.tscn
```

## 一、equipment 向下倾斜动画

修改文件：

```text
game/assets/script/main.gd
```

新增引用：

```gdscript
@onready var equipment: Node3D = $rover/equipment
```

新增状态：

```gdscript
var scanning_rock: Node3D = null
var scan_tween: Tween
var equipment_rest_rotation: Vector3
```

新增可调参数：

```gdscript
@export_range(0.0, 90.0, 0.1) var scan_tilt_degrees: float = 22.0
@export_range(0.05, 2.0, 0.01) var scan_tilt_duration: float = 0.3
@export_range(0.1, 5.0, 0.01) var scan_hold_duration: float = 1.5
@export_range(0.05, 2.0, 0.01) var scan_return_duration: float = 0.4
```

参数含义：

```text
scan_tilt_degrees     向下倾斜角度，默认 22°
scan_tilt_duration    从原角度倾斜到扫描角度的时间，默认 0.3 秒
scan_hold_duration    保持扫描状态的时间，默认 1.5 秒
scan_return_duration  从扫描角度恢复原角度的时间，默认 0.4 秒
```

`_ready()` 中记录 equipment 的原始旋转：

```gdscript
equipment_rest_rotation = equipment.rotation
```

这样以后如果在场景中调整了 equipment 的基础角度，脚本仍会以该角度作为恢复值，不会把设备强行归零。

## 扫描动画流程

点击 `Research` 后调用：

```gdscript
start_equipment_scan_animation()
```

动画分为三段：

```text
1. 0.3 秒：equipment 绕本地 X 轴向下倾斜 22°
2. 1.5 秒：保持倾斜，粒子形成较长扫描轨迹
3. 0.4 秒：equipment 平滑恢复原始角度
```

动画使用：

```gdscript
Tween.TRANS_SINE
```

因此倾斜和恢复都有平滑加减速，不会出现生硬的瞬间转向。

旋转目标：

```gdscript
equipment_rest_rotation + Vector3(deg_to_rad(scan_tilt_degrees), 0, 0)
```

`equipment` 的局部 `+Z` 方向是当前扫描粒子发射方向。绕本地 X 轴正向旋转后，`+Z` 会朝下偏转，因此形成向下扫描的视觉效果。

## 二、research 结算延迟到动画完成

原来的逻辑是点击按钮后立即执行：

```gdscript
current_rock.researched = true
tech_point += 5
```

现在点击按钮后进入扫描状态：

```gdscript
scanning_rock = current_rock
research_button_do.disabled = true
label_do.text = "Scanning rock..."
start_equipment_scan_animation()
```

动画结束后才执行：

```gdscript
scanned_rock.researched = true
tech_point += 5
```

这样可以避免“按钮刚点下去研究就已经结束”的突兀感。

扫描期间：

```text
Research 按钮会被禁用
Label 显示 Scanning rock...
equipment 播放倾斜扫描动画
```

扫描完成后：

```text
石头 researched 状态变为 true
tech_point 增加 5
UI 刷新
按钮恢复可用
Label 恢复对应提示文本
```

另外，`show_current_research()` 中原本未真正执行提示恢复：

```gdscript
research_prompt
```

现已改为：

```gdscript
label_do.text = research_prompt
```

因此从已研究石头区域切换到未研究石头区域时，Label 不会停留在上一块石头的已研究提示。

如果扫描期间当前目标切换到另一块石头，动画完成后会刷新当前 UI，并恢复按钮可用状态。

如果扫描期间玩家驶出所有石头范围，动画仍会完成并记录原石头的研究结果，但 UI 会按原有进入 / 退出逻辑隐藏，不会重复研究同一块石头。

## 三、延长粒子效果

修改文件：

```text
game/assets/scene/equipment.tscn
```

节点：

```text
equipment/GPUParticles3D
```

参数变化：

```text
Amount：   8  → 20
Lifetime： 1  → 2.5
Preprocess：0 → 2.5
```

场景文件中的实际写法：

```gdscript
amount = 20
lifetime = 2.5
preprocess = 2.5
```

### 长度计算

粒子初速度仍为：

```text
Initial Velocity = 1.0
```

关闭重力后，粒子近似匀速直线运动，因此轨迹长度约为：

```text
轨迹长度 = 初速度 × Lifetime
```

修改前：

```text
1.0 × 1.0 = 1.0
```

修改后：

```text
1.0 × 2.5 = 2.5
```

也就是扫描粒子长度约为原来的 `2.5` 倍。

### 数量计算

修改前：

```text
Amount = 8
Lifetime = 1.0
粒子发射密度 = 8 / 1.0 = 8 个 / 秒
```

修改后：

```text
Amount = 20
Lifetime = 2.5
粒子发射密度 = 20 / 2.5 = 8 个 / 秒
```

因此粒子轨迹变长的同时，单位时间发射密度保持不变，避免延长后看起来变得稀疏。

### Preprocess

新增：

```gdscript
preprocess = 2.5
```

作用是让粒子系统在场景刚开始时预先模拟 `2.5` 秒。这样游戏启动后不需要等待粒子逐个发射，扫描轨迹一开始就是完整长度。

## 四、保持不变的内容

以下内容没有修改：

```text
GPUParticles3D Position = (0, 0, 0.9050703)
GPUParticles3D Rotation.X = 90°
ParticleProcessMaterial Direction = (0, 1, 0)
ParticleProcessMaterial Spread = 0
ParticleProcessMaterial Initial Velocity = (1, 1)
ParticleProcessMaterial Gravity = (0, 0, 0)
particle_flag_inherit_emitter_scale = true
Draw Pass 1 = res://assets/resources/particle1.tres
```

因此之前已经修复的粒子方向、尺寸继承逻辑不会被本次修改破坏。

石头检测也保持原有结构：

```text
rocks/rockX/area3d
→ body_entered / body_exited
→ main.gd 中 body_enter / body_exist
```

## 五、最终效果

车辆进入岩石检测范围后：

```text
research UI 显示
```

点击 `Research` 后：

```text
equipment 向下倾斜 22°
扫描粒子保持较长轨迹
按钮暂时禁用
Label 显示 Scanning rock...
```

约 `2.2` 秒后：

```text
equipment 回到原始角度
石头标记为 researched
tech_point +5
UI 刷新为已研究状态
```

总扫描时长：

```text
0.3 + 1.5 + 0.4 = 2.2 秒
```
