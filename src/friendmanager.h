#ifndef FRIENDMANAGER_H
#define FRIENDMANAGER_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>

#include "friendmodel.h"

struct PendingRequest {
    QString requestId;
    QString username;
    QString displayName;
    QString avatarUrl;
    QDateTime createdAt;
};

class PendingRequestModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum PendingRoles {
        RequestIdRole = Qt::UserRole + 1,
        UsernameRole,
        DisplayNameRole,
        AvatarUrlRole,
        CreatedAtRole
    };
    Q_ENUM(PendingRoles)

    explicit PendingRequestModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setRequests(const QVector<PendingRequest> &requests);
    void addRequest(const PendingRequest &request);
    void removeRequest(const QString &requestId);
    void clear();

signals:
    void countChanged();

private:
    QVector<PendingRequest> m_requests;
};

class FriendManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(FriendModel *friendModel READ friendModel CONSTANT)
    Q_PROPERTY(PendingRequestModel *pendingRequestModel READ pendingRequestModel CONSTANT)
    Q_PROPERTY(int pendingRequestCount READ pendingRequestCount NOTIFY pendingRequestCountChanged)

public:
    static FriendManager *instance();

    FriendModel *friendModel() const;
    PendingRequestModel *pendingRequestModel() const;
    int pendingRequestCount() const;

    Q_INVOKABLE void loadFriends();
    Q_INVOKABLE void addFriend(const QString &username);
    Q_INVOKABLE void removeFriend(const QString &friendId);
    Q_INVOKABLE void acceptRequest(const QString &requestId);
    Q_INVOKABLE void rejectRequest(const QString &requestId);
    Q_INVOKABLE void refreshLocations();

signals:
    void pendingRequestCountChanged();
    void friendAdded(const QString &username);
    void friendRemoved(const QString &friendId);
    void friendRequestAccepted(const QString &requestId);
    void friendRequestRejected(const QString &requestId);
    void errorOccurred(const QString &error);

private slots:
    void onFriendsListReceived(const QJsonArray &friends);
    void onFriendLocationsReceived(const QJsonArray &locations);
    void onFriendAddResponse(bool success, const QString &message);
    void onFriendRemoveResponse(bool success, const QString &message);
    void onFriendRequestResponse(bool success, const QString &message);

private:
    explicit FriendManager(QObject *parent = nullptr);
    ~FriendManager() override = default;

    FriendModel *m_friendModel;
    PendingRequestModel *m_pendingRequestModel;
    int m_pendingRequestCount;

    QString m_lastAddedUsername;
    QString m_lastRemovedFriendId;
    QString m_lastRequestId;
    bool m_lastRequestWasAccept;

    static FriendManager *s_instance;
};

#endif // FRIENDMANAGER_H
