#include "mainwindow.h"
#include <QApplication>
#include <QMessageBox>
#include <QFileDialog>
#include <QSettings>
#include <QDateTime>
#include <QTime>
#include <QFrame>
#include <QSplitter>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , m_centralWidget(nullptr)
    , m_robotController(nullptr)
    , m_statusUpdateTimer(nullptr)
{
    setWindowTitle("机器人运动控制上位机 v1.0");
    setMinimumSize(1200, 800);
    resize(1400, 900);
    
    // 初始化机器人控制器
    m_robotController = new RobotController(this);
    connect(m_robotController, &RobotController::connectionStatusChanged,
            this, &MainWindow::onRobotStatusChanged);
    
    // 设置UI
    setupUI();
    setupMenuBar();
    setupStatusBar();
    
    // 设置状态更新定时器
    m_statusUpdateTimer = new QTimer(this);
    connect(m_statusUpdateTimer, &QTimer::timeout, this, &MainWindow::updateRobotStatus);
    m_statusUpdateTimer->start(100); // 100ms更新一次
    
    // 初始状态
    m_isSimulationMode = false;  // 初始化仿真模式标志
    onRobotStatusChanged(false);
}

MainWindow::~MainWindow()
{
}

void MainWindow::setupUI()
{
    m_centralWidget = new QWidget;
    setCentralWidget(m_centralWidget);
    
    // 创建主分割器
    m_mainSplitter = new QSplitter(Qt::Horizontal, this);
    
    // 创建关节控制区域
    setupJointControls();
    
    // 创建运动状态面板
    setupMotionStatusPanel();
    
    // 创建控制面板
    setupControlPanel();
    
    // 创建日志面板
    setupLogPanel();
    
    // 创建渲染窗口
    setupRenderWindow();
    
    // 设置布局
    QHBoxLayout *mainLayout = new QHBoxLayout(m_centralWidget);
    mainLayout->addWidget(m_mainSplitter);
    
    // 设置分割器比例
    m_mainSplitter->setSizes({800, 400});
}

void MainWindow::setupJointControls()
{
    // 创建标签页控件
    m_jointTabWidget = new QTabWidget;
    
    // 创建滚动区域
    m_scrollArea = new QScrollArea;
    m_scrollArea->setWidgetResizable(true);
    m_scrollArea->setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    m_scrollArea->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    
    QWidget *jointControlWidget = new QWidget;
    QVBoxLayout *jointLayout = new QVBoxLayout(jointControlWidget);
    
    // 创建各个关节组
    createJointControlGroup("左臂关节 (8个)", 0, 8, jointControlWidget);
    createJointControlGroup("右臂关节 (8个)", 8, 8, jointControlWidget);
    createJointControlGroup("腰部关节 (2个)", 16, 2, jointControlWidget);
    createJointControlGroup("底盘电机 (2个)", 18, 2, jointControlWidget);
    createJointControlGroup("升降机构 (1个)", 20, 1, jointControlWidget);
    
    jointLayout->addStretch();
    m_scrollArea->setWidget(jointControlWidget);
    
    m_jointTabWidget->addTab(m_scrollArea, "关节控制");
    
    // 添加到主分割器
    m_mainSplitter->addWidget(m_jointTabWidget);
}

void MainWindow::createJointControlGroup(const QString &groupName, int startJoint, int jointCount, QWidget *parent)
{
    QGroupBox *group = new QGroupBox(groupName);
    QGridLayout *layout = new QGridLayout(group);
    
    for (int i = 0; i < jointCount; ++i) {
        int jointId = startJoint + i;
        QString jointName = QString("关节 %1").arg(jointId + 1);
        
        JointControlWidget *jointControl = new JointControlWidget(jointId, jointName);
        connect(jointControl, &JointControlWidget::valueChanged,
                this, &MainWindow::onJointValueChanged);
        
        m_jointControls.append(jointControl);
        
        int row = i / 2;
        int col = i % 2;
        layout->addWidget(jointControl, row, col);
    }
    
    parent->layout()->addWidget(group);
}

