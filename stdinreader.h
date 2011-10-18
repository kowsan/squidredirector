#include <QtCore>
#include <QThread> 
#include <QFile> 

class stdInReader : public QThread
 {
 Q_OBJECT

 public:
	stdInReader(QObject * parent = 0);

	int init();//opend threads and became ready to work. 
	/*
	      return 
		1 if some errors was happened
		0 of all ok
		-1 if can`t oopen stdIn
		-2 if can`t oopen stdOut
		-3 if can`t oopen stdErr
	*/
	void run();
 signals:
        void stdinReadyRead(const QByteArray &data);

 public slots:
        int writetoStdOut(const QByteArray &_data);
        int writetoStdErr(const QByteArray &_data);
 private: 
	QFile stdIn;
	QFile stdOut;
	QFile stdErr;
	QByteArray data;
	bool inited;

 };
