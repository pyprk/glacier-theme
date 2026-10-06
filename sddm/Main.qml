import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: "#0b0f16"

    // scale everything from a 1080p design height
    readonly property real u: Math.max(1, height / 1080)

    readonly property color textColor: "#d8e1ee"
    readonly property color dimColor: "#7c8ba3"
    readonly property color accent: "#56a4f5"
    readonly property color ice: "#6fcdf5"
    readonly property color surface: "#1c2432"
    readonly property color red: "#e8697a"

    property int sessionIndex: sessionModel.lastIndex
    property date now: new Date()

    function login() {
        message.text = "";
        sddm.login(user.text, password.text, root.sessionIndex);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "LOGIN FAILED";
            password.text = "";
            password.forceActiveFocus();
        }
    }

    Image {
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Column {
        id: form
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.height * 0.14
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(root.now, "h:mm AP").split(" ")[0]
            color: root.textColor
            font.family: "IBM Plex Sans"
            font.weight: Font.Light
            font.pixelSize: 112 * root.u
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(root.now, "dddd  ·  dd MMM yyyy").toUpperCase()
            color: root.accent
            font.family: "IBM Plex Mono"
            font.pixelSize: 14 * root.u
            font.letterSpacing: 2.5 * root.u
        }

        Item { width: 1; height: 56 * root.u }

        TextInput {
            id: user
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300 * root.u
            horizontalAlignment: TextInput.AlignHCenter
            text: userModel.lastUser
            color: root.textColor
            selectionColor: root.accent
            font.family: "IBM Plex Mono"
            font.pixelSize: 14 * root.u
            font.letterSpacing: 2 * root.u
            clip: true
            KeyNavigation.tab: password
            Keys.onReturnPressed: password.forceActiveFocus()
            Keys.onEnterPressed: password.forceActiveFocus()

            Text {
                anchors.centerIn: parent
                visible: user.text.length === 0
                text: "USERNAME"
                color: root.dimColor
                opacity: 0.7
                font: user.font
            }
        }

        Item { width: 1; height: 14 * root.u }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300 * root.u
            height: 42 * root.u
            radius: 6 * root.u
            color: Qt.rgba(28 / 255, 36 / 255, 50 / 255, 0.85)
            border.width: Math.max(1, Math.round(root.u))
            border.color: password.activeFocus ? root.accent : "#2a3547"

            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 14 * root.u
                anchors.rightMargin: 14 * root.u
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.textColor
                selectionColor: root.accent
                font.family: "IBM Plex Mono"
                font.pixelSize: 16 * root.u
                font.letterSpacing: 3 * root.u
                clip: true
                focus: true
                KeyNavigation.backtab: user
                Keys.onReturnPressed: root.login()
                Keys.onEnterPressed: root.login()
            }

            Text {
                anchors.centerIn: parent
                visible: password.text.length === 0
                text: "PASSWORD"
                color: root.dimColor
                opacity: 0.7
                font.family: "IBM Plex Mono"
                font.pixelSize: 12 * root.u
                font.letterSpacing: 2.5 * root.u
            }
        }

        Item { width: 1; height: 16 * root.u }

        Text {
            id: message
            anchors.horizontalCenter: parent.horizontalCenter
            height: 16 * root.u
            color: root.red
            font.family: "IBM Plex Mono"
            font.pixelSize: 12 * root.u
            font.letterSpacing: 2 * root.u
        }
    }

    // session picker: click to cycle
    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.u
        spacing: 12 * root.u

        Text {
            text: "SESSION"
            color: root.dimColor
            font.family: "IBM Plex Mono"
            font.pixelSize: 12 * root.u
            font.letterSpacing: 2 * root.u
        }

        ListView {
            id: sessions
            width: 320 * root.u
            height: 18 * root.u
            model: sessionModel
            currentIndex: root.sessionIndex
            orientation: ListView.Horizontal
            interactive: false
            clip: true
            highlightRangeMode: ListView.StrictlyEnforceRange
            highlightMoveDuration: 0
            delegate: Text {
                width: sessions.width
                height: sessions.height
                text: (model.name || "").toUpperCase()
                color: sessionArea.containsMouse ? root.ice : root.textColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 12 * root.u
                font.letterSpacing: 2 * root.u
                elide: Text.ElideRight
            }

            MouseArea {
                id: sessionArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.sessionIndex = (root.sessionIndex + 1) % Math.max(1, sessions.count)
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.u
        spacing: 32 * root.u

        Repeater {
            model: [
                { label: "SLEEP", show: sddm.canSuspend, act: 0 },
                { label: "RESTART", show: sddm.canReboot, act: 1 },
                { label: "SHUT DOWN", show: sddm.canPowerOff, act: 2 }
            ]

            Text {
                visible: modelData.show
                text: modelData.label
                color: powerArea.containsMouse ? root.ice : root.dimColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 12 * root.u
                font.letterSpacing: 2 * root.u

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: powerArea
                    anchors.fill: parent
                    anchors.margins: -8 * root.u
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.act === 0) sddm.suspend();
                        else if (modelData.act === 1) sddm.reboot();
                        else sddm.powerOff();
                    }
                }
            }
        }
    }

    Component.onCompleted: (user.text.length > 0 ? password : user).forceActiveFocus()
}
