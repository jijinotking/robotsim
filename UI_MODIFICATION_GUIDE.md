# 界面修改指南 - 添加机器人运动状态显示

## 概述

本指南详细说明了如何在机器人控制上位机界面中添加运动状态显示功能。新增的运动状态面板会实时显示机器人的运动信息，包括运动状态、当前速度、运动进度等。

## 修改的文件

### 1. `mainwindow.h` - 头文件声明

**添加的内容：**
- 新增函数声明：
  ```cpp
  void setupMotionStatusPanel();     // 设置运动状态面板
  void updateMotionStatusDisplay();  // 更新运动状态显示
  ```

- 新增UI组件成员变量：
  ```cpp
  // 运动状态显示
  QGroupBox *m_motionStatusGroup;
  QLabel *m_motionStateLabel;        // 运动状态标签
  QLabel *m_currentSpeedLabel;       // 当前速度
  QLabel *m_targetPositionLabel;     // 目标位置
  QProgressBar *m_motionProgressBar; // 运动进度
  QLabel *m_activeJointsLabel;       // 活跃关节数
  QLabel *m_motionTimeLabel;         // 运动时间
  ```

### 2. `mainwindow.cpp` - 主要实现

**添加的内容：**

#### a) 头文件包含
```cpp
#include <QTime>    // 用于运动时间计算
#include <QFrame>   // 用于分隔线
```

#### b) 在setupUI()中调用新面板
```cpp
// 创建运动状态面板
setupMotionStatusPanel();
```

#### c) 在setupControlPanel()中添加到布局
```cpp
controlLayout->addWidget(m_motionStatusGroup);  // 添加运动状态面板
```

#### d) 在updateRobotStatus()中更新显示
```cpp
// 更新运动状态显示
updateMotionStatusDisplay();
```

#### e) 实现新函数

**setupMotionStatusPanel()** - 创建运动状态面板UI：
- 创建QGroupBox容器
- 添加各种状态标签和进度条
- 设置样式和布局

**updateMotionStatusDisplay()** - 更新运动状态显示：
- 计算活跃关节数
- 计算总体运动速度
- 更新运动状态（静止/运动中）
- 更新运动时间
- 更新进度条

### 3. `jointcontrolwidget.h` - 关节控制组件头文件

**添加的内容：**
```cpp
// 获取当前值和目标值（用于运动状态显示）
double getCurrentValue() const;
double getTargetValue() const;
```

### 4. `jointcontrolwidget.cpp` - 关节控制组件实现

**添加的内容：**
```cpp
double JointControlWidget::getCurrentValue() const
{
    return m_currentValue;
}

double JointControlWidget::getTargetValue() const
{
    // 目标值就是当前设置的值
    return m_currentValue;
}
```

## 运动状态面板功能

### 显示内容

1. **运动状态**：显示机器人当前是"静止"还是"运动中"
   - 静止：绿色显示
   - 运动中：橙色显示
   - 离线：红色显示

2. **当前速度**：显示所有关节的综合运动速度（°/s）

3. **目标位置**：显示当前设置的目标位置信息

4. **运动进度**：用进度条显示运动完成情况

5. **活跃关节**：显示当前启用的关节数量（如：15/21）

6. **运动时间**：显示持续运动的时间（MM:SS格式）

### 样式特性

- 使用现代化的样式设计
- 颜色编码的状态指示
- 圆角边框和阴影效果
- 响应式布局

## 如何进一步自定义

### 1. 修改显示内容

要添加新的状态信息，在 `mainwindow.h` 中添加新的QLabel：

```cpp
QLabel *m_newStatusLabel;  // 新状态标签
```

在 `setupMotionStatusPanel()` 中创建和添加：

```cpp
m_newStatusLabel = new QLabel("新状态: 未知", this);
statusLayout->addWidget(m_newStatusLabel);
```

在 `updateMotionStatusDisplay()` 中更新：

```cpp
m_newStatusLabel->setText(QString("新状态: %1").arg(newValue));
```

### 2. 修改样式

在 `setupMotionStatusPanel()` 中修改样式表：

```cpp
m_motionStatusGroup->setStyleSheet(
    "QGroupBox {"
    "    font-weight: bold;"
    "    border: 2px solid #your_color;"  // 修改边框颜色
    "    border-radius: 10px;"            // 修改圆角大小
    "    background-color: #your_bg;"     // 添加背景色
    "}"
);
```

### 3. 添加新的计算逻辑

在 `updateMotionStatusDisplay()` 中添加自定义计算：

```cpp
// 自定义计算示例
double customMetric = 0.0;
for (auto *jointControl : m_jointControls) {
    if (jointControl->isEnabled()) {
        // 添加自定义计算逻辑
        customMetric += yourCalculation(jointControl);
    }
}
```

### 4. 添加实时数据源

如果要显示真实的机器人数据，需要：

1. 在 `RobotController` 中添加获取实时数据的方法
2. 在 `updateMotionStatusDisplay()` 中调用这些方法
3. 替换模拟数据为真实数据

```cpp
// 示例：获取真实速度数据
if (m_robotController->isConnected()) {
    double realSpeed = m_robotController->getCurrentSpeed();
    m_currentSpeedLabel->setText(QString("当前速度: %1 °/s").arg(realSpeed, 0, 'f', 1));
}
```

## 编译和测试

1. **编译项目**：
   ```bash
   ./build_project.sh
   ```

2. **运行测试**：
   ```bash
   ./start_demo.sh
   ```

3. **验证功能**：
   - 启动程序后，在右侧面板应该能看到"机器人运动状态"组
   - 连接机器人后，状态应该从"离线"变为"静止"
   - 调整关节角度时，状态应该变为"运动中"
   - 各项数据应该实时更新

## 故障排除

### 常见问题

1. **编译错误**：
   - 检查是否添加了所有必要的头文件
   - 确保所有新增的成员变量都已声明
   - 验证函数签名是否正确

2. **界面不显示**：
   - 检查是否在 `setupUI()` 中调用了 `setupMotionStatusPanel()`
   - 确认是否在 `setupControlPanel()` 中添加到了布局
   - 验证QGroupBox是否正确创建

3. **数据不更新**：
   - 检查是否在 `updateRobotStatus()` 中调用了 `updateMotionStatusDisplay()`
   - 确认定时器是否正常工作
   - 验证关节控制器的数据获取是否正确

### 调试技巧

1. **添加调试输出**：
   ```cpp
   qDebug() << "Motion status update:" << activeJoints << totalSpeed;
   ```

2. **检查UI组件状态**：
   ```cpp
   if (!m_motionStatusGroup) {
       qWarning() << "Motion status group not created!";
       return;
   }
   ```

3. **验证数据范围**：
   ```cpp
   if (totalSpeed < 0 || totalSpeed > 1000) {
       qWarning() << "Invalid speed value:" << totalSpeed;
   }
   ```

## 总结

通过以上修改，您已经成功在机器人控制上位机中添加了运动状态显示功能。这个功能提供了：

- 实时的机器人运动状态监控
- 直观的视觉反馈
- 详细的运动参数显示
- 可扩展的架构设计

您可以根据实际需求进一步定制和扩展这些功能。