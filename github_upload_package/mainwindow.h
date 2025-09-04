#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QPushButton>
#include <QLabel>
#include <QSpinBox>
#include <QDoubleSpinBox>
#include <QSlider>
#include <QProgressBar>
#include <QTextEdit>
#include <QComboBox>
#include <QTimer>
#include <QStatusBar>
#include <QMenuBar>
#include <QAction>
#include <QTabWidget>
#include <QSplitter>
#include <QScrollArea>
#include <QOpenGLWidget>
#include <QGraphicsView>
#include <QGraphicsScene>
#include <QGraphicsTextItem>
#include <QCheckBox>
#include <QFrame>

#include "robotcontroller.h"
#include "jointcontrolwidget.h"

QT_BEGIN_NAMESPACE
class QAction;
class QMenu;
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void connectToRobot();
    void disconnectFromRobot();
    void emergencyStop();
    void resetToZeroPosition();
    void saveCurrentPosition();
    void loadPosition();
    void enableAllJoints();
    void disableAllJoints();
    void onRobotStatusChanged(bool connected);
    void onJointValueChanged(int jointId, double value);
    void updateRobotStatus();
    void toggleSimulationMode(bool enabled);  // 新增：切换仿真模式

private:
    void setupUI();
    void setupMenuBar();
    void setupStatusBar();
    void setupJointControls();
    void setupControlPanel();
    void setupLogPanel();
    void setupMotionStatusPanel();  // 新增：运动状态面板
    void setupRenderWindow();       // 新增：设置渲染窗口
    void updateMotionStatusDisplay();  // 新增：更新运动状态显示
    void updateRenderWindow();      // 新增：更新渲染窗口
    void createJointControlGroup(const QString &groupName, int startJoint, int jointCount, QWidget *parent);
    
    // UI组件
    QWidget *m_centralWidget;
    QSplitter *m_mainSplitter;
    QTabWidget *m_jointTabWidget;
    QScrollArea *m_scrollArea;
    
    // 关节控制组
    QGroupBox *m_leftArmGroup;
    QGroupBox *m_rightArmGroup;
    QGroupBox *m_waistGroup;
    QGroupBox *m_chassisGroup;
    QGroupBox *m_liftGroup;
    
    // 控制面板
    QGroupBox *m_controlGroup;
    QPushButton *m_connectBtn;
    QPushButton *m_disconnectBtn;
    QPushButton *m_emergencyStopBtn;
    QPushButton *m_resetZeroBtn;
    QPushButton *m_savePositionBtn;
    QPushButton *m_loadPositionBtn;
    QPushButton *m_enableAllBtn;
    QPushButton *m_disableAllBtn;
    
    // 状态显示
    QLabel *m_connectionStatusLabel;
    QLabel *m_robotStatusLabel;
    QProgressBar *m_batteryLevel;
    
    // 运动状态显示
    QGroupBox *m_motionStatusGroup;
    QLabel *m_motionStateLabel;        // 运动状态标签
    QLabel *m_currentSpeedLabel;       // 当前速度
    QLabel *m_targetPositionLabel;     // 目标位置
    QProgressBar *m_motionProgressBar; // 运动进度
    QLabel *m_activeJointsLabel;       // 活跃关节数
    QLabel *m_motionTimeLabel;         // 运动时间
    
    // 渲染窗口
    QWidget *m_renderWidget;           // 渲染窗口容器
    QGraphicsView *m_renderView;       // 图形视图
    QGraphicsScene *m_renderScene;     // 图形场景
    QLabel *m_renderStatusLabel;       // 渲染状态标签
    
    // 仿真模式
    QCheckBox *m_simulationModeCheckBox; // 仿真模式复选框
    bool m_isSimulationMode;           // 仿真模式标志
    
    // 日志面板
    QTextEdit *m_logTextEdit;
    
    // 关节控制器
    QList<JointControlWidget*> m_jointControls;
    
    // 机器人控制器
    RobotController *m_robotController;
    
    // 定时器
    QTimer *m_statusUpdateTimer;
    
    // 菜单和动作
    QMenu *m_fileMenu;
    QMenu *m_robotMenu;
    QMenu *m_helpMenu;
    QAction *m_exitAction;
    QAction *m_aboutAction;
    QAction *m_connectAction;
    QAction *m_disconnectAction;
    QAction *m_emergencyStopAction;
};

#endif // MAINWINDOW_H