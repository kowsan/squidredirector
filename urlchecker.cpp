#include "urlchecker.h"
#include <QDebug>

URLChecker::URLChecker(QObject *parent) :
    QObject(parent)
{
    qDebug ()<<"available sql drivers"<<QSqlDatabase::drivers ();
    QSqlDatabase db=QSqlDatabase::addDatabase ("QPSQL");

    db.setHostName ("127.0.0.1");
    db.setPort (5432);
    db.setUserName ("tarif");
    db.setPassword ("tarif");

    qDebug ()<<this->checkForBlackURL ("http://kavkazcenter.com");
    return;
    if (db.open ())
        {
            qDebug ()<<"db opened";
        }
    else
        {
            qDebug ()<<db.lastError ();
        }


}

bool URLChecker::checkForBlackURL(const QString &url)
{
    QSqlDatabase d=QSqlDatabase::database ();
    if (d.open ())
        {
            QSqlQuery q;
            q.prepare ("select isblackdomain2(:url)");
            q.bindValue (":url",url);
            if (!q.exec ())
                {

                    emit databasePromblem (q.lastError ().text ());
                    qDebug ()<<q.lastError ().text ();
                }
            else
                {
                    while (q.next ())
                        {
                            return q.value (0).toBool ();

                        }
                }
        }
    else
        {
            qDebug ()<<d.lastError ();
            emit databasePromblem (d.lastError ().text ());
        }
    return true;
}
