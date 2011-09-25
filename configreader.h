#ifndef CONFIGREADER_H
#define CONFIGREADER_H

#include <QObject>
#include <QSettings>

class ConfigReader : public QObject
{
        Q_OBJECT
    public:
        explicit ConfigReader(QObject *parent = 0);
        void init(const QString &path);
        QString databaseHost();
        qint16 databasePort();
        QString databaseUser();
        QString databasePassword();
        QString databaseName();
        QString sorryURL();
    private:
        QSettings *sets;
    signals:

    public slots:

};

#endif // CONFIGREADER_H
