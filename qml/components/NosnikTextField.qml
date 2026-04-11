import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

TextField {
    id: control

    property color backgroundColor: "#1E1E3A"
    property color focusBorderColor: "#BB86FC"
    property color unfocusBorderColor: "#333355"
    property color placeholderColor: "#B0B0B0"
    property color inputTextColor: "#FFFFFF"

    color: inputTextColor
    placeholderTextColor: placeholderColor
    font.pixelSize: 15
    leftPadding: 16
    rightPadding: 16
    topPadding: 14
    bottomPadding: 14

    Material.accent: focusBorderColor
    Material.foreground: inputTextColor

    background: Rectangle {
        implicitWidth: 280
        implicitHeight: 50
        radius: 10
        color: control.backgroundColor
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? control.focusBorderColor : control.unfocusBorderColor

        Behavior on border.color { ColorAnimation { duration: 200 } }
        Behavior on border.width { NumberAnimation { duration: 150 } }
    }
}
