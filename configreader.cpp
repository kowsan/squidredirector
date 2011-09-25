#include "configreader.h"

ConfigReader::ConfigReader(QObject *parent) :
    QObject(parent)
{

}

void ConfigReader::init(const QString &path)
{
    sets= new QSettings(path,QSettings::IniFormat);
}
QString ConfigReader::databaseHost()
{
    return sets->value ("database/host","127.0.0.1").toString ();

}

qint16 ConfigReader::databasePort()
{
    return sets->value ("database/port",5432).toInt ();

}

QString ConfigReader::databaseUser()
{
    return sets->value ("database/user","user").toString ();

}
QString ConfigReader::databasePassword()
{
    return sets->value ("database/password","password").toString ();

}
QString ConfigReader::databaseName()
{
    return sets->value ("database/name","db").toString ();

}
QString ConfigReader::sorryURL()
{
    return sets->value ("main/sorryurl","http://localhost").toString ();

}
