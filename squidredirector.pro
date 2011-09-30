#-------------------------------------------------
#
# Project created by QtCreator 2011-09-16T15:49:19
#
#-------------------------------------------------

QT       += core sql

QT       -= gui

#установка конфигурации
config.files = etc/squidredirector.ini
config.path = /opt/petrosoft/squidredirector/etc
INSTALLS+= config

bin.files = bin/squidredirector
bin.path = /opt/petrosoft/squidredirector/bin

INSTALLS+= bin

TARGET = bin/squidredirector
CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = app


SOURCES += main.cpp \
    urlchecker.cpp \
    stdinreader.cpp \
    configreader.cpp \
    logger.cpp

HEADERS += \
    urlchecker.h \
    stdinreader.h \
    configreader.h \
    logger.h

OTHER_FILES += \
    etc/squidredirector.ini \
    sql/database.sql \
    var/pay.php \
    README















