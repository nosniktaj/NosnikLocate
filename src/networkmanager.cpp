#include "networkmanager.h"

#include <QSettings>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

NetworkManager *NetworkManager::s_instance = nullptr;

NetworkManager *NetworkManager::instance()
{
    if (!s_instance) {
        s_instance = new NetworkManager();
    }
    return s_instance;
}

NetworkManager::NetworkManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_isConnected(false)
{
    QSettings settings;
    m_serverUrl = settings.value("serverUrl", "https://tagdb.nosniktaj.com").toString();

    connect(m_networkManager, &QNetworkAccessManager::finished, this, [this](QNetworkReply *reply) {
        bool connected = (reply->error() == QNetworkReply::NoError);
        if (connected != m_isConnected) {
            m_isConnected = connected;
            emit isConnectedChanged();
        }
    });
}

QString NetworkManager::serverUrl() const
{
    return m_serverUrl;
}

void NetworkManager::setServerUrl(const QString &url)
{
    if (m_serverUrl != url) {
        m_serverUrl = url;
        QSettings settings;
        settings.setValue("serverUrl", m_serverUrl);
        emit serverUrlChanged();
    }
}

bool NetworkManager::isConnected() const
{
    return m_isConnected;
}

void NetworkManager::setAuthToken(const QString &token)
{
    m_authToken = token;
}

QString NetworkManager::authToken() const
{
    return m_authToken;
}

QNetworkRequest NetworkManager::createRequest(const QString &endpoint) const
{
    QUrl url(m_serverUrl + endpoint);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_authToken.isEmpty()) {
        request.setRawHeader("Authorization", ("Bearer " + m_authToken).toUtf8());
    }
    return request;
}

void NetworkManager::handleReply(QNetworkReply *reply,
                                 std::function<void(const QJsonDocument &)> onSuccess,
                                 std::function<void(const QString &)> onError)
{
    connect(reply, &QNetworkReply::finished, this, [this, reply, onSuccess, onError]() {
        reply->deleteLater();

        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
            if (onSuccess)
                onSuccess(doc);
        } else {
            QString errorMsg = reply->errorString();
            QByteArray body = reply->readAll();
            if (!body.isEmpty()) {
                QJsonDocument errDoc = QJsonDocument::fromJson(body);
                if (errDoc.isObject() && errDoc.object().contains("message")) {
                    errorMsg = errDoc.object()["message"].toString();
                }
            }
            if (onError)
                onError(errorMsg);
        }
    });
}

void NetworkManager::get(const QString &endpoint)
{
    QNetworkReply *reply = m_networkManager->get(createRequest(endpoint));
    handleReply(reply,
        [this, endpoint](const QJsonDocument &doc) {
            emit requestFinished(endpoint, doc);
        },
        [this, endpoint](const QString &error) {
            emit requestError(endpoint, error);
        });
}

void NetworkManager::post(const QString &endpoint, const QJsonObject &data)
{
    QNetworkReply *reply = m_networkManager->post(createRequest(endpoint),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this, endpoint](const QJsonDocument &doc) {
            emit requestFinished(endpoint, doc);
        },
        [this, endpoint](const QString &error) {
            emit requestError(endpoint, error);
        });
}

void NetworkManager::put(const QString &endpoint, const QJsonObject &data)
{
    QNetworkReply *reply = m_networkManager->put(createRequest(endpoint),
                                                 QJsonDocument(data).toJson());
    handleReply(reply,
        [this, endpoint](const QJsonDocument &doc) {
            emit requestFinished(endpoint, doc);
        },
        [this, endpoint](const QString &error) {
            emit requestError(endpoint, error);
        });
}

void NetworkManager::deleteResource(const QString &endpoint)
{
    QNetworkReply *reply = m_networkManager->deleteResource(createRequest(endpoint));
    handleReply(reply,
        [this, endpoint](const QJsonDocument &doc) {
            emit requestFinished(endpoint, doc);
        },
        [this, endpoint](const QString &error) {
            emit requestError(endpoint, error);
        });
}

void NetworkManager::sendLocationUpdate(double latitude, double longitude, double accuracy)
{
    QJsonObject data;
    data["latitude"] = latitude;
    data["longitude"] = longitude;
    data["accuracy"] = accuracy;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/location/update"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &) {
            emit locationUpdateResponse(true);
        },
        [this](const QString &) {
            emit locationUpdateResponse(false);
        });
}

void NetworkManager::fetchFriendLocations()
{
    QNetworkReply *reply = m_networkManager->get(createRequest("/api/friends/locations"));
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            emit friendLocationsReceived(doc.array());
        },
        [this](const QString &error) {
            emit requestError("/api/friends/locations", error);
        });
}

