QT += core widgets network serialport opengl

CONFIG += c++17

TARGET = robot_control_gui
TEMPLATE = app

SOURCES += \
    main.cpp \
    mainwindow.cpp \
    robotcontroller.cpp \
    jointcontrolwidget.cpp

HEADERS += \
    mainwindow.h \
    robotcontroller.h \
    jointcontrolwidget.h

FORMS += \
    mainwindow.ui