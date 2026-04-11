import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string imageUrl: ""
    property string initials: "?"
    property real size: 48
    property bool showOnlineIndicator: false
    property bool isOnline: false
    property color gradientStart: "#BB86FC"
    property color gradientEnd: "#9C27B0"

    width: size
    height: size

    Rectangle {
        id: avatarBg
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.gradientStart }
            GradientStop { position: 1.0; color: root.gradientEnd }
        }
        visible: !avatarImage.visible

        Text {
            anchors.centerIn: parent
            text: root.initials.length > 0 ? root.initials.substring(0, 2).toUpperCase() : "?"
            font.pixelSize: root.size * 0.38
            font.weight: Font.Bold
            color: "#FFFFFF"
        }
    }

    Rectangle {
        id: avatarImageContainer
        anchors.fill: parent
        radius: width / 2
        clip: true
        visible: avatarImage.status === Image.Ready
        color: "transparent"

        Image {
            id: avatarImage
            anchors.fill: parent
            source: root.imageUrl
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: Item {}
        }
    }

    Rectangle {
        id: onlineDot
        visible: root.showOnlineIndicator
        width: root.size * 0.28
        height: width
        radius: width / 2
        color: root.isOnline ? "#00E676" : "#B0B0B0"
        border.width: 2
        border.color: "#1E1E3A"
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -1
        anchors.bottomMargin: -1

        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
