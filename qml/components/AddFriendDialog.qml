import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import NosnikLocate 1.0

Dialog {
    id: root

    property string errorMessage: ""

    signal friendRequested(string username)

    title: "Add Friend"
    modal: true
    standardButtons: Dialog.NoButton

    Material.theme: Material.Dark
    Material.accent: "#BB86FC"

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width - 48, 360)

    background: Rectangle {
        radius: 16
        color: "#16213E"
        border.width: 1
        border.color: "#333355"
    }

    header: Item {
        height: 56
        Text {
            text: "Add Friend"
            font.pixelSize: 20
            font.weight: Font.Bold
            color: "#FFFFFF"
            anchors.centerIn: parent
        }
    }

    contentItem: ColumnLayout {
        spacing: 16

        Text {
            text: "Enter their username to send a friend request"
            font.pixelSize: 13
            color: "#B0B0B0"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        NosnikTextField {
            id: usernameField
            placeholderText: "Username"
            Layout.fillWidth: true
            onAccepted: sendRequest()
        }

        Text {
            text: root.errorMessage
            font.pixelSize: 12
            color: "#CF6679"
            visible: root.errorMessage !== ""
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            NosnikButton {
                text: "Cancel"
                buttonColor: "#333355"
                Layout.fillWidth: true
                onClicked: root.close()
            }

            NosnikButton {
                text: "Send Request"
                Layout.fillWidth: true
                onClicked: sendRequest()
            }
        }
    }

    function sendRequest() {
        var uname = usernameField.text.trim();
        if (uname === "") {
            root.errorMessage = "Please enter a username";
            return;
        }
        root.errorMessage = "";
        root.friendRequested(uname);
        usernameField.text = "";
        root.close();
    }

    onOpened: {
        usernameField.text = "";
        root.errorMessage = "";
        usernameField.forceActiveFocus();
    }
}
