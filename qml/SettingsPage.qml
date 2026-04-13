import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0
import "components"

Page {
    id: settingsPage

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
                text: "Settings"
                font.pixelSize: 20
                font.weight: Font.Bold
                color: "#FFFFFF"
                anchors.centerIn: parent
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: settingsColumn.height + 40
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: settingsColumn
                width: parent.width
                spacing: 0

                // ---- Profile Section ----
                SectionHeader { text: "Profile" }

                SettingsItem {
                    Layout.preferredHeight: 96

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 14

                        AvatarCircle {
                            size: 52
                            imageUrl: UserManager.avatarUrl
                            initials: UserManager.displayName.length > 0 ? UserManager.displayName.charAt(0) : (UserManager.username.length > 0 ? UserManager.username.charAt(0) : "?")
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: UserManager.displayName.length > 0 ? UserManager.displayName : UserManager.username
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: "#FFFFFF"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: UserManager.username.length > 0 ? "@" + UserManager.username : ""
                                font.pixelSize: 13
                                color: "#B0B0B0"
                                visible: text !== ""
                                Layout.fillWidth: true
                            }
                            Text {
                                text: UserManager.email
                                font.pixelSize: 12
                                color: "#666688"
                                visible: text !== ""
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // ---- Location Section ----
                SectionHeader { text: "Location" }

                SettingsItem {
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        Text {
                            text: "Share Location"
                            font.pixelSize: 15
                            color: "#FFFFFF"
                            Layout.fillWidth: true
                        }
                        Switch {
                            checked: SettingsManager.shareLocation
                            Material.accent: "#BB86FC"
                            onToggled: {
                                SettingsManager.shareLocation = checked;
                                SettingsManager.save();
                            }
                        }
                    }
                }

                SettingsItem {
                    Layout.preferredHeight: 72
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8
                        spacing: 2

                        RowLayout {
                            Text {
                                text: "Update Interval"
                                font.pixelSize: 15
                                color: "#FFFFFF"
                                Layout.fillWidth: true
                            }
                            Text {
                                text: (intervalSlider.value / 1000).toFixed(0) + "s"
                                font.pixelSize: 13
                                color: "#BB86FC"
                            }
                        }

                        Slider {
                            id: intervalSlider
                            Layout.fillWidth: true
                            from: 10000
                            to: 300000
                            stepSize: 10000
                            value: SettingsManager.updateInterval
                            Material.accent: "#BB86FC"
                            onMoved: {
                                SettingsManager.updateInterval = value;
                                SettingsManager.save();
                            }
                        }
                    }
                }

                SettingsItem {
                    Layout.preferredHeight: 64
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Text {
                            text: "Distance Unit"
                            font.pixelSize: 15
                            color: "#FFFFFF"
                            Layout.fillWidth: true
                        }

                        ComboBox {
                            id: unitCombo
                            model: ["km", "mi"]
                            currentIndex: SettingsManager.distanceUnit === "mi" ? 1 : 0
                            Material.accent: "#BB86FC"
                            Material.foreground: "#FFFFFF"
                            implicitWidth: 100
                            Layout.alignment: Qt.AlignVCenter

                            background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: 40
                                radius: 8
                                color: "#1E1E3A"
                                border.width: 1
                                border.color: "#333355"
                            }

                            onActivated: {
                                SettingsManager.distanceUnit = currentText;
                                SettingsManager.save();
                            }
                        }
                    }
                }

                // ---- Map Section ----
                SectionHeader { text: "Map" }

                SettingsItem {
                    Layout.preferredHeight: 64
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Text {
                            text: "Map Style"
                            font.pixelSize: 15
                            color: "#FFFFFF"
                            Layout.fillWidth: true
                        }

                        ComboBox {
                            id: mapStyleCombo
                            model: ["street", "satellite", "terrain"]
                            currentIndex: {
                                var s = SettingsManager.mapStyle;
                                if (s === "satellite") return 1;
                                if (s === "terrain") return 2;
                                return 0;
                            }
                            Material.accent: "#BB86FC"
                            Material.foreground: "#FFFFFF"
                            implicitWidth: 140
                            Layout.alignment: Qt.AlignVCenter

                            background: Rectangle {
                                implicitWidth: 140
                                implicitHeight: 40
                                radius: 8
                                color: "#1E1E3A"
                                border.width: 1
                                border.color: "#333355"
                            }

                            onActivated: {
                                SettingsManager.mapStyle = currentText;
                                SettingsManager.save();
                            }
                        }
                    }
                }

                // ---- Notifications Section ----
                SectionHeader { text: "Notifications" }

                SettingsItem {
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Text {
                            text: "Show Notifications"
                            font.pixelSize: 15
                            color: "#FFFFFF"
                            Layout.fillWidth: true
                        }

                        Switch {
                            checked: SettingsManager.showNotifications
                            Material.accent: "#BB86FC"
                            onToggled: {
                                SettingsManager.showNotifications = checked;
                                SettingsManager.save();
                            }
                        }
                    }
                }

                // ---- Account Section ----
                SectionHeader { text: "Account" }

                SettingsItem {
                    Layout.preferredHeight: 48
                    MouseArea {
                        anchors.fill: parent
                        onClicked: changePasswordDialog.open()

                        Text {
                            text: "Change Password"
                            font.pixelSize: 15
                            color: "#BB86FC"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                        }
                        Text {
                            text: "›"
                            font.pixelSize: 20
                            color: "#B0B0B0"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                        }
                    }
                }

                SettingsItem {
                    Layout.preferredHeight: 48
                    MouseArea {
                        anchors.fill: parent
                        onClicked: deleteAccountDialog.open()

                        Text {
                            text: "Delete Account"
                            font.pixelSize: 15
                            color: "#CF6679"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                        }
                        Text {
                            text: "›"
                            font.pixelSize: 20
                            color: "#B0B0B0"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                        }
                    }
                }

                // Logout button
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    Layout.topMargin: 8

                    NosnikButton {
                        anchors.centerIn: parent
                        width: parent.width - 32
                        height: 48
                        text: "Sign Out"
                        buttonColor: "#333355"
                        onClicked: UserManager.logout()
                    }
                }

                // ---- About Section ----
                SectionHeader { text: "About" }

                SettingsItem {
                    Layout.preferredHeight: aboutColumn.height + 32

                    ColumnLayout {
                        id: aboutColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 6

                        Text {
                            text: "NosnikLocate v1.0.0"
                            font.pixelSize: 15
                            font.weight: Font.Medium
                            color: "#FFFFFF"
                        }
                        Text {
                            text: "Nosniktaj Organisation"
                            font.pixelSize: 13
                            color: "#B0B0B0"
                        }
                        Text {
                            text: "Built with FOSS ❤️"
                            font.pixelSize: 13
                            color: "#BB86FC"
                        }
                        Text {
                            text: "<a href='#'>Privacy Policy</a>"
                            textFormat: Text.RichText
                            font.pixelSize: 12
                            color: "#B0B0B0"
                            linkColor: "#BB86FC"
                        }
                    }
                }

                // Bottom spacer
                Item { Layout.preferredHeight: 20 }
            }
        }
    }

    // ---- Section Header Component ----
    component SectionHeader: Item {
        property string text: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 42

        Text {
            text: parent.text
            font.pixelSize: 13
            font.weight: Font.Bold
            color: "#BB86FC"
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            textFormat: Text.PlainText
        }
    }

    // ---- Settings Item Component ----
    component SettingsItem: Item {
        default property alias content: itemContent.data
        Layout.fillWidth: true
        Layout.preferredHeight: 56

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: 10
            color: "#1E1E3A"

            Item {
                id: itemContent
                anchors.fill: parent
            }
        }
    }

    // ---- Change Password Dialog ----
    Dialog {
        id: changePasswordDialog
        title: "Change Password"
        modal: true
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width - 48, 340)
        Material.theme: Material.Dark
        Material.accent: "#BB86FC"

        background: Rectangle {
            radius: 16
            color: "#16213E"
            border.width: 1
            border.color: "#333355"
        }

        header: Item {
            height: 50
            Text {
                text: "Change Password"
                font.pixelSize: 18; font.weight: Font.Bold; color: "#FFFFFF"
                anchors.centerIn: parent
            }
        }

        contentItem: ColumnLayout {
            spacing: 12

            NosnikTextField {
                id: oldPasswordField
                placeholderText: "Current Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }
            NosnikTextField {
                id: newPasswordField
                placeholderText: "New Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }

            Text {
                id: passwordChangeError
                font.pixelSize: 12
                color: "#CF6679"
                visible: text !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 12
                Layout.fillWidth: true
                NosnikButton {
                    text: "Cancel"
                    buttonColor: "#333355"
                    Layout.fillWidth: true
                    onClicked: changePasswordDialog.close()
                }
                NosnikButton {
                    text: "Change"
                    Layout.fillWidth: true
                    onClicked: {
                        if (newPasswordField.text.length < 8) {
                            passwordChangeError.text = "Password must be at least 8 characters";
                            return;
                        }
                        UserManager.changePassword(oldPasswordField.text, newPasswordField.text);
                        changePasswordDialog.close();
                    }
                }
            }
        }

        onOpened: {
            oldPasswordField.text = "";
            newPasswordField.text = "";
            passwordChangeError.text = "";
        }
    }

    // ---- Delete Account Dialog ----
    Dialog {
        id: deleteAccountDialog
        title: "Delete Account"
        modal: true
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width - 48, 340)
        Material.theme: Material.Dark

        background: Rectangle {
            radius: 16
            color: "#16213E"
            border.width: 1
            border.color: "#CF6679"
        }

        header: Item {
            height: 50
            Text {
                text: "⚠ Delete Account"
                font.pixelSize: 18; font.weight: Font.Bold; color: "#CF6679"
                anchors.centerIn: parent
            }
        }

        contentItem: ColumnLayout {
            spacing: 16

            Text {
                text: "Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently removed."
                font.pixelSize: 14
                color: "#B0B0B0"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 12
                Layout.fillWidth: true
                NosnikButton {
                    text: "Cancel"
                    buttonColor: "#333355"
                    Layout.fillWidth: true
                    onClicked: deleteAccountDialog.close()
                }
                NosnikButton {
                    text: "Delete"
                    buttonColor: "#CF6679"
                    Layout.fillWidth: true
                    onClicked: {
                        UserManager.deleteAccount();
                        deleteAccountDialog.close();
                    }
                }
            }
        }
    }
}
