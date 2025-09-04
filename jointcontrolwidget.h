#ifndef JOINTCONTROLWIDGET_H
#define JOINTCONTROLWIDGET_H

#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QSlider>
#include <QDoubleSpinBox>
#include <QPushButton>
#include <QProgressBar>
#include <QCheckBox>
#include <QGroupBox>

class JointControlWidget : public QWidget
{
    Q_OBJECT

public:
    explicit JointControlWidget(int jointId, const QString &jointName, QWidget *parent = nullptr);
    
    // 获取和设置关节值
    double getValue() const;
    void setValue(double value);
    
    // 获取当前值和目标值（用于运动状态显示）
    double getCurrentValue() const;
    double getTargetValue() const;
    
    // 获取和设置范围
    void setRange(double min, double max);
    double getMinValue() const;
    double getMaxValue() const;
    
    // 使能控制
    void setJointEnabled(bool enabled);
    bool isJointEnabled() const;
    
    // 获取关节ID
    int getJointId() const;

signals:
    void valueChanged(int jointId, double value);
    void enabledChanged(int jointId, bool enabled);
    void zeroRequested(int jointId);

private slots:
    void onSliderValueChanged(int value);
    void onSpinBoxValueChanged(double value);
    void onEnabledChanged(bool enabled);
    void onZeroButtonClicked();

private:
    void setupUI();
    void updateSliderFromSpinBox();
    void updateSpinBoxFromSlider();
    
    int m_jointId;
    QString m_jointName;
    double m_minValue;
    double m_maxValue;
    double m_currentValue;
    bool m_jointEnabled;
    
    // UI组件
    QGroupBox *m_groupBox;
    QLabel *m_nameLabel;
    QLabel *m_valueLabel;
    QSlider *m_slider;
    QDoubleSpinBox *m_spinBox;
    QPushButton *m_zeroButton;
    QCheckBox *m_enableCheckBox;
    QProgressBar *m_positionBar;
    
    // 布局
    QVBoxLayout *m_mainLayout;
    QHBoxLayout *m_controlLayout;
    QHBoxLayout *m_buttonLayout;
    
    // 常量
    static const int SLIDER_RESOLUTION = 1000; // 滑块分辨率
};

#endif // JOINTCONTROLWIDGET_H