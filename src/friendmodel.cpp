#include "friendmodel.h"

FriendModel::FriendModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int FriendModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_friends.count();
}

QVariant FriendModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_friends.count())
        return QVariant();

    const Friend &f = m_friends.at(index.row());

    switch (role) {
    case FriendIdRole:
        return f.id;
    case UsernameRole:
        return f.username;
    case DisplayNameRole:
        return f.displayName;
    case AvatarUrlRole:
        return f.avatarUrl;
    case LatitudeRole:
        return f.latitude;
    case LongitudeRole:
        return f.longitude;
    case LastSeenRole:
        return f.lastSeen;
    case IsOnlineRole:
        return f.isOnline;
    case DistanceRole:
        return f.distance;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FriendModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[FriendIdRole] = "friendId";
    roles[UsernameRole] = "username";
    roles[DisplayNameRole] = "displayName";
    roles[AvatarUrlRole] = "avatarUrl";
    roles[LatitudeRole] = "latitude";
    roles[LongitudeRole] = "longitude";
    roles[LastSeenRole] = "lastSeen";
    roles[IsOnlineRole] = "isOnline";
    roles[DistanceRole] = "distance";
    return roles;
}

void FriendModel::setFriends(const QVector<Friend> &friends)
{
    beginResetModel();
    m_friends = friends;
    endResetModel();
    emit countChanged();
}

void FriendModel::updateFriendLocation(const QString &friendId, double latitude,
                                       double longitude, bool isOnline, double distance)
{
    int idx = findFriendIndex(friendId);
    if (idx < 0)
        return;

    m_friends[idx].latitude = latitude;
    m_friends[idx].longitude = longitude;
    m_friends[idx].isOnline = isOnline;
    m_friends[idx].distance = distance;
    m_friends[idx].lastSeen = QDateTime::currentDateTimeUtc();

    QModelIndex modelIndex = index(idx);
    emit dataChanged(modelIndex, modelIndex,
                     {LatitudeRole, LongitudeRole, IsOnlineRole, DistanceRole, LastSeenRole});
}

void FriendModel::addFriend(const Friend &friendData)
{
    beginInsertRows(QModelIndex(), m_friends.count(), m_friends.count());
    m_friends.append(friendData);
    endInsertRows();
    emit countChanged();
}

void FriendModel::removeFriend(const QString &friendId)
{
    int idx = findFriendIndex(friendId);
    if (idx < 0)
        return;

    beginRemoveRows(QModelIndex(), idx, idx);
    m_friends.removeAt(idx);
    endRemoveRows();
    emit countChanged();
}

void FriendModel::clear()
{
    beginResetModel();
    m_friends.clear();
    endResetModel();
    emit countChanged();
}

QVariantMap FriendModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_friends.count())
        return map;

    const Friend &f = m_friends.at(index);
    map["friendId"] = f.id;
    map["username"] = f.username;
    map["displayName"] = f.displayName;
    map["avatarUrl"] = f.avatarUrl;
    map["latitude"] = f.latitude;
    map["longitude"] = f.longitude;
    map["lastSeen"] = f.lastSeen;
    map["isOnline"] = f.isOnline;
    map["distance"] = f.distance;
    return map;
}

int FriendModel::findFriendIndex(const QString &friendId) const
{
    for (int i = 0; i < m_friends.count(); ++i) {
        if (m_friends.at(i).id == friendId)
            return i;
    }
    return -1;
}
