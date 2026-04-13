import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0
import "components"

Page {
    id: verifyPage

    property string username: ""

    signal verificationComplete()
    signal backToLogin()

    property bool isLoading: false
    property string errorMessage: ""
    property string successMessage: ""

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
            anchors.topMargin: 60
            width: Math.min(parent.width - 48, 340)
            spacing: 0

            // Email icon
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                Layout.bottomMargin: 20

                Rectangle {
                    width: 72
                    height: 72
                    radius: 36
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#BB86FC" }
                        GradientStop { position: 1.0; color: "#9C27B0" }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "✉"
                        font.pixelSize: 32
                    }
                }
            }

            // Title
            Text {
                text: "Verify Your Email"
                font.pixelSize: 24
                font.weight: Font.Bold
                color: "#FFFFFF"
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 8
            }

            Text {
                text: "We sent a 6-digit code to your email.\nPlease enter it below."
                font.pixelSize: 14
                color: "#B0B0B0"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.bottomMargin: 28
            }

            // Verification code field
            NosnikTextField {
                id: codeField
                placeholderText: "6-digit code"
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                horizontalAlignment: TextInput.AlignHCenter
                font.pixelSize: 24
                font.weight: Font.Bold
                font.letterSpacing: 8
                maximumLength: 6
                inputMethodHints: Qt.ImhDigitsOnly
                validator: RegularExpressionValidator { regularExpression: /[0-9]{0,6}/ }
                onAccepted: doVerify()
            }

            // Error message
            Text {
                text: verifyPage.errorMessage
                font.pixelSize: 13
                color: "#CF6679"
                visible: verifyPage.errorMessage !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                horizontalAlignment: Text.AlignHCenter

                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Success message
            Text {
                text: verifyPage.successMessage
                font.pixelSize: 13
                color: "#03DAC6"
                visible: verifyPage.successMessage !== ""
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                horizontalAlignment: Text.AlignHCenter

                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            // Verify button
            NosnikButton {
                text: verifyPage.isLoading ? "" : "Verify"
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                Layout.topMargin: 8
                Layout.bottomMargin: 12
                enabled: !verifyPage.isLoading
                onClicked: doVerify()

                BusyIndicator {
                    anchors.centerIn: parent
                    running: verifyPage.isLoading
                    visible: verifyPage.isLoading
                    Material.accent: "#FFFFFF"
                    width: 28
                    height: 28
                }
            }

            // Resend code link
            Text {
                text: "Didn't receive a code? <b><font color='#BB86FC'>Resend</font></b>"
                textFormat: Text.RichText
                font.pixelSize: 14
                color: "#B0B0B0"
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 16

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        verifyPage.errorMessage = "";
                        verifyPage.successMessage = "";
                        UserManager.resendVerification(verifyPage.username);
                    }
                }
            }

            // Back to login link
            Text {
                text: "<b><font color='#BB86FC'>← Back to Sign In</font></b>"
                textFormat: Text.RichText
                font.pixelSize: 14
                color: "#B0B0B0"
                Layout.alignment: Qt.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: verifyPage.backToLogin()
                }
            }
        }
    }

    function doVerify() {
        var code = codeField.text.trim();
        if (code.length !== 6) {
            verifyPage.errorMessage = "Please enter the 6-digit verification code";
            return;
        }
        verifyPage.isLoading = true;
        verifyPage.errorMessage = "";
        verifyPage.successMessage = "";
        UserManager.verifyEmail(verifyPage.username, code);
    }

    Connections {
        target: UserManager
        function onEmailVerificationSuccess() {
            verifyPage.isLoading = false;
            verifyPage.errorMessage = "";
            verifyPage.successMessage = "Email verified! You can now sign in.";
            // Auto-redirect after a short delay
            verificationTimer.start();
        }
        function onEmailVerificationFailed(reason) {
            verifyPage.isLoading = false;
            verifyPage.errorMessage = reason;
        }
        function onVerificationResent() {
            verifyPage.successMessage = "A new code has been sent to your email.";
        }
        function onVerificationResendFailed(reason) {
            verifyPage.errorMessage = reason;
        }
    }

    Timer {
        id: verificationTimer
        interval: 1500
        repeat: false
        onTriggered: verifyPage.verificationComplete()
    }

    // Fade-in animation
    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
}
