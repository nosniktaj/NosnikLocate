#ifndef USERMANAGER_H
#define USERMANAGER_H

#include <QObject>
#include <QString>

class NetworkManager;

class UserManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn NOTIFY isLoggedInChanged)
    Q_PROPERTY(QString userId READ userId NOTIFY userDataChanged)
    Q_PROPERTY(QString username READ username NOTIFY userDataChanged)
    Q_PROPERTY(QString displayName READ displayName NOTIFY userDataChanged)
    Q_PROPERTY(QString email READ email NOTIFY userDataChanged)
    Q_PROPERTY(QString avatarUrl READ avatarUrl NOTIFY userDataChanged)
    Q_PROPERTY(QString authToken READ authToken NOTIFY authTokenChanged)

public:
    static UserManager *instance();

    bool isLoggedIn() const;
    QString userId() const;
    QString username() const;
    QString displayName() const;
    QString email() const;
    QString avatarUrl() const;
    QString authToken() const;

    Q_INVOKABLE void login(const QString &username, const QString &password);
    Q_INVOKABLE void registerUser(const QString &username, const QString &email,
                                  const QString &password, const QString &displayName);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void updateProfile(const QString &displayName, const QString &avatarUrl);
    Q_INVOKABLE void changePassword(const QString &oldPassword, const QString &newPassword);
    Q_INVOKABLE void deleteAccount();

signals:
    void isLoggedInChanged();
    void userDataChanged();
    void authTokenChanged();

    void loginSuccess();
    void loginFailed(const QString &reason);
    void registrationSuccess();
    void registrationFailed(const QString &reason);
    void profileUpdated();
    void passwordChanged();
    void passwordChangeFailed(const QString &reason);
    void accountDeleted();
    void accountDeleteFailed(const QString &reason);

private slots:
    void onLoginResponse(bool success, const QJsonObject &data);
    void onRegisterResponse(bool success, const QJsonObject &data);
    void onProfileUpdateResponse(bool success, const QJsonObject &data);
    void onPasswordChangeResponse(bool success, const QString &message);
    void onAccountDeleteResponse(bool success, const QString &message);

private:
    explicit UserManager(QObject *parent = nullptr);
    ~UserManager() override = default;

    void setAuthToken(const QString &token);
    void clearUserData();
    void loadStoredSession();

    bool m_isLoggedIn;
    QString m_userId;
    QString m_username;
    QString m_displayName;
    QString m_email;
    QString m_avatarUrl;
    QString m_authToken;

    static UserManager *s_instance;
};

#endif // USERMANAGER_H
