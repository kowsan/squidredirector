#ifndef URLCHECKER_H
#define URLCHECKER_H

#include <QObject>
#include <QtSql>
class URLChecker : public QObject
{
        Q_OBJECT
    public:
        explicit URLChecker(QObject *parent = 0);
        bool isWhite;
        bool isBlack;
        bool checkForBlackURL(const QString &url);
    signals:
        void databasePromblem(const QString &problem);
private:


    public slots:

};

#endif // URLCHECKER_H
