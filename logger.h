#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QtCore>

class Logger : public QObject
    {
    Q_OBJECT
public:
    enum TypeError {
          Debug,
          Info,
          Error,
          Fatal,
          Warning


          };
    explicit Logger(QObject *parent = 0);
    static void Write(QString message, TypeError te);

    static QString logFilePath();


signals:

public slots:


    };

#endif // LOGGER_H
