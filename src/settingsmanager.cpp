#include "settingsmanager.h"

#include <QSettings>

SettingsManager *SettingsManager::s_instance = nullptr;

SettingsManager *SettingsManager::instance()
{
    if (!s_instance) {
        s_instance = new SettingsManager();
    }
    return s_instance;
}

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_serverUrl("https://tagdb.nosniktaj.com")
    , m_updateInterval(30000)
    , m_shareLocation(true)
    , m_showNotifications(true)
    , m_mapStyle("street")
    , m_distanceUnit("km")
{
    load();
}

QString SettingsManager::serverUrl() const
{
    return m_serverUrl;
}

void SettingsManager::setServerUrl(const QString &url)
{
    if (m_serverUrl != url) {
        m_serverUrl = url;
        save();
        emit serverUrlChanged();
    }
}

int SettingsManager::updateInterval() const
{
    return m_updateInterval;
}

void SettingsManager::setUpdateInterval(int interval)
{
    if (m_updateInterval != interval) {
        m_updateInterval = interval;
        save();
        emit updateIntervalChanged();
    }
}

bool SettingsManager::shareLocation() const
{
    return m_shareLocation;
}

void SettingsManager::setShareLocation(bool share)
{
    if (m_shareLocation != share) {
        m_shareLocation = share;
        save();
        emit shareLocationChanged();
    }
}

bool SettingsManager::showNotifications() const
{
    return m_showNotifications;
}

void SettingsManager::setShowNotifications(bool show)
{
    if (m_showNotifications != show) {
        m_showNotifications = show;
        save();
        emit showNotificationsChanged();
    }
}

QString SettingsManager::mapStyle() const
{
    return m_mapStyle;
}

void SettingsManager::setMapStyle(const QString &style)
{
    if (m_mapStyle != style) {
        m_mapStyle = style;
        save();
        emit mapStyleChanged();
    }
}

QString SettingsManager::distanceUnit() const
{
    return m_distanceUnit;
}

void SettingsManager::setDistanceUnit(const QString &unit)
{
    if (m_distanceUnit != unit) {
        m_distanceUnit = unit;
        save();
        emit distanceUnitChanged();
    }
}

void SettingsManager::load()
{
    QSettings settings;
    settings.beginGroup("Settings");

    m_serverUrl = settings.value("serverUrl", "https://tagdb.nosniktaj.com").toString();
    m_updateInterval = settings.value("updateInterval", 30000).toInt();
    m_shareLocation = settings.value("shareLocation", true).toBool();
    m_showNotifications = settings.value("showNotifications", true).toBool();
    m_mapStyle = settings.value("mapStyle", "street").toString();
    m_distanceUnit = settings.value("distanceUnit", "km").toString();

    settings.endGroup();
    emit settingsLoaded();
}

void SettingsManager::save()
{
    QSettings settings;
    settings.beginGroup("Settings");

    settings.setValue("serverUrl", m_serverUrl);
    settings.setValue("updateInterval", m_updateInterval);
    settings.setValue("shareLocation", m_shareLocation);
    settings.setValue("showNotifications", m_showNotifications);
    settings.setValue("mapStyle", m_mapStyle);
    settings.setValue("distanceUnit", m_distanceUnit);

    settings.endGroup();
    settings.sync();
    emit settingsSaved();
}

void SettingsManager::resetToDefaults()
{
    setServerUrl("https://tagdb.nosniktaj.com");
    setUpdateInterval(30000);
    setShareLocation(true);
    setShowNotifications(true);
    setMapStyle("street");
    setDistanceUnit("km");
}
