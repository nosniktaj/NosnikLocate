#include "usermanager.h"
#include "networkmanager.h"

#include <QSettings>
#include <QJsonObject>

UserManager *UserManager::s_instance = nullptr;

UserManager *UserManager::instance()
{
    if (!s_instance) {
        s_instance = new UserManager();
    }
    return s_instance;
}

UserManager::UserManager(QObject *parent)
    : QObject(parent)
    , m_isLoggedIn(false)
{
    auto *net = NetworkManager::instance();
    connect(net, &NetworkManager::loginResponse, this, &UserManager::onLoginResponse);
    connect(net, &NetworkManager::registerResponse, this, &UserManager::onRegisterResponse);
    connect(net, &NetworkManager::profileUpdateResponse, this, &UserManager::onProfileUpdateResponse);
    connect(net, &NetworkManager::passwordChangeResponse, this, &UserManager::onPasswordChangeResponse);
    connect(net, &NetworkManager::accountDeleteResponse, this, &UserManager::onAccountDeleteResponse);

    loadStoredSession();
}

bool UserManager::isLoggedIn() const
{
    return m_isLoggedIn;
}

QString UserManager::userId() const
{
    return m_userId;
}

QString UserManager::username() const
{
    return m_username;
}

QString UserManager::displayName() const
{
    return m_displayName;
}

QString UserManager::email() const
{
    return m_email;
}

QString UserManager::avatarUrl() const
{
    return m_avatarUrl;
}

QString UserManager::authToken() const
{
    return m_authToken;
}

void UserManager::login(const QString &username, const QString &password)
{

    NetworkManager::instance()->loginRequest(username, password);
}

void UserManager::registerUser(const QString &username, const QString &email,
                               const QString &password, const QString &displayName)
{
    NetworkManager::instance()->registerRequest(username, email, password, displayName);
}

void UserManager::logout()
{
    clearUserData();
    clearStoredSession();
}

void UserManager::updateProfile(const QString &displayName, const QString &avatarUrl)
{
    NetworkManager::instance()->updateProfileRequest(displayName, avatarUrl);
}

void UserManager::changePassword(const QString &oldPassword, const QString &newPassword)
{
    NetworkManager::instance()->changePasswordRequest(oldPassword, newPassword);
}

void UserManager::deleteAccount()
{
    NetworkManager::instance()->deleteAccountRequest();
}

void UserManager::setAuthToken(const QString &token)
{
    if (m_authToken != token) {
        m_authToken = token;
        NetworkManager::instance()->setAuthToken(token);

        QSettings settings;
        settings.setValue("auth/token", token);
        settings.sync();

        emit authTokenChanged();
    }
}

void UserManager::clearUserData()
{
    m_isLoggedIn = false;
    m_userId.clear();
    m_username.clear();
    m_displayName.clear();
    m_email.clear();
    m_avatarUrl.clear();
    m_authToken.clear();

    NetworkManager::instance()->setAuthToken(QString());

    emit isLoggedInChanged();
    emit userDataChanged();
    emit authTokenChanged();
}

void UserManager::loadStoredSession()
{
    QSettings settings;
    QString token = settings.value("auth/token").toString();

    if (!token.isEmpty()) {
        m_authToken = token;
        m_userId = settings.value("auth/userId").toString();
        m_username = settings.value("auth/username").toString();
        m_displayName = settings.value("auth/displayName").toString();
        m_email = settings.value("auth/email").toString();
        m_avatarUrl = settings.value("auth/avatarUrl").toString();
        m_isLoggedIn = true;

        NetworkManager::instance()->setAuthToken(m_authToken);

        emit isLoggedInChanged();
        emit userDataChanged();
        emit authTokenChanged();
    }
}

void UserManager::onLoginResponse(bool success, const QJsonObject &data)
{
    if (success) {
        m_userId = data["userId"].toString();
        m_username = data["username"].toString();
        m_displayName = data["displayName"].toString();
        m_email = data["email"].toString();
        m_avatarUrl = data["avatarUrl"].toString();
        m_isLoggedIn = true;

        setAuthToken(data["token"].toString());

        QSettings settings;
        settings.setValue("auth/userId", m_userId);
        settings.setValue("auth/username", m_username);
        settings.setValue("auth/displayName", m_displayName);
        settings.setValue("auth/email", m_email);
        settings.setValue("auth/avatarUrl", m_avatarUrl);
        settings.sync();

        emit isLoggedInChanged();
        emit userDataChanged();
        emit loginSuccess();
    } else {
        QString reason = data["message"].toString("Login failed");
        emit loginFailed(reason);
    }
}

void UserManager::onRegisterResponse(bool success, const QJsonObject &data)
{
    if (success) {
        emit registrationSuccess();
    } else {
        QString reason = data["message"].toString("Registration failed");
        emit registrationFailed(reason);
    }
}

void UserManager::onProfileUpdateResponse(bool success, const QJsonObject &data)
{
    if (success) {
        if (data.contains("displayName"))
            m_displayName = data["displayName"].toString();
        if (data.contains("avatarUrl"))
            m_avatarUrl = data["avatarUrl"].toString();

        QSettings settings;
        settings.setValue("auth/displayName", m_displayName);
        settings.setValue("auth/avatarUrl", m_avatarUrl);
        settings.sync();

        emit userDataChanged();
        emit profileUpdated();
    }
}

void UserManager::onPasswordChangeResponse(bool success, const QString &message)
{
    if (success) {
        emit passwordChanged();
    } else {
        emit passwordChangeFailed(message);
    }
}

void UserManager::onAccountDeleteResponse(bool success, const QString &message)
{
    if (success) {
        clearUserData();
        clearStoredSession();
        emit accountDeleted();
    } else {
        emit accountDeleteFailed(message);
    }
}

void UserManager::clearStoredSession()
{
    QSettings settings;
    settings.remove("auth/token");
    settings.remove("auth/userId");
    settings.remove("auth/username");
    settings.remove("auth/displayName");
    settings.remove("auth/email");
    settings.remove("auth/avatarUrl");
    settings.sync();
}
