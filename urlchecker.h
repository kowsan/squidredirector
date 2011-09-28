#ifndef URLCHECKER_H
#define URLCHECKER_H

#include <QObject>
#include <QtSql>

#include "stdinreader.h"
#include "configreader.h"

class URLChecker : public QObject
{
        Q_OBJECT
    public:
        explicit URLChecker(QObject *parent = 0);
        ConfigReader *reader;
        stdInReader *stdReader;
        void start();

    private:
        QString m_sorryURL;
        bool validateIp(const QString &ipaddr);

    signals:
        void databasePromblem(const QString &problem);

    private slots:
        void processSTDINData(const QByteArray &badata);
        void analyzeSignal(int signal);

    public slots:

};

#endif // URLCHECKER_H
