import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string requestId: ""
    property string displayName: ""
    property string username: ""
    property string avatarUrl: ""
    property string createdAt: ""

    signal accepted()
    signal rejected()

    implicitHeight: 88
    implicitWidth: parent ? parent.width : 300

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        radius: 14
        color: "#1E1E3A"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            AvatarCircle {
                size: 44
                imageUrl: root.avatarUrl
                initials: root.displayName.length > 0 ? root.displayName.charAt(0) : "?"
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

            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                RoundButton {
                    width: 40
                    height: 40
                    flat: true
                    text: "✓"
                    font.pixelSize: 18
                    font.weight: Font.Bold

                    background: Rectangle {
                        radius: 20
                        color: parent.down ? Qt.darker("#03DAC6", 1.2) : "#03DAC6"
                        opacity: parent.down ? 1.0 : 0.9
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "#1A1A2E"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.accepted()
                }

                RoundButton {
                    width: 40
                    height: 40
                    flat: true
                    text: "✕"
                    font.pixelSize: 18
                    font.weight: Font.Bold

                    background: Rectangle {
                        radius: 20
                        color: parent.down ? Qt.darker("#CF6679", 1.2) : "#CF6679"
                        opacity: parent.down ? 1.0 : 0.9
                    }

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.rejected()
                }
            }
        }
    }
}