void MainWindow::setupControlPanel()
{
    QWidget *controlWidget = new QWidget;
    QVBoxLayout *controlLayout = new QVBoxLayout(controlWidget);
    
    // 连接控制组
    QGroupBox *connectionGroup = new QGroupBox("连接控制");
    QVBoxLayout *connLayout = new QVBoxLayout(connectionGroup);
    
    m_connectBtn = new QPushButton("连接机器人");
    m_disconnectBtn = new QPushButton("断开连接");
    m_emergencyStopBtn = new QPushButton("紧急停止");
    m_emergencyStopBtn->setStyleSheet("QPushButton { background-color: #ff4444; color: white; font-weight: bold; }");
    
    // 仿真模式复选框
    m_simulationModeCheckBox = new QCheckBox("仿真模式");
    m_simulationModeCheckBox->setToolTip("启用仿真模式，可在不连接真实机器人的情况下进行操作");
    
    connLayout->addWidget(m_connectBtn);
    connLayout->addWidget(m_disconnectBtn);
    connLayout->addWidget(m_emergencyStopBtn);
    
    // 添加分隔线
    QFrame *line = new QFrame();
    line->setFrameShape(QFrame::HLine);
    line->setFrameShadow(QFrame::Sunken);
    connLayout->addWidget(line);
    
    connLayout->addWidget(m_simulationModeCheckBox);
    
    // 位置控制组
    QGroupBox *positionGroup = new QGroupBox("位置控制");
    QVBoxLayout *posLayout = new QVBoxLayout(positionGroup);
    
    m_resetZeroBtn = new QPushButton("复位到零位");
    m_savePositionBtn = new QPushButton("保存当前位置");
    m_loadPositionBtn = new QPushButton("加载位置");
    
    posLayout->addWidget(m_resetZeroBtn);
    posLayout->addWidget(m_savePositionBtn);
    posLayout->addWidget(m_loadPositionBtn);
    
    // 关节控制组
    QGroupBox *jointGroup = new QGroupBox("关节控制");
    QVBoxLayout *jointLayout = new QVBoxLayout(jointGroup);
    
    m_enableAllBtn = new QPushButton("使能所有关节");
    m_disableAllBtn = new QPushButton("失能所有关节");
    
    jointLayout->addWidget(m_enableAllBtn);
    jointLayout->addWidget(m_disableAllBtn);
    
    // 状态显示组
    QGroupBox *statusGroup = new QGroupBox("状态信息");
    QVBoxLayout *statusLayout = new QVBoxLayout(statusGroup);
    
    m_connectionStatusLabel = new QLabel("连接状态: 未连接");
    m_robotStatusLabel = new QLabel("机器人状态: 离线");
    
    QLabel *batteryLabel = new QLabel("电池电量:");
    m_batteryLevel = new QProgressBar;
    m_batteryLevel->setRange(0, 100);
    m_batteryLevel->setValue(0);
    
    statusLayout->addWidget(m_connectionStatusLabel);
    statusLayout->addWidget(m_robotStatusLabel);
    statusLayout->addWidget(batteryLabel);
    statusLayout->addWidget(m_batteryLevel);
    
    // 添加到控制布局
    controlLayout->addWidget(connectionGroup);
    controlLayout->addWidget(positionGroup);
    controlLayout->addWidget(jointGroup);
    controlLayout->addWidget(statusGroup);
    controlLayout->addWidget(m_motionStatusGroup);  // 添加运动状态面板
    controlLayout->addStretch();
    
    // 连接信号槽
    connect(m_connectBtn, &QPushButton::clicked, this, &MainWindow::connectToRobot);
    connect(m_disconnectBtn, &QPushButton::clicked, this, &MainWindow::disconnectFromRobot);
    connect(m_emergencyStopBtn, &QPushButton::clicked, this, &MainWindow::emergencyStop);
    connect(m_resetZeroBtn, &QPushButton::clicked, this, &MainWindow::resetToZeroPosition);
    connect(m_savePositionBtn, &QPushButton::clicked, this, &MainWindow::saveCurrentPosition);
    connect(m_loadPositionBtn, &QPushButton::clicked, this, &MainWindow::loadPosition);
    connect(m_enableAllBtn, &QPushButton::clicked, this, &MainWindow::enableAllJoints);
    connect(m_disableAllBtn, &QPushButton::clicked, this, &MainWindow::disableAllJoints);
    connect(m_simulationModeCheckBox, &QCheckBox::toggled, this, &MainWindow::toggleSimulationMode);
    
    m_mainSplitter->addWidget(controlWidget);
}

