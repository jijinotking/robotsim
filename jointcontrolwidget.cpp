#include "jointcontrolwidget.h"
#include <QApplication>

JointControlWidget::JointControlWidget(int jointId, const QString &jointName, QWidget *parent)
    : QWidget(parent)
    , m_jointId(jointId)
    , m_jointName(jointName)
    , m_minValue(-180.0)
    , m_maxValue(180.0)
    , m_currentValue(0.0)
    , m_jointEnabled(true)
{
    setupUI();
    
    // 连接信号槽
    connect(m_slider, &QSlider::valueChanged, this, &JointControlWidget::onSliderValueChanged);
    connect(m_spinBox, QOverload<double>::of(&QDoubleSpinBox::valueChanged),
            this, &JointControlWidget::onSpinBoxValueChanged);
    connect(m_enableCheckBox, &QCheckBox::toggled, this, &JointControlWidget::onEnabledChanged);
    connect(m_zeroButton, &QPushButton::clicked, this, &JointControlWidget::onZeroButtonClicked);
    
    // 设置初始值
    setValue(0.0);
    setJointEnabled(true);
}

void JointControlWidget::setupUI()
{
    // 创建主分组框
    m_groupBox = new QGroupBox(m_jointName);
    m_groupBox->setFixedSize(280, 180);
    
    // 创建布局
    m_mainLayout = new QVBoxLayout(m_groupBox);
    m_controlLayout = new QHBoxLayout;
    m_buttonLayout = new QHBoxLayout;
    
    // 创建标签
    m_nameLabel = new QLabel(QString("ID: %1").arg(m_jointId));
    m_nameLabel->setAlignment(Qt::AlignCenter);
    m_nameLabel->setStyleSheet("font-weight: bold; color: #4CAF50;");
    
    m_valueLabel = new QLabel("0.00°");
    m_valueLabel->setAlignment(Qt::AlignCenter);
    m_valueLabel->setStyleSheet("font-size: 14px; font-weight: bold;");
    
    // 创建滑块
    m_slider = new QSlider(Qt::Horizontal);
    m_slider->setRange(0, SLIDER_RESOLUTION);
    m_slider->setValue(SLIDER_RESOLUTION / 2);
    m_slider->setTickPosition(QSlider::TicksBelow);
    m_slider->setTickInterval(SLIDER_RESOLUTION / 10);
    
    // 创建数值输入框
    m_spinBox = new QDoubleSpinBox;
    m_spinBox->setRange(m_minValue, m_maxValue);
    m_spinBox->setDecimals(2);
    m_spinBox->setSuffix("°");
    m_spinBox->setValue(0.0);
    m_spinBox->setFixedWidth(80);
    
    // 创建位置进度条
    m_positionBar = new QProgressBar;
    m_positionBar->setRange(0, SLIDER_RESOLUTION);
    m_positionBar->setValue(SLIDER_RESOLUTION / 2);
    m_positionBar->setTextVisible(false);
    m_positionBar->setFixedHeight(8);
    m_positionBar->setStyleSheet(
        "QProgressBar {"
        "    border: 1px solid #555;"
        "    border-radius: 4px;"
        "    background-color: #333;"
        "}"
        "QProgressBar::chunk {"
        "    background-color: #4CAF50;"
        "    border-radius: 3px;"
        "}"
    );
    
    // 创建按钮
    m_zeroButton = new QPushButton("归零");
    m_zeroButton->setFixedSize(50, 25);
    m_zeroButton->setStyleSheet(
        "QPushButton {"
        "    background-color: #2196F3;"
        "    color: white;"
        "    border: none;"
        "    border-radius: 3px;"
        "    font-size: 10px;"
        "}"
        "QPushButton:hover {"
        "    background-color: #1976D2;"
        "}"
        "QPushButton:pressed {"
        "    background-color: #0D47A1;"
        "}"
    );
    
    // 创建使能复选框
    m_enableCheckBox = new QCheckBox("使能");
    m_enableCheckBox->setChecked(true);
    m_enableCheckBox->setStyleSheet("color: #FFC107; font-weight: bold;");
    
    // 设置布局
    m_controlLayout->addWidget(new QLabel("值:"));
    m_controlLayout->addWidget(m_spinBox);
    m_controlLayout->addStretch();
    
    m_buttonLayout->addWidget(m_zeroButton);
    m_buttonLayout->addStretch();
    m_buttonLayout->addWidget(m_enableCheckBox);
    
    m_mainLayout->addWidget(m_nameLabel);
    m_mainLayout->addWidget(m_valueLabel);
    m_mainLayout->addWidget(m_slider);
    m_mainLayout->addWidget(m_positionBar);
    m_mainLayout->addLayout(m_controlLayout);
    m_mainLayout->addLayout(m_buttonLayout);
    
    // 设置主布局
    QVBoxLayout *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);
    layout->addWidget(m_groupBox);
}

