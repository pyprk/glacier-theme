import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    property alias cfg_Animate: animate.checked
    property alias cfg_FollowTime: follow.checked
    property alias cfg_Period: period.value
    property alias cfg_Glitch: glitch.checked

    QQC2.CheckBox {
        id: animate
        Kirigami.FormData.label: "Animation:"
        text: "Drift the terrain slowly"
    }

    QQC2.CheckBox {
        id: follow
        Kirigami.FormData.label: "Palette:"
        text: "Follow the time of day"
    }

    QQC2.CheckBox {
        id: glitch
        Kirigami.FormData.label: "Chaos:"
        text: "Let a ridge line skip now and then"
    }

    QQC2.SpinBox {
        id: period
        Kirigami.FormData.label: "Loop length (seconds):"
        from: 60
        to: 3600
        stepSize: 30
    }
}
