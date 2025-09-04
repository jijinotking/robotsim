#ifndef ROBOTCONTROLLER_H
#define ROBOTCONTROLLER_H

#include <QObject>
#include <QTimer>
#include <QSerialPort>
#include <QTcpSocket>
#include <QUdpSocket>
#include <QVector>

// 机器人关节配置
struct JointConfig {
    int id;
    QString name;
    double minAngle;
    double maxAngle;
    double currentAngle;
    bool enabled;
    
    JointConfig(int jointId = 0, const QString &jointName = "", 
                double min = -180.0, double max = 180.0)
        : id(jointId), name(jointName), minAngle(min), maxAngle(max)
        , currentAngle(0.0), enabled(false) {}
};

// 机器人状态
struct RobotStatus {
    bool connected;
    bool emergencyStop;
    double batteryLevel;
    QString errorMessage;
    QVector<double> jointPositions;
    QVector<double> jointVelocities;
    QVector<double> jointTorques;
    
    RobotStatus() : connected(false), emergencyStop(false), batteryLevel(0.0) {}
};

class RobotController : public QObject
{
    Q_OBJECT

public:
    explicit RobotController(QObject *parent = nullptr);
    ~RobotController();
    
    // 连接控制
    bool connectToRobot();
    void disconnectFromRobot();
    bool isConnected() const;
    
    // 关节控制
    void setJointPosition(int jointId, double angle);
    void setJointVelocity(int jointId, double velocity);
    void setJointTorque(int jointId, double torque);
    double getJointPosition(int jointId) const;
    
    // 机器人控制
    void emergencyStop();
    void resetToZeroPosition();
    void enableAllJoints();
    void disableAllJoints();
    void enableJoint(int jointId);
    void disableJoint(int jointId);
    
    // 状态获取
    RobotStatus getRobotStatus() const;
    JointConfig getJointConfig(int jointId) const;
    
    // 配置
    void setConnectionType(const QString &type); // "serial", "tcp", "udp"
    void setSerialPort(const QString &portName, int baudRate = 115200);
    void setTcpConnection(const QString &host, int port);
    void setUdpConnection(const QString &host, int port);

signals:
    void connectionStatusChanged(bool connected);
    void robotStatusUpdated(const RobotStatus &status);
    void jointPositionChanged(int jointId, double position);
    void errorOccurred(const QString &error);

private slots:
    void updateRobotStatus();
    void onSerialDataReceived();
    void onTcpDataReceived();
    void onUdpDataReceived();
    void onConnectionError();

private:
    void initializeJoints();
    void sendCommand(const QString &command);
    void processReceivedData(const QByteArray &data);
    QString formatJointCommand(int jointId, double value, const QString &type = "position");
    
    // 连接相关
    QString m_connectionType;
    QSerialPort *m_serialPort;
    QTcpSocket *m_tcpSocket;
    QUdpSocket *m_udpSocket;
    QString m_hostAddress;
    int m_port;
    
    // 机器人状态
    RobotStatus m_robotStatus;
    QVector<JointConfig> m_jointConfigs;
    QTimer *m_statusTimer;
    
    // 常量
    static const int TOTAL_JOINTS = 21; // 左臂8 + 右臂8 + 腰部2 + 底盘2 + 升降1
};

#endif // ROBOTCONTROLLER_H