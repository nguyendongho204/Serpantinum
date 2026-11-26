import QtQuick
import "../../../"
import "../../../reusables"

Item {
    id: el

    property string variant: "card"
    property var ctx: null

    readonly property bool plain: el.variant === "plain"

    NotificationBox {
        anchors.fill: parent
        hasShadow: false
        shadowColor: Qt.rgba(0, 0, 0, 0.14)
        baseColor: el.plain ? "transparent" : Qt.alpha(ThemeBackend.surface0, 0.32)
        standaloneBlur: false
        blurScreen: el.ctx ? el.ctx.surface.screen : null
        borderWidth: el.plain ? 0 : 1
        borderColor: Qt.rgba(1, 1, 1, 0.10)
        cornerRadius: Scaler.s(16)
        cardRadius: Scaler.s(14)
        emptyGraphicSize: Math.min(Scaler.s(110), el.height * 0.4)
        rootContext: el.ctx
    }
}
