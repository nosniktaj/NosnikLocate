import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0

ApplicationWindow {
    id: root
    width: 400
    height: 800
    visible: true
    title: "NosnikLocate"

    Material.theme: Material.Dark
    Material.accent: "#BB86FC"
    Material.primary: "#121212"
    Material.background: "#1A1A2E"

    color: "#1A1A2E"

    // Auth flow: show login/register when not logged in
    Loader {
        id: authLoader
        anchors.fill: parent
        visible: !UserManager.isLoggedIn
        active: !UserManager.isLoggedIn
        sourceComponent: loginComponent
        z: 10

        opacity: active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    }

    Component {
        id: loginComponent
        LoginPage {
            onRegisterRequested: authLoader.sourceComponent = registerComponent
        }
    }

    Component {
        id: registerComponent
        RegisterPage {
            onLoginRequested: authLoader.sourceComponent = loginComponent
        }
    }

    // Main content: visible when logged in
    Item {
        id: mainContent
        anchors.fill: parent
        visible: UserManager.isLoggedIn
        opacity: UserManager.isLoggedIn ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

        StackLayout {
            id: contentStack
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: tabBar.top
            currentIndex: tabBar.currentIndex

            MapPage {}
            FriendsPage {}
            NotificationsPage {}
            SettingsPage {}
        }

        // Bottom tab bar
        TabBar {
            id: tabBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            Material.accent: "#BB86FC"
            Material.background: "#16213E"

            background: Rectangle {
                color: "#16213E"
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#333355"
                    anchors.top: parent.top
                }
            }

            TabButton {
                text: "Map"
                icon.source: ""
                display: AbstractButton.TextUnderIcon

                contentItem: ColumnLayout {
                    spacing: 2
                    Text {
                        text: "📍"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Map"
                        font.pixelSize: 10
                        color: tabBar.currentIndex === 0 ? "#BB86FC" : "#B0B0B0"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
                background: Rectangle { color: "transparent" }
            }

            TabButton {
                text: "Friends"
                display: AbstractButton.TextUnderIcon

                contentItem: ColumnLayout {
                    spacing: 2
                    Text {
                        text: "👥"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Friends"
                        font.pixelSize: 10
                        color: tabBar.currentIndex === 1 ? "#BB86FC" : "#B0B0B0"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
                background: Rectangle { color: "transparent" }
            }

            TabButton {
                text: "Alerts"
                display: AbstractButton.TextUnderIcon

                contentItem: Item {
                    implicitHeight: notifCol.implicitHeight

                    ColumnLayout {
                        id: notifCol
                        anchors.centerIn: parent
                        spacing: 2

                        Item {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 22
                            Layout.alignment: Qt.AlignHCenter

                            Text {
                                text: "🔔"
                                font.pixelSize: 20
                                anchors.centerIn: parent
                            }

                            // Badge
                            Rectangle {
                                visible: FriendManager.pendingRequestCount > 0
                                width: Math.max(16, badgeText.implicitWidth + 6)
                                height: 16
                                radius: 8
                                color: "#CF6679"
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.topMargin: -2
                                anchors.rightMargin: -4

                                Text {
                                    id: badgeText
                                    text: FriendManager.pendingRequestCount
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                    anchors.centerIn: parent
                                }

                                scale: visible ? 1.0 : 0.0
                                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                            }
                        }

                        Text {
                            text: "Alerts"
                            font.pixelSize: 10
                            color: tabBar.currentIndex === 2 ? "#BB86FC" : "#B0B0B0"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
                background: Rectangle { color: "transparent" }
            }

            TabButton {
                text: "Settings"
                display: AbstractButton.TextUnderIcon

                contentItem: ColumnLayout {
                    spacing: 2
                    Text {
                        text: "⚙"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Settings"
                        font.pixelSize: 10
                        color: tabBar.currentIndex === 3 ? "#BB86FC" : "#B0B0B0"
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
                background: Rectangle { color: "transparent" }
            }
        }
    }

    // Reset auth view when user logs out
    Connections {
        target: UserManager
        function onIsLoggedInChanged() {
            if (!UserManager.isLoggedIn) {
                authLoader.sourceComponent = loginComponent;
            }
        }
    }
}
