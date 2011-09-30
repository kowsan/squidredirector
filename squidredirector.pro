#-------------------------------------------------
#
# Project created by QtCreator 2011-09-16T15:49:19
#
#-------------------------------------------------

QT       += core sql

QT       -= gui
#sql скрипты
sql.files=sql/01.sql sql/02.sql sql/03.sql
sql.path=/opt/petrosoft/squidredirector/sql
INSTALLS+= sql

#файл readme
readme.files = README
readme.path = /opt/petrosoft/squidredirector
INSTALLS+=readme

#установка конфигурации
config.files = etc/squidredirector.ini
config.path = /opt/petrosoft/squidredirector/etc
INSTALLS+= config

#исполняемые файлы редиректора
bin.files = bin/squidredirector
bin.path = /opt/petrosoft/squidredirector/bin
INSTALLS+= bin

#установка файлов для веб сервера
var.files = var/pay.php var/sorry.php
var.path = /opt/petrosoft/squidredirector/var
INSTALLS+= var


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
    var/pay.php \
    README \
    sql/01.sql \
    sql/02.sql \
    var/sorry.html \
    deb/description-pak \
    description-pak \
    builddeb.sh





















unix:!symbian:!maemo5:isEmpty(MEEGO_VERSION_MAJOR) {
    target.path = /opt/squidredirector/bin
    INSTALLS += target
}




