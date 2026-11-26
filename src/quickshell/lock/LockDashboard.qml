import QtQuick
import QtQuick.Window
import QtQuick.Effects
import "../"
import "../reusables"
import "redactor"
import "redactor/elements"

Item {
    id: dashboard
    required property var screenRoot
    readonly property var passwordInput: panelView.passwordInput ? panelView.passwordInput : (fallbackPassword.item ? fallbackPassword.item.input : null)

    readonly property real fit: Math.min(width / LockLayoutStore.refW, height / LockLayoutStore.refH)
    readonly property real coreWidth: Math.min(LockLayoutStore.panelW, screenRoot.s(440))
    readonly property real shellWidth: dashboard.coreWidth + screenRoot.wingsReveal * (LockLayoutStore.panelW - dashboard.coreWidth)
    readonly property real panelLeft: LockLayoutStore.panelX >= 0 ? LockLayoutStore.panelX : (LockLayoutStore.refW - LockLayoutStore.panelW) / 2
    readonly property real panelTop: LockLayoutStore.panelY >= 0 ? LockLayoutStore.panelY : (LockLayoutStore.refH - LockLayoutStore.panelH) / 2

    anchors.fill: parent

    Item {
        width: LockLayoutStore.refW
        height: LockLayoutStore.refH
        anchors.centerIn: parent
        scale: dashboard.fit

        Rectangle {
            id: mainShellShadow
            x: mainShell.x
            y: mainShell.y + screenRoot.s(1.5)
            width: mainShell.width
            height: mainShell.height
            radius: mainShell.radius
            color: Qt.rgba(0, 0, 0, 0.14 * LockLayoutStore.panelOpacity)
            opacity: mainShell.opacity
            scale: mainShell.scale
            visible: mainShell.visible
            transform: Scale {
                origin.x: mainShell.width / 2
                origin.y: mainShell.height / 2
                xScale: screenRoot.isUnlocking ? screenRoot.foldScaleX : 1.0
                yScale: screenRoot.isUnlocking ? screenRoot.foldScaleY : 1.0
            }
        }

        Rectangle {
            id: mainShell
            x: dashboard.panelLeft + (LockLayoutStore.panelW - dashboard.shellWidth) / 2
            y: dashboard.panelTop + (screenRoot.inputActive ? 0 : screenRoot.s(90))
            width: dashboard.shellWidth
            height: LockLayoutStore.panelH
            radius: ThemeBackend.borderRadius * 1.5
            // Trong suot de thay video nen phia sau qua khung panel
            color: Qt.alpha(ThemeBackend.surface0, 0.28 * LockLayoutStore.panelOpacity)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.08)
            clip: true

            property rect glassPx: Qt.rect(0, 0, 1, 1)

            opacity: screenRoot.centerReveal
            scale: 0.92 + (screenRoot.centerReveal * 0.08)
            visible: opacity > 0.01

            transform: Scale {
                origin.x: mainShell.width / 2
                origin.y: mainShell.height / 2
                xScale: screenRoot.isUnlocking ? screenRoot.foldScaleX : 1.0
                yScale: screenRoot.isUnlocking ? screenRoot.foldScaleY : 1.0
            }

            Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

            // --- LIQUID GLASS (shader that cua repo: assets/shaders/effects/liquid_glass.frag.qsb) ---
            ShaderEffectSource {
                id: panelGlassSrc
                anchors.fill: parent
                visible: false
                sourceItem: screenRoot.backdropWallpaper
                smooth: true
                sourceRect: mainShell.glassPx
            }

            LiquidGlass {
                anchors.fill: parent
                src: panelGlassSrc
                topLeftRadius: mainShell.radius
                topRightRadius: mainShell.radius
                bottomLeftRadius: mainShell.radius
                bottomRightRadius: mainShell.radius
                tintColor: Qt.alpha(ThemeBackend.surface0, 0.4)
                tintAmount: 0.40
                frost: 12.0
                rim: 0.45
                saturation: 1.1
            }

            // vien kinh ve TREN shader (Rectangle.border cua mainShell bi LiquidGlass che)
            Rectangle {
                anchors.fill: parent
                radius: mainShell.radius
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.22)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
                    GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.0) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.06) }
                }
            }

            // cap nhat vung video thuc theo vi tri panel (moi frame, tranh stale)
            FrameAnimation {
                running: true
                onTriggered: {
                    if (!screenRoot.backdropWallpaper) return;
                    let bd = screenRoot.backdropWallpaper;
                    let a = mainShell.mapToItem(bd, 0, 0);
                    let b = mainShell.mapToItem(bd, mainShell.width, mainShell.height);
                    mainShell.glassPx = Qt.rect(a.x, a.y, Math.max(1, b.x - a.x), Math.max(1, b.y - a.y));
                }
            }

            LockLayoutView {
                id: panelView
                x: (mainShell.width - LockLayoutStore.panelW) / 2
                width: LockLayoutStore.panelW
                height: LockLayoutStore.panelH
                scope: "panel"
                reveal: screenRoot.wingsReveal
                coreLeft: (LockLayoutStore.panelW - dashboard.coreWidth) / 2
                coreRight: (LockLayoutStore.panelW + dashboard.coreWidth) / 2
                ctx: dashboard.screenRoot
            }
        }
    }

    Loader {
        id: fallbackPassword
        active: panelView.passwordInput === null
        width: screenRoot.s(380)
        height: screenRoot.s(44)
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height / 2
        visible: screenRoot.centerReveal > 0.01
        sourceComponent: LockPasswordElement { ctx: dashboard.screenRoot }

        onLoaded: item.ctx = Qt.binding(() => dashboard.screenRoot)
    }

    Connections {
        target: screenRoot.lockUI
        function onFailedChanged() {
            if (screenRoot.lockUI.failed && dashboard.passwordInput) {
                dashboard.passwordInput.triggerShake();
                dashboard.passwordInput.clear();
                screenRoot.restoreFocus();
            }
        }
    }
}
