#include "logger.h"

Logger::Logger(QObject *parent) :
    QObject(parent)
{


}

QString Logger::logFilePath()
{
    QDir appdir(qApp->applicationDirPath ());
    appdir.cdUp ();
    appdir.cd("etc/");
    QSettings sets(appdir.path ()+"/squidredirector.ini",QSettings::IniFormat);
    return sets.value("logging/file","application.log").toString();
}

void Logger::Write(QString message, TypeError te)
{
    message=message.simplified ();
    QString prefix;
    prefix=QDateTime::currentDateTime ().toString ("yyyy-MM-dd hh:mm:ss")+" ["+QString::number (qApp->applicationPid ())+"]";
    switch (te)
        {
        case Error:
            prefix.append ("\tERROR\t");
            break;
        case Warning:
            prefix.append ("\tWARNING\t");
            break;
        case Info:
            prefix.append ("\tINFO\t");
            break;
        case Debug:
            prefix.append ("\tDEBUG\t");
            break;
        case Fatal:
            prefix.append ("\tFATAL\t");
            break;

        }
    QFile f;

    message=prefix+message+"\n";
    f.setFileName (logFilePath ());
    if (f.open (QIODevice::Append))
        {
            f.write (message.toAscii ());
            f.flush ();
            f.close ();
        }
    else
        {
            qDebug ()<<f.errorString ();
        }
}
