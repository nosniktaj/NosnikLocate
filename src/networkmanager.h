#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QString>

class NetworkManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString serverUrl READ serverUrl WRITE setServerUrl NOTIFY serverUrlChanged)
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY isConnectedChanged)

public:
    static NetworkManager *instance();

    QString serverUrl() const;
    void setServerUrl(const QString &url);

    bool isConnected() const;

    void setAuthToken(const QString &token);
    QString authToken() const;

    // Generic HTTP methods
    Q_INVOKABLE void get(const QString &endpoint);
    Q_INVOKABLE void post(const QString &endpoint, const QJsonObject &data);
    Q_INVOKABLE void put(const QString &endpoint, const QJsonObject &data);
    Q_INVOKABLE void deleteResource(const QString &endpoint);

    // API-specific methods
    Q_INVOKABLE void sendLocationUpdate(double latitude, double longitude, double accuracy);
    Q_INVOKABLE void fetchFriendLocations();

    Q_INVOKABLE void loginRequest(const QString &username, const QString &password);
    Q_INVOKABLE void registerRequest(const QString &username, const QString &email,
                                     const QString &password, const QString &displayName);
    Q_INVOKABLE void updateProfileRequest(const QString &displayName, const QString &avatarUrl);
    Q_INVOKABLE void changePasswordRequest(const QString &oldPassword, const QString &newPassword);
    Q_INVOKABLE void deleteAccountRequest();

    Q_INVOKABLE void fetchFriends();
    Q_INVOKABLE void fetchPendingRequests();
    Q_INVOKABLE void addFriendRequest(const QString &username);
    Q_INVOKABLE void removeFriendRequest(const QString &friendId);
    Q_INVOKABLE void acceptFriendRequest(const QString &requestId);
    Q_INVOKABLE void rejectFriendRequest(const QString &requestId);

    Q_INVOKABLE void verifyEmailRequest(const QString &username, const QString &code);
    Q_INVOKABLE void resendVerificationRequest(const QString &username);

signals:
    void serverUrlChanged();
    void isConnectedChanged();

    void requestFinished(const QString &endpoint, const QJsonDocument &response);
    void requestError(const QString &endpoint, const QString &error);

    void loginResponse(bool success, const QJsonObject &data);
    void registerResponse(bool success, const QJsonObject &data);
    void profileUpdateResponse(bool success, const QJsonObject &data);
    void passwordChangeResponse(bool success, const QString &message);
    void accountDeleteResponse(bool success, const QString &message);

    void locationUpdateResponse(bool success);
    void friendLocationsReceived(const QJsonArray &locations);

    void friendsListReceived(const QJsonArray &friends);
    void pendingRequestsReceived(const QJsonArray &requests);
    void friendAddResponse(bool success, const QString &message);
    void friendRemoveResponse(bool success, const QString &message);
    void friendRequestResponse(bool success, const QString &message);

    void emailVerificationResponse(bool success, const QString &message);
    void resendVerificationResponse(bool success, const QString &message);

private:
    explicit NetworkManager(QObject *parent = nullptr);
    ~NetworkManager() override = default;

    QNetworkRequest createRequest(const QString &endpoint) const;
    void handleReply(QNetworkReply *reply,
                     const std::function<void(const QJsonDocument &)> &onSuccess,
                     const std::function<void(const QString &)> &onError);

    QNetworkAccessManager *m_networkManager;
    QString m_serverUrl;
    QString m_authToken;
    bool m_isConnected;

    static NetworkManager *s_instance;
};

#endif // NETWORKMANAGER_H
