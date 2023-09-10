#include "core.h"
#include <QFile>
#include <QStringList>
#include <QVariantMap>
#include <QProcess>
#include <QDesktopServices>
#include <QUrl>
#include <QDebug>

Core::Core(QObject *parent) : QObject(parent), internetSettings("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", QSettings::NativeFormat)
{
    serverList = settings.value("servers").toList();
    timeSpan = settings.value("timeSpan").toUInt();
    timer.setInterval(timeSpan*1000*60);
    setServerIndex(-1);
    setRunning(false);
    QObject::connect(&timer, &QTimer::timeout, this, &Core::onTimeout);
}

Core::~Core()
{

}

void Core::updateServerList(QString path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << file.errorString();
        emit error("Unable to open file!");
    }

    this->serverList.clear();
    QStringList wordList;
    while (!file.atEnd()) {
        QByteArray line = file.readLine();
        wordList = ((QString)line).split(',');
        if(wordList.count() < 3)
            continue;


        QString name = wordList[0];
        QString ip = wordList[1];
        quint32 port = wordList[2].toUInt();
        QString override = "";

        if(wordList.count() > 3)
            override = wordList[3];

        QVariantMap serverMap;

        serverMap["name"] = name;
        serverMap["ip"] = ip;
        serverMap["port"] = port;
        serverMap["override"] = override;
        this->serverList.append(serverMap);
    }

    settings.setValue("servers", serverList);
    emit serverListChanged(serverList);
}

void Core::connectServer()
{
    if(serverList.count() < 1)
    {
        emit error("No Proxy servers available!");
        return;
    }
    setServerIndex(0);
    setRunning(true);
    startProxyServer(serverIndex);
}

void Core::disconnectServer()
{
    stopProxyServer();
    setServerIndex(-1);
    setRunning(false);
}

QVariantList Core::getServerList() const
{
    return serverList;
}

quint32 Core::getTimeSpan() const
{
    return timeSpan;
}

void Core::setTimeSpan(quint32 newTimeSpan)
{
    if (timeSpan == newTimeSpan)
        return;
    timeSpan = newTimeSpan;
    settings.setValue("timeSpan", timeSpan);
    timer.setInterval(timeSpan*1000*60);
    emit timeSpanChanged(timeSpan);
}

void Core::onTimeout()
{
    if(running)
    {
        setServerIndex(serverIndex + 1);
        if(serverIndex >= serverList.count())
        {
            setServerIndex(0);
        }
        startProxyServer(serverIndex);
    }
}

int Core::getServerIndex() const
{
    return serverIndex;
}

void Core::setServerIndex(int newServerIndex)
{
    if (serverIndex == newServerIndex)
        return;
    serverIndex = newServerIndex;
    emit serverIndexChanged(serverIndex);
}

void Core::startProxyServer(quint32 index)
{
    QVariantMap serverMap = serverList[index].toMap();
    internetSettings.setValue("ProxyEnable", 1);
    internetSettings.setValue("ProxyServer", serverMap["ip"].toString() + ":" + QString::number(serverMap["port"].toUInt()));
    internetSettings.setValue("ProxyOverride", serverMap["override"].toString());
    internetSettings.sync();

    refreshProxy();
    emit status("Connected to " + internetSettings.value("ProxyServer").toString());
}

void Core::stopProxyServer()
{
    internetSettings.setValue("ProxyEnable", 0);
    internetSettings.sync();
    refreshProxy();
    emit status("Disconnected");
}

void Core::refreshProxy()
{
    QProcess::execute("proxy.bat" , QStringList());
}

bool Core::getRunning() const
{
    return running;
}

void Core::setRunning(bool newRunning)
{
    if(running == newRunning)
        return;

    running = newRunning;

    if(running)
        timer.start();
    else
        timer.stop();

    emit runningChanged(running);
}
