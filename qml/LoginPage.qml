import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0
import "components"

Page {
    id: loginPage

    signal registerRequested()

    property bool isLoading: false
    property string errorMessage: ""

    background: Rectangle { color: "#1A1A2E" }

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + 80
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 60
            width: Math.min(parent.width - 48, 340)
            spacing: 0

            // Logo area
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                Layout.bottomMargin: 20

                Rectangle {
                    width: 80
                    height: 80
                    radius: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#BB86FC" }
                        GradientStop { position: 1.0; color: "#9C27B0" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "📍"
                        font.pixelSize: 36
                    }

                    SequentialAnimation on scale {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.05; duration: 1500; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.05; to: 1.0; duration: 1500; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    text: "NosnikLocate"
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: subtitleText.top
                    anchors.bottomMargin: 4
                }

                Text {
                    id: subtitleText
                    text: "Share your world"
                    font.pixelSize: 14
                    color: "#B0B0B0"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                }
            }

            // Username field
            NosnikTextField {
                id: usernameField
                placeholderText: "Username"
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                onAccepted: passwordField.forceActiveFocus()
            }

            // Password field
            NosnikTextField {
                id: passwordField
                placeholderText: "Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                onAccepted: doLogin()
            }

            // Error message
            Text {
                text: loginPage.errorMessage
                font.pixelSize: 13
                color: "#CF6679"
                visible: loginPage.errorMessage !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                horizontalAlignment: Text.AlignHCenter

                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Login button
            NosnikButton {
                text: loginPage.isLoading ? "" : "Sign In"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.bottomMargin: 16
                enabled: !loginPage.isLoading
                onClicked: doLogin()

                BusyIndicator {
                    anchors.centerIn: parent
                    running: loginPage.isLoading
                    visible: loginPage.isLoading
                    Material.accent: "#FFFFFF"
                    width: 28
                    height: 28
                }
            }

            // Register link
            Text {
                text: "Don't have an account? <b><font color='#BB86FC'>Register</font></b>"
                textFormat: Text.RichText
                font.pixelSize: 14
                color: "#B0B0B0"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: loginPage.registerRequested()
                }
            }
        }
    }

    function doLogin() {
        var uname = usernameField.text.trim();
        var pass = passwordField.text;
        if (uname === "" || pass === "") {
            loginPage.errorMessage = "Please enter username and password";
            return;
        }
        loginPage.isLoading = true;
        loginPage.errorMessage = "";
        UserManager.login(uname, pass);
    }

    Connections {
        target: UserManager
        function onLoginSuccess() {
            loginPage.isLoading = false;
            loginPage.errorMessage = "";
        }
        function onLoginFailed(reason) {
            loginPage.isLoading = false;
            loginPage.errorMessage = reason;
        }
    }

    // Fade-in animation
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
}
