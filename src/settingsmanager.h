#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QString>

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(int updateInterval READ updateInterval WRITE setUpdateInterval NOTIFY updateIntervalChanged)
    Q_PROPERTY(bool shareLocation READ shareLocation WRITE setShareLocation NOTIFY shareLocationChanged)
    Q_PROPERTY(bool showNotifications READ showNotifications WRITE setShowNotifications NOTIFY showNotificationsChanged)
    Q_PROPERTY(QString mapStyle READ mapStyle WRITE setMapStyle NOTIFY mapStyleChanged)
    Q_PROPERTY(QString distanceUnit READ distanceUnit WRITE setDistanceUnit NOTIFY distanceUnitChanged)

public:
    static SettingsManager *instance();

    QString serverUrl() const;
    void setServerUrl(const QString &url);

    int updateInterval() const;
    void setUpdateInterval(int interval);

    bool shareLocation() const;
    void setShareLocation(bool share);

    bool showNotifications() const;
    void setShowNotifications(bool show);

    QString mapStyle() const;
    void setMapStyle(const QString &style);

    QString distanceUnit() const;
    void setDistanceUnit(const QString &unit);

    Q_INVOKABLE void load();
    Q_INVOKABLE void save();
    Q_INVOKABLE void resetToDefaults();

signals:
    void serverUrlChanged();
    void updateIntervalChanged();
    void shareLocationChanged();
    void showNotificationsChanged();
    void mapStyleChanged();
    void distanceUnitChanged();
    void settingsLoaded();
    void settingsSaved();

private:
    explicit SettingsManager(QObject *parent = nullptr);
    ~SettingsManager() override = default;

    QString m_serverUrl;
    int m_updateInterval;
    bool m_shareLocation;
    bool m_showNotifications;
    QString m_mapStyle;
    QString m_distanceUnit;

    static SettingsManager *s_instance;
};

#endif // SETTINGSMANAGER_H
