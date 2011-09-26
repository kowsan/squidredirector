#include <QDebug>
#include "urlchecker.h"
#include "logger.h"
#include <QMap>

URLChecker::URLChecker(QObject *parent) :
    QObject(parent)
{
    stdReader = new stdInReader(this);
    stdReader->start (QThread::HighestPriority);
    qint64 r= stdReader->init ();
    Logger::Write ("STDIN reader start with code : "+QString::number (r),Logger::Debug);
    connect (stdReader,SIGNAL(stdinReadyRead(QByteArray)),this,SLOT(processSTDINData(QByteArray)));
    //connect ()
}
void URLChecker::start()
{
    Logger::Write ("Available sql drivers "+QSqlDatabase::drivers ().join (" "),Logger::Debug);
    QSqlDatabase db=QSqlDatabase::addDatabase ("QPSQL");
    QDir appdir(qApp->applicationDirPath ());
    appdir.cdUp ();
    appdir.cd("etc/");
    //qDebug ()<<"now directory : "<<appdir.path ();
    reader = new ConfigReader(0);
    reader->init (appdir.path ()+"/squidredirector.ini");

    db.setHostName (reader->databaseHost ());
    db.setPort (reader->databasePort ());
    db.setUserName (reader->databaseUser ());
    db.setPassword (reader->databasePassword ());
    db.setDatabaseName (reader->databaseName ());

    if (db.open ())
        {
            Logger::Write ("Database open OK",Logger::Info);

        }
    else
        {
            Logger::Write ("Error on connect to database : "+db.lastError ().text (),Logger::Fatal);
            //qDebug ()<<db.lastError ().text ();
        }



}

void URLChecker::processSTDINData(const QByteArray &badata)
{
    QSqlDatabase db= QSqlDatabase::database ();

    QString indata(badata);
    Logger::Write ("Incomming data '"+indata+"'",Logger::Debug);
    QStringList incomming=indata.split (" ");
    /*
        if (incomming.size ()!=4)
            {
                Logger::Write ("Incomming data not a squid  format '"+indata+"'",Logger::Error);
                stdReader->writetoStdOut (badata);
                return;

            }
            */
    QString url = incomming.at (0).trimmed ();
    QString ip = incomming.at (1);
    //  QString ident = incomming.at (2);
    //  QString met = incomming.at (3);
    ip=ip.remove ("/-",Qt::CaseInsensitive);

    if (db.open ())
        {
            QSqlQuery selQuery;
            selQuery.prepare ("select canaccesstourl(:ip,:url)");
            selQuery.bindValue (":ip",ip);
            selQuery.bindValue (":url",url);

            if (!selQuery.exec ())
                {
                    Logger::Write ("Db error "+selQuery.lastError ().text (),Logger::Error);
                    emit databasePromblem (selQuery.lastError ().text ());
                    QString  result=url+"\n";
                    stdReader->writetoStdOut (result.toAscii ());
                    return;
                }
            else {
                    while (selQuery.next ())
                        {
                            url=selQuery.value (0).toString ();
                        }
                    QString  result=url+"\n";
                    Logger::Write("Returning result'"+result+"'",Logger::Debug);
                    stdReader->writetoStdOut (result.toAscii ());
                }
        }
    else
        {
            url=reader->sorryURL ();
            QString  result=url+"\n";
            stdReader->writetoStdOut (result.toAscii ());

        }
}