void NetworkManager::loginRequest(const QString &username, const QString &password)
{
    QJsonObject data;
    data["username"] = username;
    data["password"] = password;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/auth/login"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            emit loginResponse(true, doc.object());
        },
        [this](const QString &error) {
            QJsonObject errObj;
            errObj["message"] = error;
            emit loginResponse(false, errObj);
        });
}

void NetworkManager::registerRequest(const QString &username, const QString &email,
                                     const QString &password, const QString &displayName)
{
    QJsonObject data;
    data["username"] = username;
    data["email"] = email;
    data["password"] = password;
    data["display_name"] = displayName;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/auth/register"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            emit registerResponse(true, doc.object());
        },
        [this](const QString &error) {
            QJsonObject errObj;
            errObj["message"] = error;
            emit registerResponse(false, errObj);
        });
}

void NetworkManager::updateProfileRequest(const QString &displayName, const QString &avatarUrl)
{
    QJsonObject data;
    data["displayName"] = displayName;
    data["avatarUrl"] = avatarUrl;

    QNetworkReply *reply = m_networkManager->put(createRequest("/api/user/profile"),
                                                 QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            emit profileUpdateResponse(true, doc.object());
        },
        [this](const QString &error) {
            QJsonObject errObj;
            errObj["message"] = error;
            emit profileUpdateResponse(false, errObj);
        });
}

void NetworkManager::changePasswordRequest(const QString &oldPassword, const QString &newPassword)
{
    QJsonObject data;
    data["current_password"] = oldPassword;
    data["new_password"] = newPassword;

    QNetworkReply *reply = m_networkManager->put(createRequest("/api/user/password"),
                                                 QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Password changed successfully");
            emit passwordChangeResponse(true, msg);
        },
        [this](const QString &error) {
            emit passwordChangeResponse(false, error);
        });
}

void NetworkManager::deleteAccountRequest()
{
    QNetworkReply *reply = m_networkManager->deleteResource(createRequest("/api/user/account"));
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Account deleted");
            emit accountDeleteResponse(true, msg);
        },
        [this](const QString &error) {
            emit accountDeleteResponse(false, error);
        });
}

void NetworkManager::fetchFriends()
{
    QNetworkReply *reply = m_networkManager->get(createRequest("/api/friends"));
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            emit friendsListReceived(doc.array());
        },
        [this](const QString &error) {
            emit requestError("/api/friends", error);
        });
}

void NetworkManager::addFriendRequest(const QString &username)
{
    QJsonObject data;
    data["username"] = username;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/friends/add"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Friend request sent");
            emit friendAddResponse(true, msg);
        },
        [this](const QString &error) {
            emit friendAddResponse(false, error);
        });
}

void NetworkManager::removeFriendRequest(const QString &friendId)
{
    QNetworkReply *reply = m_networkManager->deleteResource(
        createRequest("/api/friends/" + friendId));
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Friend removed");
            emit friendRemoveResponse(true, msg);
        },
        [this](const QString &error) {
            emit friendRemoveResponse(false, error);
        });
}

void NetworkManager::acceptFriendRequest(const QString &requestId)
{
    QJsonObject data;
    data["requestId"] = requestId;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/friends/accept"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Friend request accepted");
            emit friendRequestResponse(true, msg);
        },
        [this](const QString &error) {
            emit friendRequestResponse(false, error);
        });
}

void NetworkManager::rejectFriendRequest(const QString &requestId)
{
    QJsonObject data;
    data["requestId"] = requestId;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/friends/reject"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Friend request rejected");
            emit friendRequestResponse(true, msg);
        },
        [this](const QString &error) {
            emit friendRequestResponse(false, error);
        });
}

void NetworkManager::verifyEmailRequest(const QString &username, const QString &code)
{
    QJsonObject data;
    data["username"] = username;
    data["code"] = code;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/auth/verify-email"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Email verified successfully");
            emit emailVerificationResponse(true, msg);
        },
        [this](const QString &error) {
            emit emailVerificationResponse(false, error);
        });
}

void NetworkManager::resendVerificationRequest(const QString &username)
{
    QJsonObject data;
    data["username"] = username;

    QNetworkReply *reply = m_networkManager->post(createRequest("/api/auth/resend-verification"),
                                                  QJsonDocument(data).toJson());
    handleReply(reply,
        [this](const QJsonDocument &doc) {
            QString msg = doc.object()["message"].toString("Verification code sent");
            emit resendVerificationResponse(true, msg);
        },
        [this](const QString &error) {
            emit resendVerificationResponse(false, error);
        });
}
