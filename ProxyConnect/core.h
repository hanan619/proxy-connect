#ifndef CORE_H
#define CORE_H

#include <QObject>
#include <QVariantList>
#include <QSettings>
#include <QTimer>

class Core : public QObject
{
    Q_OBJECT
    Q_PROPERTY(quint32 timeSpan READ getTimeSpan WRITE setTimeSpan NOTIFY timeSpanChanged)
    Q_PROPERTY(QVariantList serverList READ getServerList NOTIFY serverListChanged)
    Q_PROPERTY(bool running READ getRunning NOTIFY runningChanged)
    Q_PROPERTY(int serverIndex READ getServerIndex WRITE setServerIndex NOTIFY serverIndexChanged)

public:
    explicit Core(QObject *parent = nullptr);
    ~Core();
    Q_INVOKABLE void updateServerList(QString path);
    Q_INVOKABLE void connectServer();
    Q_INVOKABLE void disconnectServer();

    QVariantList getServerList() const;

    quint32 getTimeSpan() const;
    void setTimeSpan(quint32 newTimeSpan);

    bool getRunning() const;
    void setRunning(bool newRunning);

    int getServerIndex() const;
    void setServerIndex(int newServerIndex);

private slots:
    void onTimeout();

signals:
    void timeSpanChanged(quint32 timeSpan);
    void serverListChanged(QVariantList& serverList);
    void runningChanged(bool running);
    void serverIndexChanged(int serverIndex);
    void error(QString err);
    void status(QString state);

private:
    QSettings    settings;
    QSettings    internetSettings;
    quint32      timeSpan;
    QVariantList serverList;
    QTimer       timer;
    bool         running;
    int          serverIndex;

    void startProxyServer(quint32 index);
    void stopProxyServer();
    void refreshProxy();
};

#endif // CORE_H
