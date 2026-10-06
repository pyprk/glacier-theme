import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    property var servers: []
    property bool loaded: false
    readonly property string command: "python3 \"" + Qt.resolvedUrl("../code/probe.py").toString().replace("file://", "") + "\""

    readonly property color up: "#7fcf9a"
    readonly property color down: "#e8697a"

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: (source, data) => {
            try {
                root.servers = JSON.parse(data["stdout"]);
                root.loaded = true;
            } catch (e) {
                // keep the previous readout if the probe produced nothing usable
            }
            disconnectSource(source);
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: runner.connectSource(root.command)
    }

    fullRepresentation: Item {
        Layout.minimumWidth: 280
        Layout.minimumHeight: 120
        Layout.preferredWidth: 340
        Layout.preferredHeight: 60 + Math.max(1, root.servers.length) * 50

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            anchors.leftMargin: 16
            spacing: 0

            Text {
                text: "SERVERS"
                color: Kirigami.Theme.disabledTextColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 12
                font.letterSpacing: 2
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 14
                implicitHeight: 1
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.14)
            }

            Text {
                visible: root.loaded && root.servers.length === 0
                text: "No servers in ~/.config/glacier/servers.json"
                color: Kirigami.Theme.disabledTextColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 11
            }

            Repeater {
                model: root.servers

                ColumnLayout {
                    required property var modelData
                    readonly property bool isUp: modelData.up === true
                    readonly property bool isMinecraft: modelData.type === "minecraft"
                    readonly property var names: modelData.players || []

                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            implicitWidth: 7
                            implicitHeight: 7
                            radius: 3.5
                            color: isUp ? root.up : root.down

                            Rectangle {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                radius: 7.5
                                color: parent.color
                                opacity: 0.18
                            }
                        }

                        Text {
                            text: modelData.name
                            color: Kirigami.Theme.textColor
                            font.family: "IBM Plex Sans"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: isUp ? (isMinecraft ? modelData.online + " / " + modelData.max
                                                      : (modelData.latency_ms !== undefined && modelData.latency_ms !== null ? modelData.latency_ms + " ms" : "UP"))
                                       : "OFFLINE"
                            color: isUp ? (isMinecraft && modelData.online > 0 ? Kirigami.Theme.focusColor : Kirigami.Theme.textColor)
                                        : Kirigami.Theme.disabledTextColor
                            font.family: "IBM Plex Mono"
                            font.pixelSize: 12
                            font.letterSpacing: 1
                        }
                    }

                    Text {
                        visible: isMinecraft && isUp
                        text: names.length > 0 ? names.join("  ·  ") : "nobody online"
                        color: Kirigami.Theme.disabledTextColor
                        font.family: "IBM Plex Mono"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.leftMargin: 17
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
