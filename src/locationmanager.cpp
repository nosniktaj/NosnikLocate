#include "locationmanager.h"
#include "networkmanager.h"

#include <QGeoPositionInfo>
#include <QGeoCoordinate>
#include <QDebug>

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniObject>
#endif

LocationManager *LocationManager::s_instance = nullptr;

LocationManager *LocationManager::instance()
{
    if (!s_instance) {
        s_instance = new LocationManager();
    }
    return s_instance;
}

LocationManager::LocationManager(QObject *parent)
    : QObject(parent)
    , m_positionSource(nullptr)
    , m_sendTimer(new QTimer(this))
    , m_latitude(0.0)
    , m_longitude(0.0)
    , m_accuracy(0.0)
    , m_isTracking(false)
    , m_updateInterval(30000)
{
    m_positionSource = QGeoPositionInfoSource::createDefaultSource(this);

    if (m_positionSource) {
        m_positionSource->setUpdateInterval(m_updateInterval);

        connect(m_positionSource, &QGeoPositionInfoSource::positionUpdated,
                this, &LocationManager::onPositionUpdated);
        connect(m_positionSource, &QGeoPositionInfoSource::errorOccurred,
                this, &LocationManager::onPositionError);
    } else {
        qWarning() << "LocationManager: No position source available";
    }

    connect(m_sendTimer, &QTimer::timeout, this, &LocationManager::onSendTimerTimeout);
}

double LocationManager::latitude() const
{
    return m_latitude;
}

double LocationManager::longitude() const
{
    return m_longitude;
}

double LocationManager::accuracy() const
{
    return m_accuracy;
}

bool LocationManager::isTracking() const
{
    return m_isTracking;
}

int LocationManager::updateInterval() const
{
    return m_updateInterval;
}

void LocationManager::setUpdateInterval(int interval)
{
    if (m_updateInterval != interval) {
        m_updateInterval = interval;
        if (m_positionSource) {
            m_positionSource->setUpdateInterval(m_updateInterval);
        }
        if (m_sendTimer->isActive()) {
            m_sendTimer->setInterval(m_updateInterval);
        }
        emit updateIntervalChanged();
    }
}

void LocationManager::startTracking()
{
    if (m_isTracking)
        return;

    if (!m_positionSource) {
        emit errorOccurred("No position source available. Check location permissions.");
        return;
    }

    m_positionSource->startUpdates();
    m_sendTimer->start(m_updateInterval);
    m_isTracking = true;
    emit trackingStateChanged(m_isTracking);
}

void LocationManager::stopTracking()
{
    if (!m_isTracking)
        return;

    if (m_positionSource) {
        m_positionSource->stopUpdates();
    }
    m_sendTimer->stop();
    m_isTracking = false;
    emit trackingStateChanged(m_isTracking);
}

void LocationManager::updateLocation()
{
    if (m_positionSource) {
        m_positionSource->requestUpdate(5000);
    } else {
        emit errorOccurred("No position source available.");
    }
}

void LocationManager::requestPermissions()
{
#ifdef Q_OS_ANDROID
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;");

    if (activity.isValid()) {
        QJniObject permissions = QJniObject::fromString("android.permission.ACCESS_FINE_LOCATION");
        QJniObject permArray = QJniObject::callStaticObjectMethod(
            "java/lang/reflect/Array",
            "newInstance",
            "(Ljava/lang/Class;I)Ljava/lang/Object;",
            QJniObject::callStaticObjectMethod("java/lang/String", "class").object<jobject>(),
            1);
        activity.callMethod<void>(
            "requestPermissions",
            "([Ljava/lang/String;I)V",
            permArray.object<jobjectArray>(),
            1);
    }
#endif
    // On iOS, permissions are requested automatically by the system
    // when starting location updates
}

void LocationManager::onPositionUpdated(const QGeoPositionInfo &info)
{
    if (!info.isValid())
        return;

    QGeoCoordinate coord = info.coordinate();
    m_latitude = coord.latitude();
    m_longitude = coord.longitude();
    m_accuracy = info.hasAttribute(QGeoPositionInfo::HorizontalAccuracy)
                     ? info.attribute(QGeoPositionInfo::HorizontalAccuracy)
                     : 0.0;

    emit locationUpdated(m_latitude, m_longitude, m_accuracy);
}

void LocationManager::onPositionError(QGeoPositionInfoSource::Error error)
{
    QString errorMsg;
    switch (error) {
    case QGeoPositionInfoSource::AccessError:
        errorMsg = "Location access denied. Please grant location permissions.";
        break;
    case QGeoPositionInfoSource::ClosedError:
        errorMsg = "Location source closed unexpectedly.";
        break;
    case QGeoPositionInfoSource::NoError:
        return;
    default:
        errorMsg = "Unknown location error occurred.";
        break;
    }
    emit errorOccurred(errorMsg);
}

void LocationManager::onSendTimerTimeout()
{
    if (m_latitude != 0.0 || m_longitude != 0.0) {
        NetworkManager::instance()->sendLocationUpdate(m_latitude, m_longitude, m_accuracy);
    }
}
