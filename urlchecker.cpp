#include <QDebug>
#include "urlchecker.h"
#include "logger.h"


URLChecker::URLChecker(QObject *parent) :
    QObject(parent)
{
    stdReader = new stdInReader(this);
    stdReader->start (QThread::HighestPriority);
    qint8 r= stdReader->init ();
    Logger::Write ("STDIN reader start with code : "+QString::number (r),Logger::Debug);
    connect (stdReader,SIGNAL(stdinReadyRead(QByteArray)),this,SLOT(processSTDINData(QByteArray)));
    //скорей всего не работает
    connect (qApp,SIGNAL(unixSignal(int)),this,SLOT(analyzeSignal(int)),Qt::DirectConnection);


}
void URLChecker::analyzeSignal(int signal)
{
    Logger::Write ("Process  squid signal ["+QString::number (signal)+"]",Logger::Debug);


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
    m_sorryURL=reader->sorryURL ();

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
bool URLChecker::validateIp(const QString &ipaddr)
{
    QRegExp rx("\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}");

    if (rx.indexIn (ipaddr)>-1)
        {
            return true;
        }

    return false;
}

void URLChecker::processSTDINData(const QByteArray &badata)
{
    QTime t;
    t.start ();
    QString _indata(badata);
    Logger::Write ("Incomming data '"+_indata+"'",Logger::Debug);
    QStringList incomming=_indata.split (" ");
    if (incomming.size ()<2)
        {
            //если чтото не так со входным массивом
            return;
        }
    QString _url = incomming.at (0).trimmed ();
    QString _ip = incomming.at (1).trimmed ();
    //  QString ident = incomming.at (2);
    //  QString met = incomming.at (3);
    _ip=_ip.remove ("/-",Qt::CaseInsensitive);
    //проверяем ip
    if (!this->validateIp (_ip))
        {
            //если ip не поддается проверке не делаем запрос к  СУБД
            Logger::Write ("Invalid ip address specified '"+_ip+"'",Logger::Error);
            return;
        }

    /*
    здесь может тратится много времени на открытие соединения к СУБД
    однако не будет проблем в случае недоступности  СУБД - редиректор сразу подцепится к база
    */

    QSqlDatabase db= QSqlDatabase::database ();
    if (db.open ())
        {
            QSqlQuery _selQuery;
            _selQuery.prepare ("select canaccesstourl(:ip,:url)");
            _selQuery.bindValue (":ip",_ip);
            _selQuery.bindValue (":url",_url);

            if (!_selQuery.exec ())
                {
                    //если проблемы в базе или при выполнеии функции
                    Logger::Write ("Db error "+_selQuery.lastError ().text (),Logger::Error);
                    emit databasePromblem (_selQuery.lastError ().text ());
                    QString  _result=m_sorryURL+"\n";
                    stdReader->writetoStdOut (_result.toAscii ());
                    return;
                }
            else {
                    while (_selQuery.next ())
                        {

                            _url=_selQuery.value (0).toString ();
                        }
                    //когда все хорошо
                    QString  _result=_url+"\n";
                    Logger::Write("Returning result '"+_result+"' ",Logger::Debug);
                    stdReader->writetoStdOut (_result.toAscii ());
                }
        }
    else
        {
            //переделан механизм чтобы постоянно не перечитывать файл конфига
            _url = m_sorryURL;
            QString  _result=_url+"\n";
            Logger::Write ("Cannot open database  '"+db.lastError ().text ()+
                           "' . Sending sorry url to client '"+m_sorryURL+"'",Logger::Error);
            stdReader->writetoStdOut (_result.toAscii ());

        }

    int et=t.elapsed ();
    Logger::Write ("Processing data from time'"+QString::number (et)+"' - millisecond",Logger::Debug);
}



