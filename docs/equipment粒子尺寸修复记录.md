# equipment 粒子尺寸修复记录

## 问题现象

场景引用链为：

```text
trail_camera.tscn
└── sojourner.tscn / VehicleBody3D / equipment
    └── equipment.tscn
        ├── Cylinder
        └── GPUParticles3D
```

`equipment.tscn` 单独打开时，`GPUParticles3D` 的显示尺寸看起来正常；但 `equipment` 被实例化到 `sojourner.tscn` 后，又在 `trail_camera.tscn` 中加载，粒子在最终场景中明显没有跟随 equipment 的缩小比例，视觉尺寸过大。

## 原因分析

`sojourner.tscn` 中 `equipment` 实例的 Transform3D 前 3×3 矩阵为：

```text
Transform3D(0.14999999, 0, 0,
            0, 0.14999999, 0,
            0, 0, 0.14999999, ...)
```

也就是 uniform scale = `0.15`。

`equipment/GPUParticles3D` 使用的 `ParticleProcessMaterial_equipment` 原本未开启 Godot 4 的粒子继承发射器缩放选项，因此粒子不会自动继承 equipment 实例的 `0.15` 缩放，导致最终场景中粒子尺寸偏大。

相关默认值：

```text
particle_flag_inherit_emitter_scale = false
scale_min = 1.0
scale_max = 1.0
```

## 修复方案

修改文件：

```text
game/assets/scene/equipment.tscn
```

在 `ParticleProcessMaterial_equipment` 中新增：

```text
particle_flag_inherit_emitter_scale = true
```

完整修改后的资源参数：

```text
[sub_resource type="ParticleProcessMaterial" id="ParticleProcessMaterial_equipment"]
direction = Vector3(0, 1, 0)
spread = 0.0
initial_velocity = Vector2(1, 1)
gravity = Vector3(0, 0, 0)
particle_flag_inherit_emitter_scale = true
```

这样 `GPUParticles3D` 会继承 equipment 实例的 `0.15` uniform scale，不需要手工把 `scale_min`、`scale_max` 或 Draw Pass 网格硬编码成另一个尺寸。

##尺寸变化

由脚本检查得到：

```text
equipment / Cylinder 本地 AABB 宽度：约 2.6197
particle1.tres 网格本地 AABB 宽度：约 2.0200
sojourner 中 equipment 实例缩放：0.15
```

修复前：

```text
2.0200 × 1.0 = 2.0200
```

修复后：

```text
2.0200 × 0.15 = 0.3030
```

缩小后的粒子宽度约为最终 equipment 圆柱宽度 `2.6197 × 0.15 = 0.3930` 的 `77%`，与 equipment 的比例保持在同一视觉量级。

## 保持不变的内容

以下内容未修改：

```text
GPUParticles3D Position = (0, 0, 0.9050703)
GPUParticles3D Rotation.X = 90°
ParticleProcessMaterial Direction = (0, 1, 0)
ParticleProcessMaterial Spread = 0
ParticleProcessMaterial Initial Velocity = (1, 1)
ParticleProcessMaterial Gravity = (0, 0, 0)
Draw Pass 1 = res://assets/resources/particle1.tres
sojourner 中 equipment 实例的 Transform3D
trail_camera 中 rover 实例的 Transform3D
```

因此之前文档中记录的粒子方向和发射逻辑不会被本次尺寸修复影响。

## 验证方式

1. 在 Godot 中打开 `game/assets/scene/equipment.tscn`，确认 Inspector 中 `ParticleProcessMaterial → Particle Flags → Inherit Emitter Scale` 为勾选状态。
2. 打开 `game/assets/scene/sojourner.tscn`，选中嵌套的 `equipment/GPUParticles3D`，确认最终视觉尺寸随 equipment 的 `0.15` 缩放变小。
3. 运行或打开 `game/assets/scene/trail_camera.tscn`，确认主场景中的粒子不再明显大于 equipment。
