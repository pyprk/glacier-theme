import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: meter

    property string label
    property real value: 0      // 0–100
    property string readout
    property color barColor: Kirigami.Theme.focusColor

    spacing: 14

    Text {
        text: meter.label
        color: Kirigami.Theme.disabledTextColor
        font.family: "IBM Plex Mono"
        font.pixelSize: 12
        font.letterSpacing: 1.5
        Layout.preferredWidth: 36
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: 3
        radius: 1.5
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, meter.value / 100))
            height: parent.height
            radius: parent.radius
            color: meter.barColor

            Behavior on width {
                NumberAnimation { duration: 700; easing.type: Easing.OutCubic }
            }
        }
    }

    Text {
        text: meter.readout
        color: Kirigami.Theme.textColor
        font.family: "IBM Plex Mono"
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        Layout.preferredWidth: 46
    }
}
