#include "robotcontroller.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

RobotController::RobotController(QObject *parent)
    : QObject(parent)
    , m_connectionType("tcp")
    , m_serialPort(nullptr)
    , m_tcpSocket(nullptr)
    , m_udpSocket(nullptr)
    , m_hostAddress("127.0.0.1")
    , m_port(8080)
{
    initializeJoints();
    
    // 创建状态更新定时器
    m_statusTimer = new QTimer(this);
    connect(m_statusTimer, &QTimer::timeout, this, &RobotController::updateRobotStatus);
    m_statusTimer->start(50); // 50ms更新一次，20Hz
    
    // 初始化机器人状态
    m_robotStatus.jointPositions.resize(TOTAL_JOINTS);
    m_robotStatus.jointVelocities.resize(TOTAL_JOINTS);
    m_robotStatus.jointTorques.resize(TOTAL_JOINTS);
}

RobotController::~RobotController()
{
    disconnectFromRobot();
}

void RobotController::initializeJoints()
{
    m_jointConfigs.clear();
    
    // 左臂关节 (0-7)
    for (int i = 0; i < 8; ++i) {
        m_jointConfigs.append(JointConfig(i, QString("左臂关节%1").arg(i+1), -180.0, 180.0));
    }
    
    // 右臂关节 (8-15)
    for (int i = 8; i < 16; ++i) {
        m_jointConfigs.append(JointConfig(i, QString("右臂关节%1").arg(i-7), -180.0, 180.0));
    }
    
    // 腰部关节 (16-17)
    for (int i = 16; i < 18; ++i) {
        m_jointConfigs.append(JointConfig(i, QString("腰部关节%1").arg(i-15), -90.0, 90.0));
    }
    
    // 底盘电机 (18-19)
    for (int i = 18; i < 20; ++i) {
        m_jointConfigs.append(JointConfig(i, QString("底盘电机%1").arg(i-17), -1000.0, 1000.0));
    }
    
    // 升降机构 (20)
    m_jointConfigs.append(JointConfig(20, "升降机构", 0.0, 500.0));
}

bool RobotController::connectToRobot()
{
    if (m_robotStatus.connected) {
        return true;
    }
    
    bool success = false;
    
    if (m_connectionType == "serial") {
        if (!m_serialPort) {
            m_serialPort = new QSerialPort(this);
            connect(m_serialPort, &QSerialPort::readyRead, this, &RobotController::onSerialDataReceived);
            connect(m_serialPort, QOverload<QSerialPort::SerialPortError>::of(&QSerialPort::errorOccurred),
                    this, &RobotController::onConnectionError);
        }
        
        if (!m_serialPort->isOpen()) {
            success = m_serialPort->open(QIODevice::ReadWrite);
        }
    }
    else if (m_connectionType == "tcp") {
        if (!m_tcpSocket) {
            m_tcpSocket = new QTcpSocket(this);
            connect(m_tcpSocket, &QTcpSocket::readyRead, this, &RobotController::onTcpDataReceived);
            connect(m_tcpSocket, QOverload<QAbstractSocket::SocketError>::of(&QAbstractSocket::errorOccurred),
                    this, &RobotController::onConnectionError);
            connect(m_tcpSocket, &QTcpSocket::connected, [this]() {
                m_robotStatus.connected = true;
                emit connectionStatusChanged(true);
                qDebug() << "TCP连接成功";
            });
        }
        
        if (m_tcpSocket->state() != QAbstractSocket::ConnectedState) {
            m_tcpSocket->connectToHost(m_hostAddress, m_port);
            success = m_tcpSocket->waitForConnected(3000);
        } else {
            success = true;
        }
    }
    else if (m_connectionType == "udp") {
        if (!m_udpSocket) {
            m_udpSocket = new QUdpSocket(this);
            connect(m_udpSocket, &QUdpSocket::readyRead, this, &RobotController::onUdpDataReceived);
        }
        
        success = m_udpSocket->bind(QHostAddress::Any, m_port);
        if (success) {
            m_robotStatus.connected = true;
        }
    }
    
    if (success && m_connectionType != "tcp") {
        m_robotStatus.connected = true;
        emit connectionStatusChanged(true);
    }
    
    return success;
}

void RobotController::disconnectFromRobot()
{
    if (m_serialPort && m_serialPort->isOpen()) {
        m_serialPort->close();
    }
    
    if (m_tcpSocket && m_tcpSocket->state() == QAbstractSocket::ConnectedState) {
        m_tcpSocket->disconnectFromHost();
    }
    
    if (m_udpSocket) {
        m_udpSocket->close();
    }
    
    m_robotStatus.connected = false;
    emit connectionStatusChanged(false);
}