void MainWindow::setupLogPanel()
{
    QWidget *logWidget = new QWidget;
    QVBoxLayout *logLayout = new QVBoxLayout(logWidget);
    
    QLabel *logLabel = new QLabel("系统日志:");
    m_logTextEdit = new QTextEdit;
    m_logTextEdit->setMaximumHeight(200);
    m_logTextEdit->setReadOnly(true);
    
    logLayout->addWidget(logLabel);
    logLayout->addWidget(m_logTextEdit);
    
    // 添加到控制面板的底部
    QWidget *controlWidget = qobject_cast<QWidget*>(m_mainSplitter->widget(1));
    if (controlWidget) {
        controlWidget->layout()->addWidget(logWidget);
    }
    
    // 添加初始日志
    m_logTextEdit->append(QString("[%1] 系统启动").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
}

void MainWindow::setupMenuBar()
{
    // 文件菜单
    m_fileMenu = menuBar()->addMenu("文件(&F)");
    m_exitAction = new QAction("退出(&X)", this);
    m_exitAction->setShortcut(QKeySequence::Quit);
    connect(m_exitAction, &QAction::triggered, this, &QWidget::close);
    m_fileMenu->addAction(m_exitAction);
    
    // 机器人菜单
    m_robotMenu = menuBar()->addMenu("机器人(&R)");
    m_connectAction = new QAction("连接(&C)", this);
    m_disconnectAction = new QAction("断开连接(&D)", this);
    m_emergencyStopAction = new QAction("紧急停止(&E)", this);
    m_emergencyStopAction->setShortcut(QKeySequence("F1"));
    
    connect(m_connectAction, &QAction::triggered, this, &MainWindow::connectToRobot);
    connect(m_disconnectAction, &QAction::triggered, this, &MainWindow::disconnectFromRobot);
    connect(m_emergencyStopAction, &QAction::triggered, this, &MainWindow::emergencyStop);
    
    m_robotMenu->addAction(m_connectAction);
    m_robotMenu->addAction(m_disconnectAction);
    m_robotMenu->addSeparator();
    m_robotMenu->addAction(m_emergencyStopAction);
    
    // 帮助菜单
    m_helpMenu = menuBar()->addMenu("帮助(&H)");
    m_aboutAction = new QAction("关于(&A)", this);
    connect(m_aboutAction, &QAction::triggered, [this]() {
        QMessageBox::about(this, "关于", 
            "机器人运动控制上位机 v1.0\n\n"
            "支持轮臂机器人控制:\n"
            "- 左臂: 8个关节\n"
            "- 右臂: 8个关节\n"
            "- 腰部: 2个关节\n"
            "- 底盘: 2个电机\n"
            "- 升降: 1个电机\n\n"
            "总计21个自由度");
    });
    m_helpMenu->addAction(m_aboutAction);
}

void MainWindow::setupStatusBar()
{
    statusBar()->showMessage("就绪");
}

void MainWindow::connectToRobot()
{
    m_logTextEdit->append(QString("[%1] 正在连接机器人...").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
    
    if (m_robotController->connectToRobot()) {
        m_logTextEdit->append(QString("[%1] 机器人连接成功").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
        statusBar()->showMessage("已连接到机器人");
    } else {
        m_logTextEdit->append(QString("[%1] 机器人连接失败").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
        QMessageBox::warning(this, "连接失败", "无法连接到机器人，请检查连接设置。");
    }
}

void MainWindow::disconnectFromRobot()
{
    m_robotController->disconnectFromRobot();
    m_logTextEdit->append(QString("[%1] 已断开机器人连接").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
    statusBar()->showMessage("已断开连接");
}

void MainWindow::emergencyStop()
{
    m_robotController->emergencyStop();
    m_logTextEdit->append(QString("[%1] 紧急停止已激活").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
    QMessageBox::warning(this, "紧急停止", "紧急停止已激活！所有运动已停止。");
}

void MainWindow::resetToZeroPosition()
{
    m_robotController->resetToZeroPosition();
    
    // 更新UI显示
    for (auto *jointControl : m_jointControls) {
        jointControl->setValue(0.0);
    }
    
    m_logTextEdit->append(QString("[%1] 机器人已复位到零位").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
}

void MainWindow::saveCurrentPosition()
{
    QString fileName = QFileDialog::getSaveFileName(this, "保存位置", "", "位置文件 (*.pos)");
    if (!fileName.isEmpty()) {
        QSettings settings(fileName, QSettings::IniFormat);
        
        for (int i = 0; i < m_jointControls.size(); ++i) {
            settings.setValue(QString("joint_%1").arg(i), m_jointControls[i]->getValue());
        }
        
        m_logTextEdit->append(QString("[%1] 位置已保存到: %2").arg(QDateTime::currentDateTime().toString("hh:mm:ss"), fileName));
    }
}

void MainWindow::loadPosition()
{
    QString fileName = QFileDialog::getOpenFileName(this, "加载位置", "", "位置文件 (*.pos)");
    if (!fileName.isEmpty()) {
        QSettings settings(fileName, QSettings::IniFormat);
        
        for (int i = 0; i < m_jointControls.size(); ++i) {
            double value = settings.value(QString("joint_%1").arg(i), 0.0).toDouble();
            m_jointControls[i]->setValue(value);
            m_robotController->setJointPosition(i, value);
        }
        
        m_logTextEdit->append(QString("[%1] 位置已从文件加载: %2").arg(QDateTime::currentDateTime().toString("hh:mm:ss"), fileName));
    }
}

void MainWindow::enableAllJoints()
{
    for (auto *jointControl : m_jointControls) {
        jointControl->setEnabled(true);
    }
    m_robotController->enableAllJoints();
    m_logTextEdit->append(QString("[%1] 所有关节已使能").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
}

void MainWindow::disableAllJoints()
{
    for (auto *jointControl : m_jointControls) {
        jointControl->setEnabled(false);
    }
    m_robotController->disableAllJoints();
    m_logTextEdit->append(QString("[%1] 所有关节已失能").arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
}

void MainWindow::onRobotStatusChanged(bool connected)
{
    m_connectBtn->setEnabled(!connected);
    m_disconnectBtn->setEnabled(connected);
    m_resetZeroBtn->setEnabled(connected);
    m_savePositionBtn->setEnabled(connected);
    m_loadPositionBtn->setEnabled(connected);
    m_enableAllBtn->setEnabled(connected);
    m_disableAllBtn->setEnabled(connected);
    
    m_connectAction->setEnabled(!connected);
    m_disconnectAction->setEnabled(connected);
    
    if (connected) {
        m_connectionStatusLabel->setText("连接状态: 已连接");
        m_robotStatusLabel->setText("机器人状态: 在线");
        m_connectionStatusLabel->setStyleSheet("color: green;");
    } else {
        m_connectionStatusLabel->setText("连接状态: 未连接");
        m_robotStatusLabel->setText("机器人状态: 离线");
        m_connectionStatusLabel->setStyleSheet("color: red;");
        m_batteryLevel->setValue(0);
    }
}

void MainWindow::onJointValueChanged(int jointId, double value)
{
    m_robotController->setJointPosition(jointId, value);
}

void MainWindow::updateRobotStatus()
{
    if (m_robotController->isConnected()) {
        // 更新电池电量（模拟数据）
        static int batteryValue = 85;
        m_batteryLevel->setValue(batteryValue);
        
        // 更新关节位置反馈（如果有的话）
        // 这里可以从机器人控制器获取实际的关节位置反馈
        
        // 更新运动状态显示
        updateMotionStatusDisplay();
        
        // 更新渲染窗口
        updateRenderWindow();
    }
}

void MainWindow::setupMotionStatusPanel()
{
    // 创建运动状态组
    m_motionStatusGroup = new QGroupBox("机器人运动状态", this);
    m_motionStatusGroup->setStyleSheet(
        "QGroupBox {"
        "    font-weight: bold;"
        "    border: 2px solid #cccccc;"
        "    border-radius: 5px;"
        "    margin-top: 1ex;"
        "    padding-top: 10px;"
        "}"
        "QGroupBox::title {"
        "    subcontrol-origin: margin;"
        "    left: 10px;"
        "    padding: 0 5px 0 5px;"
        "}"
    );
    
    // 创建布局
    QVBoxLayout *statusLayout = new QVBoxLayout(m_motionStatusGroup);
    
    // 运动状态标签
    m_motionStateLabel = new QLabel("运动状态: 静止", this);
    m_motionStateLabel->setStyleSheet("font-weight: bold; color: #2E8B57;");
    statusLayout->addWidget(m_motionStateLabel);
    
    // 当前速度
    m_currentSpeedLabel = new QLabel("当前速度: 0.0 °/s", this);
    statusLayout->addWidget(m_currentSpeedLabel);
    
    // 目标位置
    m_targetPositionLabel = new QLabel("目标位置: 未设置", this);
    statusLayout->addWidget(m_targetPositionLabel);
    
    // 运动进度条
    QLabel *progressLabel = new QLabel("运动进度:", this);
    statusLayout->addWidget(progressLabel);
    
    m_motionProgressBar = new QProgressBar(this);
    m_motionProgressBar->setRange(0, 100);
    m_motionProgressBar->setValue(0);
    m_motionProgressBar->setStyleSheet(
        "QProgressBar {"
        "    border: 2px solid grey;"
        "    border-radius: 5px;"
        "    text-align: center;"
        "}"
        "QProgressBar::chunk {"
        "    background-color: #4CAF50;"
        "    border-radius: 3px;"
        "}"
    );
    statusLayout->addWidget(m_motionProgressBar);
    
    // 活跃关节数
    m_activeJointsLabel = new QLabel("活跃关节: 0/21", this);
    statusLayout->addWidget(m_activeJointsLabel);
    
    // 运动时间
    m_motionTimeLabel = new QLabel("运动时间: 00:00", this);
    statusLayout->addWidget(m_motionTimeLabel);
    
    // 添加分隔线
    QFrame *line = new QFrame(this);
    line->setFrameShape(QFrame::HLine);
    line->setFrameShadow(QFrame::Sunken);
    statusLayout->addWidget(line);
    
    // 添加到右侧面板（与控制面板一起）
    // 这里需要修改setupControlPanel中的布局
}

void MainWindow::updateMotionStatusDisplay()
{
    if (!m_robotController->isConnected()) {
        m_motionStateLabel->setText("运动状态: 离线");
        m_motionStateLabel->setStyleSheet("font-weight: bold; color: #DC143C;");
        m_currentSpeedLabel->setText("当前速度: -- °/s");
        m_targetPositionLabel->setText("目标位置: --");
        m_motionProgressBar->setValue(0);
        m_activeJointsLabel->setText("活跃关节: --/21");
        m_motionTimeLabel->setText("运动时间: --:--");
        return;
    }
    
    // 计算活跃关节数（正在运动的关节）
    int activeJoints = 0;
    double totalSpeed = 0.0;
    
    for (auto *jointControl : m_jointControls) {
        if (jointControl->isEnabled()) {
            activeJoints++;
            // 这里可以获取关节的实际速度，现在使用模拟数据
            totalSpeed += qAbs(jointControl->getCurrentValue() - jointControl->getTargetValue()) * 0.1;
        }
    }
    
    // 更新运动状态
    if (activeJoints > 0 && totalSpeed > 0.1) {
        m_motionStateLabel->setText("运动状态: 运动中");
        m_motionStateLabel->setStyleSheet("font-weight: bold; color: #FF8C00;");
        
        // 模拟运动进度
        static int progress = 0;
        progress = (progress + 2) % 101;
        m_motionProgressBar->setValue(progress);
    } else {
        m_motionStateLabel->setText("运动状态: 静止");
        m_motionStateLabel->setStyleSheet("font-weight: bold; color: #2E8B57;");
        m_motionProgressBar->setValue(100);
    }
    
    // 更新显示信息
    m_currentSpeedLabel->setText(QString("当前速度: %1 °/s").arg(totalSpeed, 0, 'f', 1));
    m_activeJointsLabel->setText(QString("活跃关节: %1/21").arg(activeJoints));
    
    // 更新运动时间（模拟）
    static QTime motionStartTime = QTime::currentTime();
    if (activeJoints > 0) {
        QTime currentTime = QTime::currentTime();
        int elapsed = motionStartTime.secsTo(currentTime);
        m_motionTimeLabel->setText(QString("运动时间: %1:%2")
            .arg(elapsed / 60, 2, 10, QChar('0'))
            .arg(elapsed % 60, 2, 10, QChar('0')));
    } else {
        motionStartTime = QTime::currentTime();
        m_motionTimeLabel->setText("运动时间: 00:00");
    }
}

void MainWindow::setupRenderWindow()
{
    // 创建渲染窗口容器
    m_renderWidget = new QWidget;
    QVBoxLayout *renderLayout = new QVBoxLayout(m_renderWidget);
    
    // 创建标题标签
    QLabel *titleLabel = new QLabel("机器人3D视图");
    titleLabel->setAlignment(Qt::AlignCenter);
    titleLabel->setStyleSheet("font-weight: bold; font-size: 14px; padding: 5px;");
    
    // 创建图形视图和场景
    m_renderScene = new QGraphicsScene(this);
    m_renderView = new QGraphicsView(m_renderScene);
    
    // 设置渲染视图属性
    m_renderView->setMinimumSize(400, 300);
    m_renderView->setStyleSheet("background-color: #1a1a1a; border: 2px solid #333333;");
    m_renderView->setRenderHint(QPainter::Antialiasing);
    
    // 设置场景大小
    m_renderScene->setSceneRect(-200, -150, 400, 300);
    
    // 添加一些基本的3D坐标轴指示
    QPen axisPen(Qt::white, 2);
    
    // X轴 (红色)
    QPen xAxisPen(Qt::red, 3);
    m_renderScene->addLine(-180, 0, -130, 0, xAxisPen);
    QGraphicsTextItem *xText = m_renderScene->addText("X", QFont("Arial", 10));
    xText->setPos(-125, -15);
    xText->setDefaultTextColor(Qt::red);
    
    // Y轴 (绿色)
    QPen yAxisPen(Qt::green, 3);
    m_renderScene->addLine(-180, 0, -180, -50, yAxisPen);
    QGraphicsTextItem *yText = m_renderScene->addText("Y", QFont("Arial", 10));
    yText->setPos(-190, -60);
    yText->setDefaultTextColor(Qt::green);
    
    // Z轴 (蓝色)
    QPen zAxisPen(Qt::blue, 3);
    m_renderScene->addLine(-180, 0, -160, -20, zAxisPen);
    QGraphicsTextItem *zText = m_renderScene->addText("Z", QFont("Arial", 10));
    zText->setPos(-155, -35);
    zText->setDefaultTextColor(Qt::blue);
    
    // 添加网格
    QPen gridPen(QColor(64, 64, 64), 1);
    for (int i = -200; i <= 200; i += 20) {
        m_renderScene->addLine(i, -150, i, 150, gridPen);
        m_renderScene->addLine(-200, i, 200, i, gridPen);
    }
    
    // 添加中心提示文本
    QGraphicsTextItem *centerText = m_renderScene->addText("机器人3D模型渲染区域\n(开发中...)", QFont("Arial", 12));
    centerText->setDefaultTextColor(Qt::white);
    centerText->setPos(-80, -10);
    
    // 创建状态标签
    m_renderStatusLabel = new QLabel("渲染状态: 就绪");
    m_renderStatusLabel->setStyleSheet("color: #2E8B57; font-weight: bold;");
    
    // 添加到布局
    renderLayout->addWidget(titleLabel);
    renderLayout->addWidget(m_renderView);
    renderLayout->addWidget(m_renderStatusLabel);
    
    // 将渲染窗口添加到主分割器的左侧（与关节控制一起）
    // 创建左侧分割器
    QSplitter *leftSplitter = new QSplitter(Qt::Vertical);
    
    // 从主分割器中取出关节控制区域
    QWidget *jointControlWidget = m_mainSplitter->widget(0);
    if (jointControlWidget) {
        // 先从主分割器中移除，但不删除
        jointControlWidget->setParent(nullptr);
        
        // 添加到左侧分割器
        leftSplitter->addWidget(jointControlWidget);
        leftSplitter->addWidget(m_renderWidget);
        
        // 将左侧分割器添加到主分割器的第一个位置
        m_mainSplitter->insertWidget(0, leftSplitter);
        
        // 设置左侧分割器比例 (关节控制:渲染窗口 = 3:2)
        leftSplitter->setSizes({600, 400});
    } else {
        // 如果没有找到关节控制区域，直接添加渲染窗口
        m_mainSplitter->insertWidget(0, m_renderWidget);
    }
}

void MainWindow::updateRenderWindow()
{
    if (!m_renderScene) return;
    
    // 更新渲染状态
    if (m_isSimulationMode) {
        m_renderStatusLabel->setText("渲染状态: 仿真模式");
        m_renderStatusLabel->setStyleSheet("color: #FF8C00; font-weight: bold;");
    } else if (m_robotController && m_robotController->isConnected()) {
        m_renderStatusLabel->setText("渲染状态: 实时同步");
        m_renderStatusLabel->setStyleSheet("color: #2E8B57; font-weight: bold;");
    } else {
        m_renderStatusLabel->setText("渲染状态: 离线");
        m_renderStatusLabel->setStyleSheet("color: #DC143C; font-weight: bold;");
    }
    
    // TODO: 在这里添加实际的机器人模型渲染逻辑
    // 根据关节角度更新机器人姿态
    // 这里可以集成OpenGL或其他3D渲染库
}

void MainWindow::toggleSimulationMode(bool enabled)
{
    m_isSimulationMode = enabled;
    
    if (enabled) {
        // 启用仿真模式
        m_logTextEdit->append(QString("[%1] 仿真模式已启用")
            .arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
        
        // 在仿真模式下，允许关节控制即使没有连接机器人
        for (auto *jointControl : m_jointControls) {
            jointControl->setEnabled(true);
        }
        
        // 更新按钮状态
        m_connectBtn->setEnabled(false);
        m_disconnectBtn->setEnabled(false);
        
    } else {
        // 禁用仿真模式
        m_logTextEdit->append(QString("[%1] 仿真模式已禁用")
            .arg(QDateTime::currentDateTime().toString("hh:mm:ss")));
        
        // 恢复正常的连接状态控制
        bool isConnected = m_robotController && m_robotController->isConnected();
        m_connectBtn->setEnabled(!isConnected);
        m_disconnectBtn->setEnabled(isConnected);
        
        // 如果没有连接机器人，禁用关节控制
        if (!isConnected) {
            for (auto *jointControl : m_jointControls) {
                jointControl->setEnabled(false);
            }
        }
    }
    
    // 更新渲染窗口
    updateRenderWindow();
}