# equipment 粒子方向设置说明

## 修改对象

- 场景：`game/assets/scene/equipment.tscn`
- 节点：`equipment/GPUParticles3D`
- 粒子显示网格：`game/assets/resources/particle1.tres`，保持不变

## 目的

1. 让 `GPUParticles3D` 使用的 Torus 粒子网格中心轴与 `Cylinder` 的中心轴平行。
2. 让粒子从当前发射点沿 `equipment` 本地坐标系的 Z 轴正方向发射。

## 明确参数更改

### 1. GPUParticles3D 旋转

原值：

```text
Rotation.X = 0
Rotation.Y = 0
Rotation.Z = 0
```

新值：

```text
Rotation.X = 90°
Rotation.Y = 0
Rotation.Z = 0
```

等价脚本值：

```gdscript
rotation = Vector3(PI / 2.0, 0, 0)
```

场景中的基础矩阵由：

```text
Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0.9050703)
```

改为：

```text
Transform3D(1, 0, 0, 0, -4.371139e-08, -1, 0, 1, -4.371139e-08, 0, 0, 0.9050703)
```

位置保持不变：

```text
Position = (0, 0, 0.9050703)
```

作用：粒子网格原来的局部 `+Y` 轴会被旋转到 `equipment` 的 `+Z` 轴，使 Torus 网格中心轴与 Cylinder 中心轴平行。

### 2. 新增 ParticleProcessMaterial

为 `GPUParticles3D.process_material` 新增并挂载一个 `ParticleProcessMaterial`。

原值：

```text
process_material = null
```

新值：

```text
process_material = ParticleProcessMaterial_equipment
```

### 3. 发射方向

设置为：

```text
Direction = (0, 1, 0)
```

脚本写法：

```gdscript
direction = Vector3(0, 1, 0)
```

说明：因为 `GPUParticles3D` 已经绕 X 轴旋转 90°，其局部 `+Y` 方向对应 `equipment` 的 `+Z` 方向，所以这里设置 `(0, 1, 0)`，最终发射方向是 `equipment +Z`。

### 4. 发射扩散角

设置为：

```text
Spread = 0°
```

作用：粒子不向四周扩散，保持直线沿 `equipment +Z` 发射。

### 5. 初始速度

设置为：

```text
Initial Velocity Min = 1.0
Initial Velocity Max = 1.0
```

资源写法：

```text
initial_velocity = Vector2(1, 1)
```

作用：每个粒子以固定 1 单位/秒的初速度沿指定方向发射。

### 6. 重力

设置为：

```text
Gravity = (0, 0, 0)
```

作用：关闭默认重力，避免粒子下坠，保证粒子沿 Z 轴直线运动。

## 保持不变的参数

以下常见参数保持 Godot 默认值，未在本次修改中额外设置：

```text
Amount = 8
Lifetime = 1.0
Emitting = true
Local Coords = false
Speed Scale = 1.0
Explosiveness = 0.0
Randomness = 0.0
Draw Pass 1 = res://assets/resources/particle1.tres
```

如后续需要更密集或更长的粒子效果，可以再显式调整 `Amount` 与 `Lifetime`。

## 最终关系

修改后：

```text
Cylinder 中心轴：equipment +Z
Torus 粒子网格中心轴：equipment +Z
粒子发射方向：equipment +Z
```