double JointControlWidget::getValue() const
{
    return m_currentValue;
}

void JointControlWidget::setValue(double value)
{
    value = qBound(m_minValue, value, m_maxValue);
    
    if (qAbs(value - m_currentValue) < 0.01) {
        return; // 避免微小变化引起的无限循环
    }
    
    m_currentValue = value;
    
    // 更新UI组件
    m_spinBox->blockSignals(true);
    m_spinBox->setValue(value);
    m_spinBox->blockSignals(false);
    
    updateSliderFromSpinBox();
    
    // 更新显示标签
    m_valueLabel->setText(QString("%1°").arg(value, 0, 'f', 2));
    
    // 更新进度条
    double normalizedValue = (value - m_minValue) / (m_maxValue - m_minValue);
    int progressValue = static_cast<int>(normalizedValue * SLIDER_RESOLUTION);
    m_positionBar->setValue(progressValue);
    
    // 根据值的大小改变进度条颜色
    QString color;
    if (qAbs(value) < 10.0) {
        color = "#4CAF50"; // 绿色 - 接近零位
    } else if (qAbs(value) < 90.0) {
        color = "#FFC107"; // 黄色 - 中等角度
    } else {
        color = "#FF5722"; // 红色 - 大角度
    }
    
    m_positionBar->setStyleSheet(
        QString("QProgressBar {"
                "    border: 1px solid #555;"
                "    border-radius: 4px;"
                "    background-color: #333;"
                "}"
                "QProgressBar::chunk {"
                "    background-color: %1;"
                "    border-radius: 3px;"
                "}").arg(color)
    );
}

void JointControlWidget::setRange(double min, double max)
{
    m_minValue = min;
    m_maxValue = max;
    
    m_spinBox->setRange(min, max);
    
    // 确保当前值在新范围内
    if (m_currentValue < min || m_currentValue > max) {
        setValue(qBound(min, m_currentValue, max));
    } else {
        updateSliderFromSpinBox();
    }
}

double JointControlWidget::getMinValue() const
{
    return m_minValue;
}

double JointControlWidget::getMaxValue() const
{
    return m_maxValue;
}

void JointControlWidget::setJointEnabled(bool enabled)
{
    m_jointEnabled = enabled;
    m_enableCheckBox->setChecked(enabled);
    
    // 更新UI状态
    m_slider->setEnabled(enabled);
    m_spinBox->setEnabled(enabled);
    m_zeroButton->setEnabled(enabled);
    
    // 更新样式
    if (enabled) {
        m_groupBox->setStyleSheet("QGroupBox { color: white; }");
        m_nameLabel->setStyleSheet("font-weight: bold; color: #4CAF50;");
    } else {
        m_groupBox->setStyleSheet("QGroupBox { color: #666; }");
        m_nameLabel->setStyleSheet("font-weight: bold; color: #666;");
    }
}

bool JointControlWidget::isJointEnabled() const
{
    return m_jointEnabled;
}

int JointControlWidget::getJointId() const
{
    return m_jointId;
}

void JointControlWidget::onSliderValueChanged(int value)
{
    updateSpinBoxFromSlider();
    emit valueChanged(m_jointId, m_currentValue);
}

void JointControlWidget::onSpinBoxValueChanged(double value)
{
    setValue(value);
    emit valueChanged(m_jointId, value);
}

void JointControlWidget::onEnabledChanged(bool enabled)
{
    setJointEnabled(enabled);
    emit enabledChanged(m_jointId, enabled);
}

void JointControlWidget::onZeroButtonClicked()
{
    setValue(0.0);
    emit valueChanged(m_jointId, 0.0);
    emit zeroRequested(m_jointId);
}

void JointControlWidget::updateSliderFromSpinBox()
{
    double normalizedValue = (m_currentValue - m_minValue) / (m_maxValue - m_minValue);
    int sliderValue = static_cast<int>(normalizedValue * SLIDER_RESOLUTION);
    
    m_slider->blockSignals(true);
    m_slider->setValue(sliderValue);
    m_slider->blockSignals(false);
}

void JointControlWidget::updateSpinBoxFromSlider()
{
    double normalizedValue = static_cast<double>(m_slider->value()) / SLIDER_RESOLUTION;
    double value = m_minValue + normalizedValue * (m_maxValue - m_minValue);
    
    m_spinBox->blockSignals(true);
    m_spinBox->setValue(value);
    m_spinBox->blockSignals(false);
    
    setValue(value);
}

double JointControlWidget::getCurrentValue() const
{
    return m_currentValue;
}

double JointControlWidget::getTargetValue() const
{
    // 目标值就是当前设置的值
    return m_currentValue;
}