bool RobotController::isConnected() const
{
    return m_robotStatus.connected;
}

void RobotController::setJointPosition(int jointId, double angle)
{
    if (jointId < 0 || jointId >= TOTAL_JOINTS) {
        return;
    }
    
    // 限制角度范围
    const JointConfig &config = m_jointConfigs[jointId];
    angle = qBound(config.minAngle, angle, config.maxAngle);
    
    // 更新内部状态
    m_jointConfigs[jointId].currentAngle = angle;
    m_robotStatus.jointPositions[jointId] = angle;
    
    // 发送命令到机器人
    if (m_robotStatus.connected) {
        QString command = formatJointCommand(jointId, angle, "position");
        sendCommand(command);
    }
    
    emit jointPositionChanged(jointId, angle);
}

void RobotController::setJointVelocity(int jointId, double velocity)
{
    if (jointId < 0 || jointId >= TOTAL_JOINTS) {
        return;
    }
    
    m_robotStatus.jointVelocities[jointId] = velocity;
    
    if (m_robotStatus.connected) {
        QString command = formatJointCommand(jointId, velocity, "velocity");
        sendCommand(command);
    }
}

void RobotController::setJointTorque(int jointId, double torque)
{
    if (jointId < 0 || jointId >= TOTAL_JOINTS) {
        return;
    }
    
    m_robotStatus.jointTorques[jointId] = torque;
    
    if (m_robotStatus.connected) {
        QString command = formatJointCommand(jointId, torque, "torque");
        sendCommand(command);
    }
}

double RobotController::getJointPosition(int jointId) const
{
    if (jointId < 0 || jointId >= TOTAL_JOINTS) {
        return 0.0;
    }
    
    return m_jointConfigs[jointId].currentAngle;
}

void RobotController::emergencyStop()
{
    m_robotStatus.emergencyStop = true;
    
    if (m_robotStatus.connected) {
        sendCommand("EMERGENCY_STOP");
    }
    
    // 停止所有关节运动
    for (int i = 0; i < TOTAL_JOINTS; ++i) {
        setJointVelocity(i, 0.0);
    }
}

void RobotController::resetToZeroPosition()
{
    if (m_robotStatus.emergencyStop) {
        m_robotStatus.emergencyStop = false;
    }
    
    for (int i = 0; i < TOTAL_JOINTS; ++i) {
        setJointPosition(i, 0.0);
    }
    
    if (m_robotStatus.connected) {
        sendCommand("RESET_ZERO");
    }
}

void RobotController::enableAllJoints()
{
    for (int i = 0; i < TOTAL_JOINTS; ++i) {
        enableJoint(i);
    }
    
    if (m_robotStatus.connected) {
        sendCommand("ENABLE_ALL");
    }
}

void RobotController::disableAllJoints()
{
    for (int i = 0; i < TOTAL_JOINTS; ++i) {
        disableJoint(i);
    }
    
    if (m_robotStatus.connected) {
        sendCommand("DISABLE_ALL");
    }
}

void RobotController::enableJoint(int jointId)
{
    if (jointId >= 0 && jointId < TOTAL_JOINTS) {
        m_jointConfigs[jointId].enabled = true;
        
        if (m_robotStatus.connected) {
            sendCommand(QString("ENABLE_JOINT %1").arg(jointId));
        }
    }
}

void RobotController::disableJoint(int jointId)
{
    if (jointId >= 0 && jointId < TOTAL_JOINTS) {
        m_jointConfigs[jointId].enabled = false;
        
        if (m_robotStatus.connected) {
            sendCommand(QString("DISABLE_JOINT %1").arg(jointId));
        }
    }
}

RobotStatus RobotController::getRobotStatus() const
{
    return m_robotStatus;
}

JointConfig RobotController::getJointConfig(int jointId) const
{
    if (jointId >= 0 && jointId < TOTAL_JOINTS) {
        return m_jointConfigs[jointId];
    }
    return JointConfig();
}

void RobotController::setConnectionType(const QString &type)
{
    m_connectionType = type.toLower();
}

void RobotController::setSerialPort(const QString &portName, int baudRate)
{
    if (m_serialPort) {
        m_serialPort->setPortName(portName);
        m_serialPort->setBaudRate(baudRate);
        m_serialPort->setDataBits(QSerialPort::Data8);
        m_serialPort->setParity(QSerialPort::NoParity);
        m_serialPort->setStopBits(QSerialPort::OneStop);
        m_serialPort->setFlowControl(QSerialPort::NoFlowControl);
    }
}

