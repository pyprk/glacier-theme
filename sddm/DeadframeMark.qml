import QtQuick

// DEADFRAME mark: letter-spaced mono text in a thin frame whose bottom-right
// corner is missing. The missing corner blinks back for 120 ms now and then.
Item {
    id: root

    property real u: 1
    property color color: "#7c8ba3"
    property color blinkColor: "#6fcdf5"
    property real frameOpacity: 0.55
    property int every: 40000

    readonly property real lw: Math.max(1, Math.round(u))
    readonly property real pad: 10 * u

    implicitWidth: label.implicitWidth + 2 * pad
    implicitHeight: label.implicitHeight + 1.3 * pad
    width: implicitWidth
    height: implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: 1.5 * root.u   // trailing letter-spacing
        text: "DEADFRAME"
        color: root.color
        font.family: "IBM Plex Mono"
        font.pixelSize: 10 * root.u
        font.letterSpacing: 3 * root.u
    }

    Rectangle { x: 0; y: 0; width: parent.width; height: root.lw; color: root.color; opacity: root.frameOpacity }
    Rectangle { x: 0; y: 0; width: root.lw; height: parent.height; color: root.color; opacity: root.frameOpacity }
    Rectangle { x: parent.width - root.lw; y: 0; width: root.lw; height: parent.height * 0.5; color: root.color; opacity: root.frameOpacity }
    Rectangle { x: 0; y: parent.height - root.lw; width: parent.width * 0.7; height: root.lw; color: root.color; opacity: root.frameOpacity }

    Rectangle {
        id: corner
        x: parent.width - root.lw
        y: parent.height - root.lw
        width: root.lw
        height: root.lw
        color: root.blinkColor
        opacity: 0
    }

    // a dead frame: one letter drops out and the missing corner lights up
    function flash() {
        const i = 1 + Math.floor(Math.random() * 7);
        label.text = "DEADFRAME".substring(0, i) + " " + "DEADFRAME".substring(i + 1);
        corner.opacity = 1;
        off.restart();
    }

    Timer {
        running: true
        repeat: true
        interval: root.every * (0.5 + Math.random())
        onTriggered: {
            interval = root.every * (0.5 + Math.random());
            root.flash();
        }
    }

    Timer { id: off; interval: 120; onTriggered: { corner.opacity = 0; label.text = "DEADFRAME" } }
}
