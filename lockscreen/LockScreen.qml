// Glacier lock screen. Replaces the Breeze LockScreen.qml inside the
// org.kde.plasma.desktop shell package (see install-lockscreen.sh); kept
// self-contained so plasma-desktop upgrades can't break it. Layout mirrors
// the SDDM login screen (sddm/Main.qml). The greeter draws the wallpaper
// behind this item and provides `authenticator`, `kscreenlocker_userName`.

import QtQuick
import org.kde.plasma.private.sessions 2.0
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.kscreenlocker 1.0 as ScreenLocker

Item {
    id: root

    // properties and signals kscreenlocker looks for
    property bool viewVisible: false
    property bool suspendToRamSupported: false
    property bool suspendToDiskSupported: false
    signal suspendToRam()
    signal suspendToDisk()

    readonly property real u: Math.max(1, height / 1080)

    readonly property color textColor: "#d8e1ee"
    readonly property color dimColor: "#7c8ba3"
    readonly property color accent: "#56a4f5"
    readonly property color ice: "#6fcdf5"
    readonly property color red: "#e8697a"
    readonly property color amber: "#e6b673"
    readonly property color green: "#7fcf9a"

    property bool uiVisible: false
    property bool unlockedWithoutPrompt: false
    property string message: ""
    property color messageColor: red
    property date now: new Date()

    implicitWidth: 800
    implicitHeight: 600

    function wake() {
        if (!uiVisible) {
            uiVisible = true;
            authenticator.startAuthenticating();
        }
        hideTimer.restart();
    }

    function sleep() {
        uiVisible = false;
        password.text = "";
    }

    function showMessage(text, colour) {
        if (!text) return;
        message = text.toUpperCase();
        messageColor = colour;
        messageTimer.restart();
    }

    function submit() {
        if (unlockedWithoutPrompt) {
            Qt.quit();
            return;
        }
        if (authenticator.graceLocked || password.text.length === 0) return;
        authenticator.respond(password.text);
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Timer { id: hideTimer; interval: 15000; onTriggered: if (password.text.length === 0) root.sleep() }
    Timer { id: messageTimer; interval: 4000; onTriggered: root.message = "" }
    Timer {
        id: graceTimer
        interval: 3000
        onTriggered: {
            password.text = "";
            authenticator.startAuthenticating();
            password.forceActiveFocus();
        }
    }

    SessionManagement { id: sessions }
    KeyboardIndicator.KeyState { id: capsLock; key: Qt.Key_CapsLock }

    Connections {
        target: sessions
        function onAboutToSuspend() { password.text = "" }
    }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind !== 0) return;          // fingerprint / smartcard: ignore
            root.showMessage("Unlock failed", root.red);
            shake.restart();
            graceTimer.restart();
        }
        function onSucceeded() {
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                root.unlockedWithoutPrompt = true;
                root.wake();
                root.showMessage("Unlocked · press Enter", root.green);
                messageTimer.stop();
            }
        }
        function onInfoMessageChanged() { root.showMessage(authenticator.infoMessage, root.dimColor) }
        function onErrorMessageChanged() { root.showMessage(authenticator.errorMessage, root.red) }
        function onPromptChanged() { root.showMessage(authenticator.prompt, root.dimColor) }
        function onPromptForSecretChanged() { password.forceActiveFocus() }
    }

    // dims the wallpaper slightly while the form is showing
    Rectangle {
        anchors.fill: parent
        color: "#0b0f16"
        opacity: root.uiVisible ? 0.35 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    MouseArea {
        id: wakeArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.uiVisible ? Qt.ArrowCursor : Qt.BlankCursor
        property bool seenMove: false
        onPressed: root.wake()
        onPositionChanged: { if (seenMove) root.wake(); seenMove = true }
    }

    // keys the password field doesn't consume (Shift, arrows ...) bubble up here
    Keys.onPressed: event => { root.wake(); event.accepted = false }

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

        Item {
            id: entry
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300 * root.u
            height: 42 * root.u
            opacity: root.uiVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 250 } }

            SequentialAnimation on x {
                id: shake
                running: false
                NumberAnimation { to: 10 * root.u; duration: 50 }
                NumberAnimation { to: -10 * root.u; duration: 80 }
                NumberAnimation { to: 6 * root.u; duration: 70 }
                NumberAnimation { to: 0; duration: 60 }
            }

            Rectangle {
                anchors.fill: parent
                radius: 6 * root.u
                color: Qt.rgba(28 / 255, 36 / 255, 50 / 255, 0.85)
                border.width: Math.max(1, Math.round(root.u))
                border.color: password.activeFocus ? root.accent : "#2a3547"
                Behavior on border.color { ColorAnimation { duration: 150 } }
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
                color: root.textColor
                selectionColor: root.accent
                font.family: "IBM Plex Mono"
                font.pixelSize: 16 * root.u
                font.letterSpacing: 3 * root.u
                clip: true
                enabled: !authenticator.graceLocked && !root.unlockedWithoutPrompt
                cursorVisible: root.uiVisible && activeFocus
                onTextChanged: root.wake()
                Keys.onReturnPressed: root.submit()
                Keys.onEnterPressed: root.submit()
                Keys.onEscapePressed: root.sleep()
            }

            Text {
                anchors.centerIn: parent
                visible: password.text.length === 0
                text: root.unlockedWithoutPrompt ? "ENTER" : "PASSWORD"
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
            text: root.message.length > 0 ? root.message
                : capsLock.locked ? "CAPS LOCK ON"
                : (authenticator.authenticatorTypes & ScreenLocker.Authenticator.Fingerprint) ? "OR SCAN FINGERPRINT"
                : ""
            color: root.message.length > 0 ? root.messageColor
                : capsLock.locked ? root.amber : root.dimColor
            opacity: root.uiVisible ? 1 : 0
            font.family: "IBM Plex Mono"
            font.pixelSize: 12 * root.u
            font.letterSpacing: 2 * root.u
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.u
        spacing: 12 * root.u
        opacity: root.uiVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        Text {
            text: "LOCKED"
            color: root.dimColor
            font.family: "IBM Plex Mono"
            font.pixelSize: 12 * root.u
            font.letterSpacing: 2 * root.u
        }
        Text {
            text: String(kscreenlocker_userName).toUpperCase()
            color: root.textColor
            font.family: "IBM Plex Mono"
            font.pixelSize: 12 * root.u
            font.letterSpacing: 2 * root.u
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 32 * root.u
        spacing: 32 * root.u
        opacity: root.uiVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250 } }

        Repeater {
            model: [
                { label: "SLEEP", show: root.suspendToRamSupported, act: 0 },
                { label: "HIBERNATE", show: root.suspendToDiskSupported, act: 1 },
                { label: "SWITCH USER", show: sessions.canSwitchUser, act: 2 }
            ]

            Text {
                required property var modelData
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
                        if (modelData.act === 0) root.suspendToRam();
                        else if (modelData.act === 1) root.suspendToDisk();
                        else sessions.switchUser();
                    }
                }
            }
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
