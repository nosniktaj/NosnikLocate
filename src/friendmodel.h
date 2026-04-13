#ifndef FRIENDMODEL_H
#define FRIENDMODEL_H

#include <QAbstractListModel>
#include <QDateTime>
#include <QString>
#include <QVector>

struct Friend {
    QString id;
    QString username;
    QString displayName;
    QString avatarUrl;
    double latitude = 0.0;
    double longitude = 0.0;
    QDateTime lastSeen;
    bool isOnline = false;
    double distance = 0.0;
};

class FriendModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum FriendRoles {
        FriendIdRole = Qt::UserRole + 1,
        UsernameRole,
        DisplayNameRole,
        AvatarUrlRole,
        LatitudeRole,
        LongitudeRole,
        LastSeenRole,
        IsOnlineRole,
        DistanceRole
    };
    Q_ENUM(FriendRoles)

    explicit FriendModel(QObject *parent = nullptr);
    ~FriendModel() override = default;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setFriends(const QVector<Friend> &friends);
    bool updateFriendLocation(const QString &friendId, double latitude, double longitude,
                              bool isOnline, double distance);
    void addFriend(const Friend &friendData);
    void removeFriend(const QString &friendId);
    void clear();

    Q_INVOKABLE QVariantMap get(int index) const;

signals:
    void countChanged();

private:
    QVector<Friend> m_friends;
    int findFriendIndex(const QString &friendId) const;
};

#endif // FRIENDMODEL_H
