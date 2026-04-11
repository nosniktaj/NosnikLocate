#include "friendmanager.h"
#include "networkmanager.h"

#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>

// --- PendingRequestModel ---

PendingRequestModel::PendingRequestModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int PendingRequestModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_requests.count();
}

QVariant PendingRequestModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_requests.count())
        return QVariant();

    const PendingRequest &req = m_requests.at(index.row());

    switch (role) {
    case RequestIdRole:
        return req.requestId;
    case UsernameRole:
        return req.username;
    case DisplayNameRole:
        return req.displayName;
    case AvatarUrlRole:
        return req.avatarUrl;
    case CreatedAtRole:
        return req.createdAt;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PendingRequestModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[RequestIdRole] = "requestId";
    roles[UsernameRole] = "username";
    roles[DisplayNameRole] = "displayName";
    roles[AvatarUrlRole] = "avatarUrl";
    roles[CreatedAtRole] = "createdAt";
    return roles;
}

void PendingRequestModel::setRequests(const QVector<PendingRequest> &requests)
{
    beginResetModel();
    m_requests = requests;
    endResetModel();
    emit countChanged();
}

void PendingRequestModel::addRequest(const PendingRequest &request)
{
    beginInsertRows(QModelIndex(), m_requests.count(), m_requests.count());
    m_requests.append(request);
    endInsertRows();
    emit countChanged();
}

void PendingRequestModel::removeRequest(const QString &requestId)
{
    for (int i = 0; i < m_requests.count(); ++i) {
        if (m_requests.at(i).requestId == requestId) {
            beginRemoveRows(QModelIndex(), i, i);
            m_requests.removeAt(i);
            endRemoveRows();
            emit countChanged();
            return;
        }
    }
}

void PendingRequestModel::clear()
{
    beginResetModel();
    m_requests.clear();
    endResetModel();
    emit countChanged();
}

// --- FriendManager ---

FriendManager *FriendManager::s_instance = nullptr;

FriendManager *FriendManager::instance()
{
    if (!s_instance) {
        s_instance = new FriendManager();
    }
    return s_instance;
}

FriendManager::FriendManager(QObject *parent)
    : QObject(parent)
    , m_friendModel(new FriendModel(this))
    , m_pendingRequestModel(new PendingRequestModel(this))
    , m_pendingRequestCount(0)
    , m_lastRequestWasAccept(false)
{
    auto *net = NetworkManager::instance();
    connect(net, &NetworkManager::friendsListReceived, this, &FriendManager::onFriendsListReceived);
    connect(net, &NetworkManager::friendLocationsReceived, this, &FriendManager::onFriendLocationsReceived);
    connect(net, &NetworkManager::friendAddResponse, this, &FriendManager::onFriendAddResponse);
    connect(net, &NetworkManager::friendRemoveResponse, this, &FriendManager::onFriendRemoveResponse);
    connect(net, &NetworkManager::friendRequestResponse, this, &FriendManager::onFriendRequestResponse);
}

FriendModel *FriendManager::friendModel() const
{
    return m_friendModel;
}

PendingRequestModel *FriendManager::pendingRequestModel() const
{
    return m_pendingRequestModel;
}

int FriendManager::pendingRequestCount() const
{
    return m_pendingRequestCount;
}

void FriendManager::loadFriends()
{
    NetworkManager::instance()->fetchFriends();
}

void FriendManager::addFriend(const QString &username)
{
    m_lastAddedUsername = username;
    NetworkManager::instance()->addFriendRequest(username);
}

void FriendManager::removeFriend(const QString &friendId)
{
    m_lastRemovedFriendId = friendId;
    NetworkManager::instance()->removeFriendRequest(friendId);
}

void FriendManager::acceptRequest(const QString &requestId)
{
    m_lastRequestId = requestId;
    m_lastRequestWasAccept = true;
    NetworkManager::instance()->acceptFriendRequest(requestId);
}

void FriendManager::rejectRequest(const QString &requestId)
{
    m_lastRequestId = requestId;
    m_lastRequestWasAccept = false;
    NetworkManager::instance()->rejectFriendRequest(requestId);
}

void FriendManager::refreshLocations()
{
    NetworkManager::instance()->fetchFriendLocations();
}

void FriendManager::onFriendsListReceived(const QJsonArray &friends)
{
    QVector<Friend> friendList;
    QVector<PendingRequest> pendingList;

    for (const QJsonValue &val : friends) {
        QJsonObject obj = val.toObject();
        QString status = obj["status"].toString();

        if (status == "pending") {
            PendingRequest req;
            req.requestId = obj["requestId"].toString();
            req.username = obj["username"].toString();
            req.displayName = obj["displayName"].toString();
            req.avatarUrl = obj["avatarUrl"].toString();
            req.createdAt = QDateTime::fromString(obj["createdAt"].toString(), Qt::ISODate);
            pendingList.append(req);
        } else {
            Friend f;
            f.id = obj["id"].toString();
            f.username = obj["username"].toString();
            f.displayName = obj["displayName"].toString();
            f.avatarUrl = obj["avatarUrl"].toString();
            f.latitude = obj["latitude"].toDouble();
            f.longitude = obj["longitude"].toDouble();
            f.lastSeen = QDateTime::fromString(obj["lastSeen"].toString(), Qt::ISODate);
            f.isOnline = obj["isOnline"].toBool();
            f.distance = obj["distance"].toDouble();
            friendList.append(f);
        }
    }

    m_friendModel->setFriends(friendList);
    m_pendingRequestModel->setRequests(pendingList);

    int newCount = pendingList.count();
    if (m_pendingRequestCount != newCount) {
        m_pendingRequestCount = newCount;
        emit pendingRequestCountChanged();
    }
}

void FriendManager::onFriendLocationsReceived(const QJsonArray &locations)
{
    for (const QJsonValue &val : locations) {
        QJsonObject obj = val.toObject();
        QString friendId = obj["friendId"].toString();
        double lat = obj["latitude"].toDouble();
        double lng = obj["longitude"].toDouble();
        bool online = obj["isOnline"].toBool();
        double dist = obj["distance"].toDouble();

        m_friendModel->updateFriendLocation(friendId, lat, lng, online, dist);
    }
}

void FriendManager::onFriendAddResponse(bool success, const QString &message)
{
    if (success) {
        emit friendAdded(m_lastAddedUsername);
        loadFriends();
    } else {
        emit errorOccurred(message);
    }
}

void FriendManager::onFriendRemoveResponse(bool success, const QString &message)
{
    if (success) {
        m_friendModel->removeFriend(m_lastRemovedFriendId);
        emit friendRemoved(m_lastRemovedFriendId);
    } else {
        emit errorOccurred(message);
    }
}

void FriendManager::onFriendRequestResponse(bool success, const QString &message)
{
    if (success) {
        m_pendingRequestModel->removeRequest(m_lastRequestId);
        m_pendingRequestCount = m_pendingRequestModel->rowCount();
        emit pendingRequestCountChanged();

        if (m_lastRequestWasAccept) {
            emit friendRequestAccepted(m_lastRequestId);
            loadFriends();
        } else {
            emit friendRequestRejected(m_lastRequestId);
        }
    } else {
        emit errorOccurred(message);
    }
}
