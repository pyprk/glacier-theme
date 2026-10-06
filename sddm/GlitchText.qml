import QtQuick

// Text with a rare tear: every `every` ms (±40 %), a horizontal slice of the
// glyphs jumps sideways in the tear colour for ~80 ms, then heals.
Item {
    id: root

    property alias text: src.text
    property alias font: src.font
    property alias color: src.color
    property color tearColor: "#6fcdf5"
    property real u: 1
    property int every: 30000
    property bool active: true

    property bool torn: false
    property real sy: 0
    property real sh: 0
    property real dx: 0

    implicitWidth: src.implicitWidth
    implicitHeight: src.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Text { id: src; visible: !root.torn }

    Item {
        visible: root.torn
        clip: true
        width: root.width
        height: root.sy
        Text { text: src.text; font: src.font; color: src.color }
    }

    Item {
        visible: root.torn
        clip: true
        x: root.dx
        y: root.sy
        width: root.width
        height: root.sh
        Text { y: -root.sy; text: src.text; font: src.font; color: root.tearColor }
    }

    Item {
        visible: root.torn
        clip: true
        y: root.sy + root.sh
        width: root.width
        height: Math.max(0, root.height - root.sy - root.sh)
        Text { y: -(root.sy + root.sh); text: src.text; font: src.font; color: src.color }
    }

    Timer {
        id: schedule
        running: root.active
        repeat: true
        interval: root.every * (0.6 + Math.random() * 0.8)
        onTriggered: {
            interval = root.every * (0.6 + Math.random() * 0.8);
            root.sy = Math.round(root.height * (0.15 + Math.random() * 0.6));
            root.sh = Math.round(root.height * (0.08 + Math.random() * 0.14));
            root.dx = (Math.random() < 0.5 ? -1 : 1) * Math.round((4 + Math.random() * 8) * root.u);
            root.torn = true;
            heal.restart();
        }
    }

    Timer { id: heal; interval: 80; onTriggered: root.torn = false }
}
