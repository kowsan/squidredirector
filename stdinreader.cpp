
#include "stdinreader.h"

stdInReader::stdInReader(QObject * parent)
    : QThread (parent)
{
    inited=false;
}

int stdInReader::init()
{
    inited=false;
    if (! stdIn.open(stdin, QIODevice::ReadOnly)) return -1;
    if (! stdOut.open(stdout, QIODevice::WriteOnly)) return -2;
    if (! stdErr.open(stdout, QIODevice::WriteOnly)) return -3;
    inited=true;
    return 0;
};

//-----------------------------------------------------
void stdInReader::run()
{

    if (!inited) return;
    while (true)
        {
            /* while (stdIn.bytesAvailable()==0) //<------- ВНИМАНИЕ! так - НЕ работает... да) QT 4.5
                                            //почему-то пока не начнешь читать, размер буфера не обновится...
                this->msleep(1000);
     */
            data=stdIn.read(1); //тут "блокирующее чтение"... потому никаких sleep не надо
            if (stdIn.bytesAvailable()>0)
                data.append(stdIn.read(stdIn.bytesAvailable()));//и только тут буфер покажет сколько нам послупило данных. лол)
            emit stdinReadyRead(data);

            /*
        ////------ далее - демо код для примера ----------
        //// что бы оно заработало - надо stdOut.open... раскомментировать выше...
                stdOut.write(QByteArray().append(QString("[")));
                stdOut.write(data);
                stdOut.write(QByteArray().append(QString("]")));
                stdOut.flush();//отправим сразу...
       */
        };
    return;
}

//-----------------------------------------------------
int stdInReader::writetoStdOut(const QByteArray &_data)
{
    int rz=stdOut.write(_data);
    stdOut.flush();
    return rz;
}

//-----------------------------------------------------
int stdInReader::writetoStdErr(const QByteArray &_data)
{
    int rz=stdErr.write(_data);
    stdErr.flush();
    return rz;
}
