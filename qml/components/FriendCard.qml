import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string friendId: ""
    property string displayName: ""
    property string username: ""
    property string avatarUrl: ""
    property bool isOnline: false
    property string lastSeen: ""
    property real distance: 0.0
    property string distanceUnit: "km"

    signal clicked()
    signal removeRequested()

    implicitHeight: 76
    implicitWidth: parent ? parent.width : 300

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        radius: 14
        color: "#1E1E3A"

        MouseArea {
            anchors.fill: parent
            onClicked: root.clicked()

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: parent.pressed ? "#FFFFFF" : "transparent"
                opacity: parent.pressed ? 0.05 : 0
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            AvatarCircle {
                size: 44
                imageUrl: root.avatarUrl
                initials: root.displayName.length > 0 ? root.displayName.charAt(0) : "?"
                showOnlineIndicator: true
                isOnline: root.isOnline
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    text: root.displayName
                    font.pixelSize: 15
                    font.weight: Font.Medium
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: "@" + root.username
                    font.pixelSize: 12
                    color: "#B0B0B0"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                spacing: 2

                Text {
                    text: root.distance > 0 ? root.distance.toFixed(1) + " " + root.distanceUnit : ""
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: "#BB86FC"
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignRight
                }

                Text {
                    text: root.isOnline ? "Online" : (root.lastSeen !== "" ? root.lastSeen : "Offline")
                    font.pixelSize: 11
                    color: root.isOnline ? "#00E676" : "#B0B0B0"
                    horizontalAlignment: Text.AlignRight
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
}
