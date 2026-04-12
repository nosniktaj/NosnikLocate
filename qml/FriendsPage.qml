import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0
import "components"

Page {
    id: friendsPage

    background: Rectangle { color: "#1A1A2E" }

    property string searchQuery: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#16213E"

            Text {
                text: "Friends"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#FFFFFF"
                anchors.centerIn: parent
            }
        }

        // Search bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 12
            Layout.bottomMargin: 8
            radius: 12
            color: "#1E1E3A"
            border.width: searchField.activeFocus ? 1 : 0
            border.color: "#BB86FC"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Text {
                    text: "🔍"
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignVCenter
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    placeholderText: "Search friends..."
                    placeholderTextColor: "#666688"
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    background: Item {}
                    onTextChanged: friendsPage.searchQuery = text.toLowerCase()
                }

                Text {
                    text: "✕"
                    font.pixelSize: 14
                    color: "#B0B0B0"
                    visible: searchField.text !== ""
                    Layout.alignment: Qt.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: searchField.text = ""
                    }
                }
            }
        }

        // Friends list
        ListView {
            id: friendsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: FriendManager.friendModel
            spacing: 0

            // Pull to refresh
            onContentYChanged: {
                if (contentY < -80 && !dragging) {
                    FriendManager.loadFriends();
                    FriendManager.refreshLocations();
                }
            }

            Text {
                anchors.top: parent.top
                anchors.topMargin: -40
                anchors.horizontalCenter: parent.horizontalCenter
                text: "↓ Pull to refresh"
                font.pixelSize: 12
                color: "#B0B0B0"
                opacity: friendsList.contentY < -40 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            delegate: Item {
                width: friendsList.width

                required property int index
                required property string friendId
                required property string displayName
                required property string username
                required property string avatarUrl
                required property bool isOnline
                required property var lastSeen
                required property double distance

                visible: {
                    if (friendsPage.searchQuery === "") return true;
                    return displayName.toLowerCase().indexOf(friendsPage.searchQuery) >= 0 ||
                           username.toLowerCase().indexOf(friendsPage.searchQuery) >= 0;
                }
                height: visible ? friendCard.implicitHeight : 0

                // Swipe to delete
                SwipeDelegate {
                    id: swipeDelegate
                    anchors.fill: parent
                    padding: 0

                    background: Rectangle {
                        color: "transparent"

                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.topMargin: 4
                            anchors.bottomMargin: 4
                            color: "#CF6679"
                            radius: 14
                            opacity: Math.min(1.0, Math.abs(swipeDelegate.swipe.position))

                            Text {
                                text: "Remove"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#FFFFFF"
                                anchors.right: parent.right
                                anchors.rightMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                visible: swipeDelegate.swipe.position < -0.2
                            }
                        }
                    }

                    contentItem: FriendCard {
                        id: friendCard
                        friendId: parent.parent.friendId
                        displayName: parent.parent.displayName
                        username: parent.parent.username
                        avatarUrl: parent.parent.avatarUrl
                        isOnline: parent.parent.isOnline
                        lastSeen: parent.parent.lastSeen ? Qt.formatDateTime(parent.parent.lastSeen, "hh:mm AP") : ""
                        distance: parent.parent.distance
                        distanceUnit: SettingsManager.distanceUnit
                    }

                    swipe.right: Item {
                        width: parent.width
                        height: parent.height

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                        }
                    }

                    swipe.onCompleted: {
                        FriendManager.removeFriend(parent.friendId);
                    }
                }
            }

            // Empty state
            Item {
                anchors.centerIn: parent
                width: parent.width - 60
                height: emptyColumn.height
                visible: FriendManager.friendModel.count === 0

                ColumnLayout {
                    id: emptyColumn
                    anchors.centerIn: parent
                    spacing: 12
                    width: parent.width

                    Text {
                        text: "👥"
                        font.pixelSize: 48
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No friends yet"
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        color: "#FFFFFF"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Tap the + button to add friends\nand start sharing locations"
                        font.pixelSize: 14
                        color: "#B0B0B0"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    // FAB: Add friend
    RoundButton {
        id: addFriendFab
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        width: 56
        height: 56
        z: 2

        background: Rectangle {
            radius: 28
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#BB86FC" }
                GradientStop { position: 1.0; color: "#9C27B0" }
            }
        }

        contentItem: Text {
            text: "+"
            font.pixelSize: 28
            font.weight: Font.Light
            color: "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: addFriendDialog.open()

        scale: pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    AddFriendDialog {
        id: addFriendDialog
        parent: Overlay.overlay
        onFriendRequested: function(username) {
            FriendManager.addFriend(username);
        }
    }

    Component.onCompleted: {
        FriendManager.loadFriends();
    }
}
