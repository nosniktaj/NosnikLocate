import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0
import "components"

Page {
    id: registerPage

    signal loginRequested()

    property bool isLoading: false
    property string errorMessage: ""

    background: Rectangle { color: "#1A1A2E" }

    Flickable {
        anchors.fill: parent
        contentHeight: contentColumn.height + 80
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: contentColumn
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            width: Math.min(parent.width - 48, 340)
            spacing: 0

            // Header
            Text {
                text: "Create Account"
                font.pixelSize: 26
                font.weight: Font.Bold
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
            }

            Text {
                text: "Join NosnikLocate"
                font.pixelSize: 14
                color: "#B0B0B0"
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 28
            }

            NosnikTextField {
                id: usernameField
                placeholderText: "Username *"
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                onAccepted: emailField.forceActiveFocus()
            }

            NosnikTextField {
                id: emailField
                placeholderText: "Email *"
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                inputMethodHints: Qt.ImhEmailCharactersOnly
                onAccepted: displayNameField.forceActiveFocus()
            }

            NosnikTextField {
                id: displayNameField
                placeholderText: "Display Name"
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                onAccepted: passwordField.forceActiveFocus()
            }

            NosnikTextField {
                id: passwordField
                placeholderText: "Password *"
                echoMode: TextInput.Password
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                onAccepted: confirmPasswordField.forceActiveFocus()
            }

            NosnikTextField {
                id: confirmPasswordField
                placeholderText: "Confirm Password *"
                echoMode: TextInput.Password
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                onAccepted: doRegister()
            }

            // Error message
            Text {
                text: registerPage.errorMessage
                font.pixelSize: 13
                color: "#CF6679"
                visible: registerPage.errorMessage !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                horizontalAlignment: Text.AlignHCenter

                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Register button
            NosnikButton {
                text: registerPage.isLoading ? "" : "Create Account"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.bottomMargin: 16
                enabled: !registerPage.isLoading
                onClicked: doRegister()

                BusyIndicator {
                    anchors.centerIn: parent
                    running: registerPage.isLoading
                    visible: registerPage.isLoading
                    Material.accent: "#FFFFFF"
                    width: 28
                    height: 28
                }
            }

            // Login link
            Text {
                text: "Already have an account? <b><font color='#BB86FC'>Sign In</font></b>"
                textFormat: Text.RichText
                font.pixelSize: 14
                color: "#B0B0B0"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: registerPage.loginRequested()
                }
            }
        }
    }

    function doRegister() {
        var uname = usernameField.text.trim();
        var email = emailField.text.trim();
        var dname = displayNameField.text.trim();
        var pass = passwordField.text;
        var confirmPass = confirmPasswordField.text;

        if (uname === "" || email === "" || pass === "") {
            registerPage.errorMessage = "Please fill in all required fields";
            return;
        }

        // Basic email format check
        var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            registerPage.errorMessage = "Please enter a valid email address";
            return;
        }

        if (pass.length < 6) {
            registerPage.errorMessage = "Password must be at least 6 characters";
            return;
        }

        if (pass !== confirmPass) {
            registerPage.errorMessage = "Passwords do not match";
            return;
        }

        registerPage.isLoading = true;
        registerPage.errorMessage = "";
        UserManager.registerUser(uname, email, pass, dname !== "" ? dname : uname);
    }

    Connections {
        target: UserManager
        function onRegistrationSuccess() {
            registerPage.isLoading = false;
            registerPage.errorMessage = "";
        }
        function onRegistrationFailed(reason) {
            registerPage.isLoading = false;
            registerPage.errorMessage = reason;
        }
    }

    // Fade-in animation
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
}
