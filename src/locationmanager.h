#ifndef LOCATIONMANAGER_H
#define LOCATIONMANAGER_H

#include <QObject>
#include <QGeoPositionInfoSource>
#include <QGeoPositionInfo>
#include <QTimer>

class NetworkManager;

class LocationManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double latitude READ latitude NOTIFY locationUpdated)
    Q_PROPERTY(double longitude READ longitude NOTIFY locationUpdated)
    Q_PROPERTY(double accuracy READ accuracy NOTIFY locationUpdated)
    Q_PROPERTY(bool isTracking READ isTracking NOTIFY trackingStateChanged)
    Q_PROPERTY(int updateInterval READ updateInterval WRITE setUpdateInterval NOTIFY updateIntervalChanged)

public:
    static LocationManager *instance();

    double latitude() const;
    double longitude() const;
    double accuracy() const;
    bool isTracking() const;

    int updateInterval() const;
    void setUpdateInterval(int interval);

    Q_INVOKABLE void startTracking();
    Q_INVOKABLE void stopTracking();
    Q_INVOKABLE void updateLocation();
    Q_INVOKABLE void requestPermissions();

signals:
    void locationUpdated(double latitude, double longitude, double accuracy);
    void trackingStateChanged(bool isTracking);
    void updateIntervalChanged();
    void errorOccurred(const QString &error);

private slots:
    void onPositionUpdated(const QGeoPositionInfo &info);
    void onPositionError(QGeoPositionInfoSource::Error error);
    void onSendTimerTimeout();

private:
    explicit LocationManager(QObject *parent = nullptr);
    ~LocationManager() override = default;

    QGeoPositionInfoSource *m_positionSource;
    QTimer *m_sendTimer;
    double m_latitude;
    double m_longitude;
    double m_accuracy;
    bool m_isTracking;
    int m_updateInterval;

    static LocationManager *s_instance;
};

#endif // LOCATIONMANAGER_H
