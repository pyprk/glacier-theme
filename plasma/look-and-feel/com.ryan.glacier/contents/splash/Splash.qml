import QtQuick

Rectangle {
    id: root
    color: "#0b0f16"

    property int stage

    Column {
        anchors.centerIn: parent
        spacing: 36

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/glacier.svg"
            sourceSize: Qt.size(96, 96)
        }

        Rectangle {
            id: track
            anchors.horizontalCenter: parent.horizontalCenter
            width: 180
            height: 2
            radius: 1
            color: "#1c2432"
            clip: true

            Rectangle {
                id: runner
                width: 60
                height: parent.height
                radius: 1
                color: "#56a4f5"

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: -runner.width; to: track.width; duration: 1100; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}
