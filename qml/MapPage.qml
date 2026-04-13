import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtPositioning
import QtLocation
import NosnikLocate 1.0
import "components"

Page {
    id: mapPage

    background: Rectangle { color: "#1A1A2E" }

    property bool showFriendPopup: false
    property var selectedFriend: null

    Plugin {
        id: osmPlugin
        name: "osm"

        PluginParameter { name: "osm.useragent"; value: "NosnikLocate/1.0 (https://github.com/nosniktaj/NosnikLocate)" }
        PluginParameter { name: "osm.mapping.custom.host"; value: "https://tile.openstreetmap.org/" }
        PluginParameter { name: "osm.mapping.highdpi_tiles"; value: true }
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: osmPlugin
        center: QtPositioning.coordinate(
            LocationManager.latitude !== 0 ? LocationManager.latitude : 51.5074,
            LocationManager.longitude !== 0 ? LocationManager.longitude : -0.1278
        )
        zoomLevel: 14
        copyrightsVisible: false

        // User location marker
        MapQuickItem {
            id: userMarker
            visible: LocationManager.latitude !== 0 && LocationManager.longitude !== 0
            coordinate: QtPositioning.coordinate(LocationManager.latitude, LocationManager.longitude)
            anchorPoint.x: userDot.width / 2
            anchorPoint.y: userDot.height / 2

            sourceItem: Item {
                id: userDot
                width: 28
                height: 28

                // Pulsing ring
                Rectangle {
                    id: pulseRing
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    radius: 14
                    color: "transparent"
                    border.width: 2
                    border.color: "#BB86FC"
                    opacity: 0

                    SequentialAnimation on opacity {
                        running: LocationManager.isTracking
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.8; to: 0.0; duration: 2000; easing.type: Easing.OutQuad }
                        PauseAnimation { duration: 500 }
                    }

                    SequentialAnimation on scale {
                        running: LocationManager.isTracking
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 2.5; duration: 2000; easing.type: Easing.OutQuad }
                        PauseAnimation { duration: 500 }
                    }
                }

                // Main dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    radius: 9
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#BB86FC" }
                        GradientStop { position: 1.0; color: "#9C27B0" }
                    }
                    border.width: 3
                    border.color: "#FFFFFF"
                }
            }
        }

        // Accuracy circle
        MapCircle {
            id: accuracyCircle
            visible: LocationManager.isTracking && LocationManager.accuracy > 0
            center: QtPositioning.coordinate(LocationManager.latitude, LocationManager.longitude)
            radius: LocationManager.accuracy
            color: "#15BB86FC"
            border.width: 1
            border.color: "#40BB86FC"
        }

        // Friend markers via MapItemView
        MapItemView {
            model: FriendManager.friendModel

            delegate: MapQuickItem {
                required property double latitude
                required property double longitude
                required property string displayName
                required property string avatarUrl
                required property bool isOnline
                required property string friendId
                required property string username
                required property double distance
                required property var lastSeen

                coordinate: QtPositioning.coordinate(latitude, longitude)
                anchorPoint.x: markerItem.width / 2
                anchorPoint.y: markerItem.height
                visible: latitude !== 0 && longitude !== 0

                sourceItem: MapFriendMarker {
                    id: markerItem
                    displayName: parent.displayName
                    avatarUrl: parent.avatarUrl
                    isOnline: parent.isOnline

                    onTapped: {
                        mapPage.selectedFriend = {
                            "friendId": parent.friendId,
                            "displayName": parent.displayName,
                            "username": parent.username,
                            "avatarUrl": parent.avatarUrl,
                            "isOnline": parent.isOnline,
                            "distance": parent.distance,
                            "lastSeen": parent.lastSeen ? Qt.formatDateTime(parent.lastSeen, "hh:mm AP") : ""
                        };
                        mapPage.showFriendPopup = true;
                    }
                }
            }
        }
    }

    // Map controls - Zoom buttons
    Column {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 12
        spacing: 8
        z: 2

        RoundButton {
            width: 44
            height: 44
            text: "+"
            font.pixelSize: 22
            font.weight: Font.Bold
            onClicked: map.zoomLevel = Math.min(map.zoomLevel + 1, 19)

            background: Rectangle {
                radius: 22
                color: "#1E1E3A"
                border.width: 1
                border.color: "#333355"
            }
            contentItem: Text {
                text: parent.text; font: parent.font; color: "#FFFFFF"
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }

        RoundButton {
            width: 44
            height: 44
            text: "−"
            font.pixelSize: 22
            font.weight: Font.Bold
            onClicked: map.zoomLevel = Math.max(map.zoomLevel - 1, 2)

            background: Rectangle {
                radius: 22
                color: "#1E1E3A"
                border.width: 1
                border.color: "#333355"
            }
            contentItem: Text {
                text: parent.text; font: parent.font; color: "#FFFFFF"
                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // FAB: Center on user
    RoundButton {
        id: centerButton
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 16
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
            text: "◎"
            font.pixelSize: 24
            color: "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: {
            if (LocationManager.latitude !== 0 && LocationManager.longitude !== 0) {
                map.center = QtPositioning.coordinate(LocationManager.latitude, LocationManager.longitude);
            }
        }

        scale: pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    // Tracking toggle button
    RoundButton {
        id: trackingButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        width: 56
        height: 56
        z: 2

        background: Rectangle {
            radius: 28
            color: LocationManager.isTracking ? "#9C27B0" : "#1E1E3A"
            border.width: LocationManager.isTracking ? 0 : 2
            border.color: "#BB86FC"

            Behavior on color { ColorAnimation { duration: 200 } }
        }

        contentItem: Text {
            text: LocationManager.isTracking ? "⏸" : "▶"
            font.pixelSize: 20
            color: "#FFFFFF"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: {
            if (LocationManager.isTracking) {
                LocationManager.stopTracking();
            } else {
                LocationManager.startTracking();
            }
        }

        scale: pressed ? 0.9 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    // Friend info popup
    Rectangle {
        id: friendPopup
        visible: mapPage.showFriendPopup && mapPage.selectedFriend !== null
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        anchors.bottomMargin: 16
        height: 100
        radius: 16
        color: "#16213E"
        border.width: 1
        border.color: "#333355"
        z: 3

        opacity: visible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            AvatarCircle {
                size: 48
                imageUrl: mapPage.selectedFriend ? mapPage.selectedFriend.avatarUrl : ""
                initials: mapPage.selectedFriend ? mapPage.selectedFriend.displayName.charAt(0) : ""
                showOnlineIndicator: true
                isOnline: mapPage.selectedFriend ? mapPage.selectedFriend.isOnline : false
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: mapPage.selectedFriend ? mapPage.selectedFriend.displayName : ""
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: mapPage.selectedFriend ? "@" + mapPage.selectedFriend.username : ""
                    font.pixelSize: 12
                    color: "#B0B0B0"
                    Layout.fillWidth: true
                }
                Text {
                    text: {
                        if (!mapPage.selectedFriend) return "";
                        var parts = [];
                        if (mapPage.selectedFriend.isOnline) parts.push("Online");
                        else if (mapPage.selectedFriend.lastSeen !== "") parts.push("Last seen: " + mapPage.selectedFriend.lastSeen);
                        if (mapPage.selectedFriend.distance > 0) parts.push(mapPage.selectedFriend.distance.toFixed(1) + " km away");
                        return parts.join(" · ");
                    }
                    font.pixelSize: 12
                    color: mapPage.selectedFriend && mapPage.selectedFriend.isOnline ? "#00E676" : "#B0B0B0"
                    Layout.fillWidth: true
                }
            }

            RoundButton {
                width: 32
                height: 32
                flat: true
                text: "✕"
                onClicked: mapPage.showFriendPopup = false

                contentItem: Text {
                    text: "✕"; font.pixelSize: 14; color: "#B0B0B0"
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle { radius: 16; color: "transparent" }
            }
        }
    }

    // Refresh friend locations periodically
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: FriendManager.refreshLocations()
    }

    Component.onCompleted: {
        FriendManager.refreshLocations();
    }
}
