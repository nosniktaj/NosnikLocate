import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0
import "components"

Page {
    id: notificationsPage

    background: Rectangle { color: "#1A1A2E" }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            color: "#16213E"

            Text {
                text: "Notifications"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#FFFFFF"
                anchors.centerIn: parent
            }

            // Badge count
            Rectangle {
                visible: FriendManager.pendingRequestCount > 0
                anchors.left: parent.horizontalCenter
                anchors.leftMargin: 64
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(22, badgeCountText.implicitWidth + 12)
                height: 22
                radius: 11
                color: "#BB86FC"

                Text {
                    id: badgeCountText
                    text: FriendManager.pendingRequestCount
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    anchors.centerIn: parent
                }
            }
        }

        // Pending requests list
        ListView {
            id: requestsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: FriendManager.pendingRequestModel
            spacing: 0

            // Pull to refresh
            onContentYChanged: {
                if (contentY < -80 && !dragging) {
                    FriendManager.loadFriends();
                }
            }

            Text {
                anchors.top: parent.top
                anchors.topMargin: -40
                anchors.horizontalCenter: parent.horizontalCenter
                text: "↓ Pull to refresh"
                font.pixelSize: 12
                color: "#B0B0B0"
                opacity: requestsList.contentY < -40 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            header: Item {
                width: parent.width
                height: sectionLabel.visible ? 44 : 0

                Text {
                    id: sectionLabel
                    text: "Friend Requests"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#B0B0B0"
                    visible: FriendManager.pendingRequestCount > 0
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            delegate: FriendRequestCard {
                width: requestsList.width
                requestId: model.requestId
                displayName: model.displayName
                username: model.username
                avatarUrl: model.avatarUrl
                onAccepted: FriendManager.acceptRequest(model.requestId)
                onRejected: FriendManager.rejectRequest(model.requestId)
            }

            // Empty state
            Item {
                anchors.centerIn: parent
                width: parent.width - 60
                height: emptyCol.height
                visible: FriendManager.pendingRequestCount === 0

                ColumnLayout {
                    id: emptyCol
                    anchors.centerIn: parent
                    spacing: 12
                    width: parent.width

                    Text {
                        text: "🔔"
                        font.pixelSize: 48
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "All caught up!"
                        font.pixelSize: 18
                        font.weight: Font.Medium
                        color: "#FFFFFF"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No pending friend requests.\nWhen someone sends you a request,\nit will appear here."
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

    Component.onCompleted: {
        FriendManager.loadFriends();
    }
}
