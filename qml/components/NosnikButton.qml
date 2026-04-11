import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: control

    property color buttonColor: "#BB86FC"
    property color pressedColor: "#9C27B0"
    property color textColor: "#FFFFFF"
    property string iconSource: ""
    property real radius: 12

    font.pixelSize: 16
    font.weight: Font.Medium
    font.capitalization: Font.MixedCase

    icon.color: textColor

    Material.background: buttonColor
    Material.foreground: textColor

    contentItem: Row {
        spacing: 8
        anchors.centerIn: parent

        Text {
            visible: control.iconSource !== ""
            text: control.iconSource
            font.pixelSize: 18
            font.family: "Segoe Fluent Icons, Segoe MDL2 Assets, Material Icons"
            color: control.textColor
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: control.text
            font: control.font
            color: control.textColor
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 48
        radius: control.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: control.down ? control.pressedColor : control.buttonColor }
            GradientStop { position: 1.0; color: control.down ? Qt.darker(control.pressedColor, 1.1) : Qt.darker(control.buttonColor, 1.15) }
        }
        opacity: control.enabled ? 1.0 : 0.5

        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    scale: down ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
}
