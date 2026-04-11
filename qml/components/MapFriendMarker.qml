import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string displayName: ""
    property string avatarUrl: ""
    property bool isOnline: false

    signal tapped()

    width: markerColumn.width
    height: markerColumn.height

    Column {
        id: markerColumn
        spacing: 2
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
            width: nameLabel.implicitWidth + 16
            height: nameLabel.implicitHeight + 8
            radius: 10
            color: "#1E1E3A"
            border.width: 1
            border.color: "#BB86FC"
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.displayName !== ""

            Text {
                id: nameLabel
                text: root.displayName
                font.pixelSize: 11
                font.weight: Font.Medium
                color: "#FFFFFF"
                anchors.centerIn: parent
            }
        }

        Item {
            width: 40
            height: 40
            anchors.horizontalCenter: parent.horizontalCenter

            AvatarCircle {
                anchors.centerIn: parent
                size: 36
                imageUrl: root.avatarUrl
                initials: root.displayName.length > 0 ? root.displayName.charAt(0) : "?"
                showOnlineIndicator: true
                isOnline: root.isOnline
            }

            Rectangle {
                anchors.fill: parent
                radius: 20
                border.width: 2
                border.color: root.isOnline ? "#00E676" : "#BB86FC"
                color: "transparent"
            }
        }

        // Pointer triangle
        Canvas {
            width: 12
            height: 8
            anchors.horizontalCenter: parent.horizontalCenter

            onPaint: {
                var ctx = getContext("2d");
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width / 2, height);
                ctx.closePath();
                ctx.fillStyle = "#BB86FC";
                ctx.fill();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.tapped()
    }
}
