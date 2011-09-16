#include <QtCore/QCoreApplication>
#include "urlchecker.h"
int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);
    URLChecker u;
    return a.exec();
}
