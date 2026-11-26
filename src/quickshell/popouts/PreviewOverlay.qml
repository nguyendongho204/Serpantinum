import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../"
import "../reusables"

PanelWindow {
    id: root

    visible: false
    WlrLayershell.namespace: "sddm-preview-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    screen: {
        if (typeof Hyprland !== "undefined" && Hyprland.focusedMonitor) {
            let name = Hyprland.focusedMonitor.name;
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === name) return Quickshell.screens[i];
            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    mask: Region {
        item: root.visible ? overlayRoot : null
    }

    property string themeName: ""

    function s(val) {
        return (typeof Scaler !== "undefined") ? Scaler.s(val) : val;
    }

    IpcHandler {
        target: "sddm-preview"

        function open(theme: string): void {
            root.themeName = theme;
            root.visible = true;
        }

        function close(): void {
            root.visible = false;
        }
    }

    Item {
        id: overlayRoot
        anchors.fill: parent

        // Chặn toàn bộ chuột vào greeter bên dưới: chỉ xem, không bấm
        // mật khẩu / Restart / Shutdown.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: function(wheel) {
                wheel.accepted = true;
            }
        }

        Rectangle {
            id: bar
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.s(18)
            width: Math.min(parent.width - root.s(40), root.s(640))
            height: root.s(52)
            radius: root.s(14)
            color: Qt.alpha(ThemeBackend.surface0, 0.94)
            border.width: 1
            border.color: Qt.alpha(ThemeBackend.mauve, 0.55)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.s(16)
                anchors.rightMargin: root.s(10)
                spacing: root.s(10)

                Text {
                    text: "󰈈"
                    color: ThemeBackend.mauve
                    font.family: ThemeBackend.iconFont
                    font.pixelSize: root.s(18)
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: I18n.t("guide.display.login.previewing", "Đang xem trước")
                        color: ThemeBackend.subtext0
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: root.s(10)
                    }

                    Text {
                        text: root.themeName
                        color: ThemeBackend.text
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: root.s(13)
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    id: closeButton
                    implicitWidth: closeLabel.implicitWidth + root.s(22)
                    implicitHeight: root.s(30)
                    radius: root.s(8)
                    color: ThemeBackend.mauve

                    Text {
                        id: closeLabel
                        anchors.centerIn: parent
                        text: I18n.t("guide.display.login.close_preview", "Đóng  •  Super+Q")
                        color: ThemeBackend.crust
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: root.s(11)
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached([
                                "bash", "-c",
                                "pkill -f 'sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/'; " +
                                "pkill -f '^Xwayland :[2-6] -geometry 1280x800'"
                            ]);
                            root.visible = false;
                        }
                    }
                }
            }
        }

        Text {
            anchors.top: bar.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: root.s(8)
            text: I18n.t("guide.display.login.preview_only", "Chỉ xem giao diện — không nhập mật khẩu, không bấm Restart/Shutdown")
            color: ThemeBackend.subtext0
            font.family: ThemeBackend.fontFamily
            font.pixelSize: root.s(10)
        }
    }
}
