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

        //  bool checkForBlackURL(const QString &url);
        ConfigReader *reader;
        stdInReader *stdReader;

        void start();

        bool validateIp(const QString &ipaddr);
    private:
        QString m_sorryURL;
    signals:
        void databasePromblem(const QString &problem);

    private slots:
        void processSTDINData(const QByteArray &badata);
        void analyzeSignal(int signal);

    public slots:

};

#endif // URLCHECKER_H
