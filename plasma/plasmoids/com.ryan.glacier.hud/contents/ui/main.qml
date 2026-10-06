import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property date now: new Date()
    readonly property bool use12h: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("ap") !== -1

    function num(v) {
        const n = Number(v);
        return isNaN(n) ? 0 : n;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Sensors.Sensor { id: cpu; sensorId: "cpu/all/usage"; updateRateLimit: 2000 }
    Sensors.Sensor { id: temp; sensorId: "cpu/all/averageTemperature"; updateRateLimit: 2000 }
    Sensors.Sensor { id: mem; sensorId: "memory/physical/usedPercent"; updateRateLimit: 2000 }
    Sensors.Sensor { id: gpu; sensorId: "gpu/all/usage"; updateRateLimit: 2000 }
    Sensors.Sensor { id: disk; sensorId: "disk/all/usedPercent"; updateRateLimit: 30000 }
    Sensors.Sensor { id: down; sensorId: "network/all/download"; updateRateLimit: 2000 }
    Sensors.Sensor { id: up; sensorId: "network/all/upload"; updateRateLimit: 2000 }

    fullRepresentation: Item {
        Layout.minimumWidth: 280
        Layout.minimumHeight: 300
        Layout.preferredWidth: 340
        Layout.preferredHeight: 330

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            RowLayout {
                spacing: 8

                GlitchText {
                    text: Qt.formatTime(root.now, root.use12h ? "h:mm AP" : "HH:mm").split(" ")[0]
                    color: Kirigami.Theme.textColor
                    tearColor: Kirigami.Theme.hoverColor
                    every: 75000
                    font.family: "IBM Plex Sans"
                    font.weight: Font.Light
                    font.pixelSize: 84
                    Layout.alignment: Qt.AlignBaseline
                }

                Text {
                    visible: root.use12h
                    text: Qt.formatTime(root.now, "AP")
                    color: Kirigami.Theme.disabledTextColor
                    font.family: "IBM Plex Mono"
                    font.pixelSize: 14
                    font.letterSpacing: 1.5
                    Layout.alignment: Qt.AlignBaseline
                }
            }

            Text {
                text: Qt.formatDate(root.now, "dddd  ·  dd MMM yyyy").toUpperCase()
                color: Kirigami.Theme.focusColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 13
                font.letterSpacing: 2
                Layout.topMargin: -4
                Layout.leftMargin: 4
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 20
                Layout.bottomMargin: 18
                Layout.leftMargin: 4
                implicitHeight: 1
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
            }

            ColumnLayout {
                Layout.leftMargin: 4
                Layout.fillWidth: true
                spacing: 13

                Meter { Layout.fillWidth: true; label: "CPU"; value: root.num(cpu.value); readout: Math.round(value) + "%" }
                Meter { Layout.fillWidth: true; label: "TMP"; value: root.num(temp.value); readout: Math.round(value) + "°C"; barColor: Kirigami.Theme.hoverColor }
                Meter { Layout.fillWidth: true; label: "MEM"; value: root.num(mem.value); readout: Math.round(value) + "%" }
                Meter { Layout.fillWidth: true; label: "GPU"; value: root.num(gpu.value); readout: Math.round(value) + "%" }
                Meter { Layout.fillWidth: true; label: "DSK"; value: root.num(disk.value); readout: Math.round(value) + "%" }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        text: "NET"
                        color: Kirigami.Theme.disabledTextColor
                        font.family: "IBM Plex Mono"
                        font.pixelSize: 12
                        font.letterSpacing: 1.5
                        Layout.preferredWidth: 36
                    }

                    Text {
                        text: "↓ " + (down.formattedValue || "–") + "   ↑ " + (up.formattedValue || "–")
                        color: Kirigami.Theme.textColor
                        font.family: "IBM Plex Mono"
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
