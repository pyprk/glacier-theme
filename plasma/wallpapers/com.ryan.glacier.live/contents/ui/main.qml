import QtQuick
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.taskmanager as TaskManager

WallpaperItem {
    id: root

    readonly property bool animate: configuration.Animate
    readonly property bool followTime: configuration.FollowTime
    readonly property int period: Math.max(60, configuration.Period)
    readonly property int fps: 20
    readonly property bool glitch: configuration.Glitch

    property real phase: 0
    property bool covered: false
    property real hour: 0

    // ---- the touch of chaos: one ridge skips sideways for two frames ------
    property real glitchRow: -1
    property real glitchShift: 0

    Timer {
        running: root.glitch && root.animate && !root.covered
        repeat: true
        interval: 15000 + Math.random() * 25000
        onTriggered: {
            interval = 15000 + Math.random() * 25000;
            root.glitchRow = 18 + Math.floor(Math.random() * 44);
            root.glitchShift = (Math.random() < 0.5 ? -1 : 1) * (0.006 + Math.random() * 0.008);
            glitchHeal.restart();
        }
    }

    Timer { id: glitchHeal; interval: 2000 / root.fps; onTriggered: root.glitchRow = -1 }

    // ---- palettes by time of day ----------------------------------------
    readonly property var palettes: ({
        night: { skyTop: [9, 13, 20], skyMid: [13, 19, 29], skyBot: [15, 23, 36],
                 glow: [86, 164, 245, 0.16], horizon: [0, 0, 0, 0],
                 lineFar: [52, 96, 160], lineNear: [96, 176, 248], linePeak: [140, 215, 250], dot: [160, 190, 230] },
        dawn:  { skyTop: [13, 15, 30], skyMid: [24, 24, 44], skyBot: [32, 27, 42],
                 glow: [240, 150, 130, 0.14], horizon: [250, 170, 120, 0.22],
                 lineFar: [120, 96, 150], lineNear: [150, 170, 240], linePeak: [255, 205, 180], dot: [200, 185, 220] },
        day:   { skyTop: [14, 24, 40], skyMid: [22, 38, 60], skyBot: [24, 42, 66],
                 glow: [140, 200, 250, 0.18], horizon: [150, 210, 250, 0.10],
                 lineFar: [70, 120, 180], lineNear: [130, 200, 250], linePeak: [215, 240, 255], dot: [180, 210, 240] },
        dusk:  { skyTop: [12, 12, 28], skyMid: [22, 18, 42], skyBot: [26, 20, 44],
                 glow: [170, 120, 240, 0.16], horizon: [240, 120, 150, 0.20],
                 lineFar: [100, 84, 170], lineNear: [140, 150, 245], linePeak: [245, 180, 215], dot: [190, 180, 230] }
    })
    readonly property var keyframes: [[0, "night"], [5, "night"], [6.5, "dawn"], [9, "day"], [16.5, "day"], [18.5, "dusk"], [20.5, "night"], [24, "night"]]

    function paletteColor(key) {
        if (!followTime) {
            return toColor(palettes.night[key]);
        }
        var h = hour;
        for (var i = 0; i < keyframes.length - 1; i++) {
            var a = keyframes[i], b = keyframes[i + 1];
            if (h >= a[0] && h <= b[0]) {
                var k = (h - a[0]) / Math.max(0.001, b[0] - a[0]);
                return mixColor(palettes[a[1]][key], palettes[b[1]][key], k);
            }
        }
        return toColor(palettes.night[key]);
    }

    function toColor(c) {
        return Qt.rgba(c[0] / 255, c[1] / 255, c[2] / 255, c.length > 3 ? c[3] : 1);
    }

    function mixColor(a, b, k) {
        var aa = a.length > 3 ? a[3] : 1, ba = b.length > 3 ? b[3] : 1;
        return Qt.rgba((a[0] + (b[0] - a[0]) * k) / 255, (a[1] + (b[1] - a[1]) * k) / 255,
                       (a[2] + (b[2] - a[2]) * k) / 255, aa + (ba - aa) * k);
    }

    function updateHour() {
        var d = new Date();
        hour = d.getHours() + d.getMinutes() / 60;
    }

    Component.onCompleted: updateHour()

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.updateHour()
    }

    Timer {
        interval: 1000 / root.fps
        running: root.animate && !root.covered
        repeat: true
        onTriggered: root.phase = (root.phase + (interval / 1000) / root.period) % 1
    }

    // ---- pause while a maximised or fullscreen window hides the desktop --
    TaskManager.VirtualDesktopInfo { id: vdi }
    TaskManager.ActivityInfo { id: ai }
    TaskManager.TasksModel {
        id: tasks
        filterByVirtualDesktop: true
        filterByActivity: true
        filterByScreen: true
        filterMinimized: true
        filterHidden: true
        virtualDesktop: vdi.currentDesktop
        activity: ai.currentActivity
        screenGeometry: Qt.rect(Screen.virtualX, Screen.virtualY, Screen.width, Screen.height)
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    Instantiator {
        id: windows
        model: tasks
        delegate: QtObject {
            readonly property bool covers: (model.IsMaximized === true || model.IsFullScreen === true) && model.IsMinimized !== true
            onCoversChanged: root.recount()
        }
        onObjectAdded: root.recount()
        onObjectRemoved: root.recount()
    }

    function recount() {
        var c = false;
        for (var i = 0; i < windows.count; i++) {
            var o = windows.objectAt(i);
            if (o && o.covers) { c = true; break; }
        }
        covered = c;
    }

    // ---- render -----------------------------------------------------------
    Image {
        id: fieldImage
        source: Qt.resolvedUrl("../images/field.png")
        visible: false
        smooth: true
        mipmap: false
    }

    Rectangle {
        anchors.fill: parent
        color: root.paletteColor("skyMid")
    }

    ShaderEffect {
        id: fx
        anchors.fill: parent

        readonly property real dpr: Screen.devicePixelRatio || 1
        readonly property real cap: Math.min(1, 2560 / Math.max(1, width * dpr))
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(Math.max(1, Math.round(width * dpr * cap)), Math.max(1, Math.round(height * dpr * cap)))

        property real phase: root.phase
        property size res: Qt.size(layer.textureSize.width, layer.textureSize.height)
        property variant field: fieldImage
        property color skyTop: root.paletteColor("skyTop")
        property color skyMid: root.paletteColor("skyMid")
        property color skyBot: root.paletteColor("skyBot")
        property color glowCol: root.paletteColor("glow")
        property color horizonCol: root.paletteColor("horizon")
        property color lineFar: root.paletteColor("lineFar")
        property color lineNear: root.paletteColor("lineNear")
        property color linePeak: root.paletteColor("linePeak")
        property color dotCol: root.paletteColor("dot")
        property real glitchRow: root.glitchRow
        property real glitchShift: root.glitchShift

        fragmentShader: Qt.resolvedUrl("../shaders/terrain.frag.qsb")

        Behavior on skyTop { ColorAnimation { duration: 2000 } }
        Behavior on skyMid { ColorAnimation { duration: 2000 } }
        Behavior on skyBot { ColorAnimation { duration: 2000 } }
        Behavior on glowCol { ColorAnimation { duration: 2000 } }
        Behavior on horizonCol { ColorAnimation { duration: 2000 } }
        Behavior on lineFar { ColorAnimation { duration: 2000 } }
        Behavior on lineNear { ColorAnimation { duration: 2000 } }
        Behavior on linePeak { ColorAnimation { duration: 2000 } }
        Behavior on dotCol { ColorAnimation { duration: 2000 } }
    }

    DeadframeMark {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28 * u
        u: Math.min(2, Math.max(1, root.height / 1080))
        color: root.paletteColor("lineNear")
        blinkColor: root.paletteColor("linePeak")
        frameOpacity: 0.45
        opacity: 0.55
    }
}
