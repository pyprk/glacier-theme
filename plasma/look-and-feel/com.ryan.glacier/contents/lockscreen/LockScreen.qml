import QtQuick
import QtQuick.Window
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.sessions
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator

// Glacier lock screen. The wallpaper is drawn by kscreenlocker behind this;
// kscreenlocker provides `authenticator` and `kscreenlocker_userName`.
Item {
    id: root

    property bool debug: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()
    property bool viewVisible: false
    property bool suspendToRamSupported: false
    property bool suspendToDiskSupported: false
    signal suspendToDisk()
    signal suspendToRam()

    implicitWidth: 800
    implicitHeight: 600

    readonly property real u: Math.max(1, height / 1080)
    readonly property color textColor: "#d8e1ee"
    readonly property color dimColor: "#7c8ba3"
    readonly property color accent: "#56a4f5"
    readonly property color ice: "#6fcdf5"
    readonly property color red: "#e8697a"

    property date now: new Date()
    property string message

    function unlock() {
        if (authenticator.graceLocked || password.text.length === 0) {
            return;
        }
        root.message = "";
        authenticator.respond(password.text);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Timer {
        id: messageTimer
        interval: 3000
        onTriggered: root.message = ""
    }

    Timer {
        id: graceTimer
        interval: 3000
        onTriggered: {
            password.text = "";
            authenticator.startAuthenticating();
        }
    }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind !== 0) {
                return;
            }
            root.message = "UNLOCK FAILED";
            password.text = "";
            shake.restart();
            graceTimer.restart();
            messageTimer.restart();
        }
        function onSucceeded() {
            Qt.quit();
        }
        function onPromptForSecretChanged() {
            password.forceActiveFocus();
        }
        function onInfoMessageChanged() {
            if (authenticator.infoMessage) {
                root.message = authenticator.infoMessage.toUpperCase();
                messageTimer.restart();
            }
        }
        function onErrorMessageChanged() {
            if (authenticator.errorMessage) {
                root.message = authenticator.errorMessage.toUpperCase();
                messageTimer.restart();
            }
        }
    }

    onClearPassword: password.text = ""
    onViewVisibleChanged: if (viewVisible) { password.forceActiveFocus(); }

    SessionManagement {
        id: sessionManagement
    }

    KeyboardIndicator.KeyState {
        id: capsLock
        key: Qt.Key_CapsLock
    }

    Component.onCompleted: {
        authenticator.startAuthenticating();
        password.forceActiveFocus();
    }

    // darken the wallpaper slightly so text stays readable in the day palette
    Rectangle {
        anchors.fill: parent
        color: "#0b0f16"
        opacity: 0.25
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

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: (typeof kscreenlocker_userName !== "undefined" ? kscreenlocker_userName : "").toUpperCase()
            color: root.dimColor
            font.family: "IBM Plex Mono"
            font.pixelSize: 13 * root.u
            font.letterSpacing: 2.5 * root.u
        }

        Item { width: 1; height: 14 * root.u }

        Rectangle {
            id: box
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300 * root.u
            height: 42 * root.u
            radius: 6 * root.u
            color: Qt.rgba(28 / 255, 36 / 255, 50 / 255, 0.85)
            border.width: Math.max(1, Math.round(root.u))
            border.color: authenticator.graceLocked ? root.red : (password.activeFocus ? root.accent : "#2a3547")
            opacity: authenticator.graceLocked ? 0.6 : 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: -10 * root.u; duration: 50 }
                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: 10 * root.u; duration: 50 }
                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: -6 * root.u; duration: 50 }
                NumberAnimation { target: box; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
            }

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 14 * root.u
                anchors.rightMargin: 14 * root.u
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                enabled: !authenticator.graceLocked
                color: root.textColor
                selectionColor: root.accent
                font.family: "IBM Plex Mono"
                font.pixelSize: 16 * root.u
                font.letterSpacing: 3 * root.u
                clip: true
                focus: true
                Keys.onReturnPressed: root.unlock()
                Keys.onEnterPressed: root.unlock()
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
            anchors.horizontalCenter: parent.horizontalCenter
            height: 16 * root.u
            text: {
                const parts = [];
                if (capsLock.locked) parts.push("CAPS LOCK ON");
                if (root.message) parts.push(root.message);
                else if (root.notification) parts.push(root.notification.toUpperCase());
                return parts.join("  ·  ");
            }
            color: root.message === "UNLOCK FAILED" ? root.red : root.dimColor
            font.family: "IBM Plex Mono"
            font.pixelSize: 12 * root.u
            font.letterSpacing: 2 * root.u
        }
    }

    // anything typed while the field is not focused goes to it
    Keys.onPressed: event => {
        if (!password.activeFocus) {
            password.forceActiveFocus();
        }
        event.accepted = false;
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.u
        spacing: 32 * root.u

        Repeater {
            model: [
                { label: "SLEEP", show: sessionManagement.canSuspend, act: 0 },
                { label: "SWITCH USER", show: sessionManagement.canSwitchUser, act: 1 }
            ]

            Text {
                visible: modelData.show
                text: modelData.label
                color: area.containsMouse ? root.ice : root.dimColor
                font.family: "IBM Plex Mono"
                font.pixelSize: 12 * root.u
                font.letterSpacing: 2 * root.u

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: -8 * root.u
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.act === 0) sessionManagement.suspend();
                        else sessionManagement.switchUser();
                    }
                }
            }
        }
    }
}