void RobotController::setTcpConnection(const QString &host, int port)
{
    m_hostAddress = host;
    m_port = port;
}

void RobotController::setUdpConnection(const QString &host, int port)
{
    m_hostAddress = host;
    m_port = port;
}

void RobotController::updateRobotStatus()
{
    // 模拟电池电量变化
    static double batteryLevel = 85.0;
    static bool batteryDecreasing = true;
    
    if (m_robotStatus.connected) {
        if (batteryDecreasing) {
            batteryLevel -= 0.01;
            if (batteryLevel <= 20.0) {
                batteryDecreasing = false;
            }
        } else {
            batteryLevel += 0.02;
            if (batteryLevel >= 100.0) {
                batteryDecreasing = true;
            }
        }
        
        m_robotStatus.batteryLevel = batteryLevel;
    }
    
    emit robotStatusUpdated(m_robotStatus);
}

void RobotController::onSerialDataReceived()
{
    if (m_serialPort) {
        QByteArray data = m_serialPort->readAll();
        processReceivedData(data);
    }
}

void RobotController::onTcpDataReceived()
{
    if (m_tcpSocket) {
        QByteArray data = m_tcpSocket->readAll();
        processReceivedData(data);
    }
}

void RobotController::onUdpDataReceived()
{
    if (m_udpSocket) {
        while (m_udpSocket->hasPendingDatagrams()) {
            QByteArray data;
            data.resize(m_udpSocket->pendingDatagramSize());
            m_udpSocket->readDatagram(data.data(), data.size());
            processReceivedData(data);
        }
    }
}

void RobotController::onConnectionError()
{
    QString errorMsg;
    
    if (m_serialPort) {
        errorMsg = QString("串口错误: %1").arg(m_serialPort->errorString());
    } else if (m_tcpSocket) {
        errorMsg = QString("TCP错误: %1").arg(m_tcpSocket->errorString());
    }
    
    m_robotStatus.errorMessage = errorMsg;
    emit errorOccurred(errorMsg);
    
    // 连接断开
    m_robotStatus.connected = false;
    emit connectionStatusChanged(false);
}

void RobotController::sendCommand(const QString &command)
{
    QByteArray data = command.toUtf8() + "\n";
    
    if (m_connectionType == "serial" && m_serialPort && m_serialPort->isOpen()) {
        m_serialPort->write(data);
    }
    else if (m_connectionType == "tcp" && m_tcpSocket && m_tcpSocket->state() == QAbstractSocket::ConnectedState) {
        m_tcpSocket->write(data);
    }
    else if (m_connectionType == "udp" && m_udpSocket) {
        m_udpSocket->writeDatagram(data, QHostAddress(m_hostAddress), m_port);
    }
    
    qDebug() << "发送命令:" << command;
}

void RobotController::processReceivedData(const QByteArray &data)
{
    QString message = QString::fromUtf8(data).trimmed();
    qDebug() << "接收数据:" << message;
    
    // 解析JSON格式的状态数据
    QJsonParseError error;
    QJsonDocument doc = QJsonDocument::fromJson(data, &error);
    
    if (error.error == QJsonParseError::NoError && doc.isObject()) {
        QJsonObject obj = doc.object();
        
        // 更新关节位置
        if (obj.contains("joints")) {
            QJsonArray joints = obj["joints"].toArray();
            for (int i = 0; i < joints.size() && i < TOTAL_JOINTS; ++i) {
                double position = joints[i].toDouble();
                m_robotStatus.jointPositions[i] = position;
                m_jointConfigs[i].currentAngle = position;
            }
        }
        
        // 更新电池电量
        if (obj.contains("battery")) {
            m_robotStatus.batteryLevel = obj["battery"].toDouble();
        }
        
        // 更新错误信息
        if (obj.contains("error")) {
            m_robotStatus.errorMessage = obj["error"].toString();
        }
    }
}

QString RobotController::formatJointCommand(int jointId, double value, const QString &type)
{
    QJsonObject obj;
    obj["command"] = type;
    obj["joint"] = jointId;
    obj["value"] = value;
    obj["timestamp"] = QDateTime::currentMSecsSinceEpoch();
    
    QJsonDocument doc(obj);
    return doc.toJson(QJsonDocument::Compact);
}