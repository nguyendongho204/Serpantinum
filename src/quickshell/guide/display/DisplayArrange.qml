import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../"
import "../../reusables"
import "../../reusables/guide"

Rectangle {
    id: arrangeRoot
    required property var tab
    readonly property var rootObj: tab.rootObj
    readonly property bool supported: tab.compositor === "hyprland"
    visible: supported && tab.monitorsList.length > 1

    Layout.fillWidth: true
    clip: true
    radius: ThemeBackend.borderRadius
    color: arrangeGlass.active ? "transparent" : Qt.alpha(ThemeBackend.surface0, 0.4)
    border.width: arrangeGlass.active ? 0 : 1
    border.color: Qt.alpha(ThemeBackend.surface1, 0.4)

    GlassFill {
        id: arrangeGlass
        anchors.fill: parent
        radius: parent.radius
        tintColor: Qt.alpha(ThemeBackend.surface0, 0.4)
        tintAmount: 0.25
    }

    // ===== state bo tri =====
    property var basePositions: ({})   // name -> {x, y} vi tri hien tai cua man hinh
    property var pendingPositions: ({})
    property var logicalExtents: ({})  // name -> {lw, lh} kich thuoc logic
    property real fitFactor: 0.06
    property real fitOx: 0
    property real fitOy: 0
    property var revertPositions: null
    property int keepSeconds: 15
    property bool applyBusy: false
    property bool autoKeepPending: false

    property bool isDirty: {
        let keys = Object.keys(pendingPositions);
        for (let i = 0; i < keys.length; i++) {
            let n = keys[i];
            let b = basePositions[n];
            if (!b) return true;
            if (Math.round(pendingPositions[n].x) !== Math.round(b.x) ||
                Math.round(pendingPositions[n].y) !== Math.round(b.y)) return true;
        }
        return false;
    }

    implicitHeight: visible ? (contentCol.implicitHeight + rootObj.s(24)) : 0
    opacity: visible ? 1.0 : 0.0
    Behavior on implicitHeight { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Component.onCompleted: rebuildFromMonitors()

    function rebuildFromMonitors() {
        let base = {}, ext = {};
        let mons = arrangeRoot.tab.monitorsList;
        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            if (!m) continue;
            if (m.active === false) continue;
            let sc = m.scale !== undefined ? Number(m.scale) : 1.0;
            if (!sc || sc <= 0) sc = 1.0;
            let dims = (m.dimensions || "1920x1080").split("x");
            let w = parseInt(dims[0]) || 1920;
            let h = parseInt(dims[1]) || 1080;
            base[m.name] = { x: (m.x !== undefined ? m.x : 0), y: (m.y !== undefined ? m.y : 0) };
            ext[m.name] = { lw: w / sc, lh: h / sc };
        }
        arrangeRoot.basePositions = base;
        arrangeRoot.logicalExtents = ext;
        arrangeRoot.pendingPositions = JSON.parse(JSON.stringify(base));
        arrangeRoot.revertPositions = null;
        arrangeRoot.keepSeconds = 15;
        arrangePositionsRepeater.model = Object.keys(ext);
        arrangeRoot.recomputeFit();
    }

    function recomputeFit() {
        let keys = Object.keys(arrangeRoot.pendingPositions);
        if (keys.length === 0) return;
        let minx = 1e9, miny = 1e9, maxx = -1e9, maxy = -1e9;
        for (let i = 0; i < keys.length; i++) {
            let n = keys[i];
            let p = arrangeRoot.pendingPositions[n];
            let e = arrangeRoot.logicalExtents[n];
            if (!p || !e) continue;
            if (p.x < minx) minx = p.x;
            if (p.y < miny) miny = p.y;
            if (p.x + e.lw > maxx) maxx = p.x + e.lw;
            if (p.y + e.lh > maxy) maxy = p.y + e.lh;
        }
        let bw = Math.max(1, maxx - minx);
        let bh = Math.max(1, maxy - miny);
        let cw = dragCanvas.width > 60 ? dragCanvas.width : 600;
        let ch = dragCanvas.height > 60 ? dragCanvas.height : 200;
        let f = Math.min(cw / bw, ch / bh) * 0.90;
        arrangeRoot.fitFactor = Math.max(0.005, f);
        arrangeRoot.fitOx = (cw - bw * arrangeRoot.fitFactor) / 2 - minx * arrangeRoot.fitFactor;
        arrangeRoot.fitOy = (ch - bh * arrangeRoot.fitFactor) / 2 - miny * arrangeRoot.fitFactor;
    }

    function snapOnce(cur, otherVal, otherSize, ownSize, factor) {
        let thr = 24 / Math.max(arrangeRoot.fitFactor, 0.02);
        let cands = [0, otherVal, otherVal + otherSize - ownSize, otherVal + otherSize, otherVal - ownSize];
        let best = cur, bd = thr;
        for (let i = 0; i < cands.length; i++) {
            let d = Math.abs(cands[i] - cur);
            if (d < bd) { bd = d; best = cands[i]; }
        }
        return { v: best, snapped: best !== cur };
    }

    function samePositions(a, b) {
        let keysA = Object.keys(a);
        let keysB = Object.keys(b);
        if (keysA.length !== keysB.length) return false;
        for (let i = 0; i < keysA.length; i++) {
            let n = keysA[i];
            if (!b[n]) return false;
            if (Math.round(a[n].x) !== Math.round(b[n].x) ||
                Math.round(a[n].y) !== Math.round(b[n].y)) return false;
        }
        return true;
    }

    function positionsList(src) {
        let out = [];
        let keys = Object.keys(src);
        for (let i = 0; i < keys.length; i++) {
            out.push({ name: keys[i], x: Math.round(src[keys[i]].x), y: Math.round(src[keys[i]].y) });
        }
        return out;
    }

    function applyPositions(list) {
        if (applyBusy) return;
        applyBusy = true;
        arrangeRoot.tab.applyMonitorPositions(list);
        verifyTimer.restart();
    }

    Timer {
        id: verifyTimer
        interval: 700
        repeat: false
        running: false
        onTriggered: arrangeRoot.tab.reloadMonitors()
    }

    Connections {
        target: arrangeRoot.tab
        function onMonitorsListChanged() {
            if (!arrangeRoot.applyBusy) {
                arrangeRoot.rebuildFromMonitors();
                return;
            }
            arrangeRoot.applyBusy = false;
            verifyTimer.stop();
            let fresh = {};
            let mons = arrangeRoot.tab.monitorsList;
            for (let i = 0; i < mons.length; i++) {
                let m = mons[i];
                fresh[m.name] = { x: (m.x !== undefined ? m.x : 0),
                                  y: (m.y !== undefined ? m.y : 0) };
            }
            if (samePositions(fresh, arrangeRoot.pendingPositions)) {
                // ap dung thanh cong
                if (!samePositions(arrangeRoot.basePositions, arrangeRoot.pendingPositions)) {
                    if (arrangeRoot.autoKeepPending) {
                        arrangeRoot.autoKeepPending = false;
                        arrangeRoot.keepLayout();
                    } else {
                        arrangeRoot.revertPositions = JSON.parse(JSON.stringify(arrangeRoot.basePositions));
                        arrangeRoot.keepSeconds = 15;
                        keepTimer.restart();
                    }
                } else {
                    arrangeRoot.autoKeepPending = false;
                    arrangeRoot.rebuildFromMonitors(); // keo nhung ve dung cho
                }
            } else {
                // hyprctl tu choi / that bai -> quay lai trang thai that
                arrangeRoot.rebuildFromMonitors();
            }
        }
    }

    function applyLayout() {
        if (applyBusy) return;
        arrangeRoot.revertPositions = JSON.parse(JSON.stringify(arrangeRoot.basePositions));
        arrangeRoot.applyPositions(arrangeRoot.positionsList(arrangeRoot.pendingPositions));
    }

    function keepLayout() {
        keepTimer.stop();
        let list = arrangeRoot.positionsList(arrangeRoot.pendingPositions);
        arrangeRoot.tab.persistMonitorLua(list);
        let nb = JSON.parse(JSON.stringify(arrangeRoot.pendingPositions));
        arrangeRoot.basePositions = nb;
        arrangeRoot.revertPositions = null;
        arrangeRoot.keepSeconds = 15;
        let keys = Object.keys(nb);
        for (let i = 0; i < keys.length; i++) {
            arrangeRoot.tab.updateMonitorSetting(keys[i], "position",
                { x: nb[keys[i]].x, y: nb[keys[i]].y });
        }
    }

    // One-click preset: dat man phu quanh man laptop theo huong.
    // left/right: canh day thang voi laptop (giong man hinh thuc te);
    // top/bottom: canh giua theo chieu ngang.
    function presetLayout(dir) {
        if (applyBusy || revertPositions !== null) return;
        let mons = arrangeRoot.tab.monitorsList;
        let anchor = null;
        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            if (!m || m.active === false) continue;
            if (!anchor) anchor = m;
            if (m.name.indexOf("eDP") === 0) { anchor = m; break; }
        }
        if (!anchor) return;
        let ext = arrangeRoot.logicalExtents;
        let px = (anchor.x !== undefined ? Math.round(anchor.x) : 0);
        let py = (anchor.y !== undefined ? Math.round(anchor.y) : 0);
        let ae = ext[anchor.name] || { lw: 1920, lh: 1080 };
        let prev = { x: px, y: py, lw: ae.lw, lh: ae.lh };
        let out = {};
        out[anchor.name] = { x: px, y: py };
        for (let i = 0; i < mons.length; i++) {
            let m = mons[i];
            if (!m || m.active === false || m.name === anchor.name) continue;
            let e = ext[m.name] || { lw: 1920, lh: 1080 };
            if (dir === "right") {
                prev = { x: prev.x + prev.lw, y: prev.y + prev.lh - e.lh, lw: e.lw, lh: e.lh };
            } else if (dir === "left") {
                prev = { x: prev.x - e.lw, y: prev.y + prev.lh - e.lh, lw: e.lw, lh: e.lh };
            } else if (dir === "top") {
                prev = { x: prev.x + Math.round((prev.lw - e.lw) / 2), y: prev.y - e.lh, lw: e.lw, lh: e.lh };
            } else {
                prev = { x: prev.x + Math.round((prev.lw - e.lw) / 2), y: prev.y + prev.lh, lw: e.lw, lh: e.lh };
            }
            prev.x = Math.round(prev.x);
            prev.y = Math.round(prev.y);
            out[m.name] = { x: prev.x, y: prev.y };
        }
        arrangeRoot.pendingPositions = out;
        arrangeRoot.autoKeepPending = true;
        arrangeRoot.applyLayout();
    }

    Timer {
        id: keepTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            arrangeRoot.keepSeconds -= 1;
            if (arrangeRoot.keepSeconds <= 0) {
                stop();
                if (arrangeRoot.revertPositions !== null) {
                    arrangeRoot.applyPositions(arrangeRoot.positionsList(arrangeRoot.revertPositions));
                    arrangeRoot.revertPositions = null;
                    arrangeRoot.keepSeconds = 15;
                }
            }
        }
    }

    ColumnLayout {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: rootObj.s(12)
        spacing: rootObj.s(6)

        RowLayout {
            Layout.fillWidth: true
            spacing: rootObj.s(8)

            Text {
                text: I18n.t("guide.display.arrange.title", "Arrange displays")
                font.family: ThemeBackend.fontFamily
                font.pixelSize: rootObj.s(16)
                font.bold: true
                color: ThemeBackend.text
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: !arrangeRoot.isDirty
                text: I18n.t("guide.display.arrange.desc", "Drag the displays to place them next to each other")
                font.family: ThemeBackend.fontFamily
                font.pixelSize: rootObj.s(12)
                color: ThemeBackend.subtext0
            }
        }

        Item {
            id: dragCanvas
            Layout.fillWidth: true
            implicitHeight: rootObj.s(210)
            clip: true
            onWidthChanged: recomputeFit()

            Repeater {
                id: arrangePositionsRepeater
                delegate: Item {
                    id: monBox
                    required property string modelData
                    visible: arrangeRoot.pendingPositions[modelData] !== undefined
                             && arrangeRoot.logicalExtents[modelData] !== undefined
                    x: {
                        let p = arrangeRoot.pendingPositions[modelData];
                        return p ? Math.round(arrangeRoot.fitOx + p.x * arrangeRoot.fitFactor) : 0;
                    }
                    y: {
                        let p = arrangeRoot.pendingPositions[modelData];
                        return p ? Math.round(arrangeRoot.fitOy + p.y * arrangeRoot.fitFactor) : 0;
                    }
                    width: {
                        let e = arrangeRoot.logicalExtents[modelData];
                        return e ? Math.max(rootObj.s(40), Math.round(e.lw * arrangeRoot.fitFactor)) : rootObj.s(60);
                    }
                    height: {
                        let e = arrangeRoot.logicalExtents[modelData];
                        return e ? Math.max(rootObj.s(30), Math.round(e.lh * arrangeRoot.fitFactor)) : rootObj.s(40);
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: ThemeBackend.borderRadius * 0.6
                        color: Qt.alpha(ThemeBackend.mauve, arrangeRoot.isDirty ? 0.30 : 0.18)
                        border.color: ioArea.containsMouse || ioArea.pressed
                                      ? ThemeBackend.text
                                      : Qt.alpha(ThemeBackend.mauve, 0.8)
                        border.width: ioArea.pressed ? 2 : 1
                        clip: true

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                text: monBox.modelData
                                font.family: ThemeBackend.fontFamily
                                font.bold: true
                                font.pixelSize: Math.min(rootObj.s(12), monBox.height / 5)
                                color: ThemeBackend.text
                            }
                            Text {
                                text: {
                                    let e = arrangeRoot.logicalExtents[monBox.modelData];
                                    let p = arrangeRoot.pendingPositions[monBox.modelData];
                                    let dims = e ? Math.round(e.lw) + "×" + Math.round(e.lh) : "";
                                    let pos = p ? Math.round(p.x) + "," + Math.round(p.y) : "";
                                    return dims + "\n" + pos;
                                }
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: Math.max(rootObj.s(9), Math.min(rootObj.s(10), monBox.height / 7))
                                color: ThemeBackend.subtext0
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    MouseArea {
                        id: ioArea
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        property real startX: 0
                        property real startY: 0
                        property var startPos: null
                        function canvasPoint(mouse) {
                            return ioArea.mapToItem(dragCanvas, mouse.x, mouse.y);
                        }
                        onPressed: function(mouse) {
                            if (tab && tab.canvasFlickable) tab.canvasFlickable.interactive = false;
                            let p = arrangeRoot.pendingPositions[monBox.modelData];
                            if (!p) {
                                if (tab && tab.canvasFlickable) tab.canvasFlickable.interactive = true;
                                return;
                            }
                            let cp = canvasPoint(mouse);
                            startX = cp.x;
                            startY = cp.y;
                            startPos = JSON.parse(JSON.stringify(p));
                        }
                        onPositionChanged: function(mouse) {
                            if (!pressed || !startPos) return;
                            let e = arrangeRoot.logicalExtents[monBox.modelData];
                            if (!e) return;
                            let cp = canvasPoint(mouse);
                            let ff = arrangeRoot.fitFactor;
                            let lx = startPos.x + (cp.x - startX) / ff;
                            let ly = startPos.y + (cp.y - startY) / ff;
                            let others = Object.keys(arrangeRoot.pendingPositions);
                            let nx = lx, ny = ly;
                            for (let i = 0; i < others.length; i++) {
                                let on = others[i];
                                if (on === monBox.modelData) continue;
                                let op = arrangeRoot.pendingPositions[on];
                                let oe = arrangeRoot.logicalExtents[on];
                                if (!op || !oe) continue;
                                let sX = arrangeRoot.snapOnce(nx, op.x, oe.lw, e.lw, ff);
                                let sY = arrangeRoot.snapOnce(ny, op.y, oe.lh, e.lh, ff);
                                if (sX.snapped) nx = sX.v;
                                if (sY.snapped) ny = sY.v;
                            }
                            arrangeRoot.pendingPositions[monBox.modelData] = { x: Math.round(nx), y: Math.round(ny) };
                            arrangeRoot.pendingPositions = JSON.parse(JSON.stringify(arrangeRoot.pendingPositions));
                        }
                        function dragFinish() {
                            if (tab && tab.canvasFlickable) tab.canvasFlickable.interactive = true;
                            arrangeRoot.recomputeFit();
                        }
                        onReleased: ioArea.dragFinish()
                        onCanceled: ioArea.dragFinish()
                    }
                }
            }

        Text {
            anchors.centerIn: parent
            visible: Object.keys(arrangeRoot.pendingPositions).length === 0
            text: I18n.t("guide.display.arrange.no_monitors", "No displays detected")
            color: ThemeBackend.subtext0
            font.pixelSize: rootObj.s(12)
        }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: rootObj.s(6)

            Text {
                text: I18n.t("guide.display.arrange.preset_label", "Đặt nhanh:")
                font.family: ThemeBackend.fontFamily
                font.pixelSize: rootObj.s(11)
                color: ThemeBackend.subtext0
            }

            FillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: rootObj.s(34)
                buttonText: I18n.t("guide.display.arrange.preset_top", "Màn phụ trên")
                buttonIcon: ""
                accentColor: ThemeBackend.mauve
                baseColor: ThemeBackend.surface0
                hoverColor: Qt.alpha(ThemeBackend.mauve, 0.15)
                textColor: ThemeBackend.mauve
                horizontalPadding: rootObj.s(8)
                cornerRadius: 8
                textFontSize: 12
                enabled: !arrangeRoot.applyBusy && arrangeRoot.revertPositions === null
                fillDuration: 600
                onTriggered: arrangeRoot.presetLayout("top")
            }
            FillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: rootObj.s(34)
                buttonText: I18n.t("guide.display.arrange.preset_left", "Trái")
                buttonIcon: ""
                accentColor: ThemeBackend.mauve
                baseColor: ThemeBackend.surface0
                hoverColor: Qt.alpha(ThemeBackend.mauve, 0.15)
                textColor: ThemeBackend.mauve
                horizontalPadding: rootObj.s(8)
                cornerRadius: 8
                textFontSize: 12
                enabled: !arrangeRoot.applyBusy && arrangeRoot.revertPositions === null
                fillDuration: 600
                onTriggered: arrangeRoot.presetLayout("left")
            }
            FillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: rootObj.s(34)
                buttonText: I18n.t("guide.display.arrange.preset_right", "Phải")
                buttonIcon: ""
                accentColor: ThemeBackend.mauve
                baseColor: ThemeBackend.surface0
                hoverColor: Qt.alpha(ThemeBackend.mauve, 0.15)
                textColor: ThemeBackend.mauve
                horizontalPadding: rootObj.s(8)
                cornerRadius: 8
                textFontSize: 12
                enabled: !arrangeRoot.applyBusy && arrangeRoot.revertPositions === null
                fillDuration: 600
                onTriggered: arrangeRoot.presetLayout("right")
            }
            FillButton {
                Layout.fillWidth: true
                Layout.preferredHeight: rootObj.s(34)
                buttonText: I18n.t("guide.display.arrange.preset_bottom", "Dưới")
                buttonIcon: ""
                accentColor: ThemeBackend.mauve
                baseColor: ThemeBackend.surface0
                hoverColor: Qt.alpha(ThemeBackend.mauve, 0.15)
                textColor: ThemeBackend.mauve
                horizontalPadding: rootObj.s(8)
                cornerRadius: 8
                textFontSize: 12
                enabled: !arrangeRoot.applyBusy && arrangeRoot.revertPositions === null
                fillDuration: 600
                onTriggered: arrangeRoot.presetLayout("bottom")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: rootObj.s(10)
            visible: arrangeRoot.isDirty || arrangeRoot.revertPositions !== null

            LoaderIcon {
                visible: arrangeRoot.applyBusy
                Layout.preferredWidth: rootObj.s(28)
                Layout.preferredHeight: rootObj.s(28)
                running: arrangeRoot.applyBusy
                accentColor: ThemeBackend.mauve
            }

            Text {
                Layout.fillWidth: true
                text: {
                    if (arrangeRoot.applyBusy)
                        return I18n.t("guide.display.arrange.applying", "Applying layout…");
                    if (arrangeRoot.revertPositions !== null)
                        return I18n.t("guide.display.arrange.confirm", "Check your displays — keep or undo?") + " (" + arrangeRoot.keepSeconds + "s)";
                    return I18n.t("guide.display.arrange.dirty_hint", "Layout changed but not applied yet");
                }
                font.family: ThemeBackend.fontFamily
                font.pixelSize: rootObj.s(12)
                color: ThemeBackend.subtext0
                elide: Text.ElideRight
            }

            FillButton {
                visible: !arrangeRoot.applyBusy && arrangeRoot.revertPositions === null && arrangeRoot.isDirty
                Layout.preferredHeight: rootObj.s(38)
                buttonText: I18n.t("guide.display.arrange.apply")
                buttonIcon: ""
                accentColor: ThemeBackend.mauve
                baseColor: ThemeBackend.surface0
                hoverColor: Qt.alpha(ThemeBackend.mauve, 0.15)
                textColor: ThemeBackend.mauve
                horizontalPadding: rootObj.s(20)
                cornerRadius: 10
                textFontSize: 14
                maxWidth: rootObj.s(220)
                onTriggered: arrangeRoot.applyLayout()
            }

            FillButton {
                visible: !arrangeRoot.applyBusy && arrangeRoot.revertPositions !== null
                Layout.preferredHeight: rootObj.s(38)
                buttonText: I18n.t("guide.display.arrange.undo")
                buttonIcon: ""
                accentColor: ThemeBackend.red
                baseColor: ThemeBackend.surface0
                hoverColor: Qt.alpha(ThemeBackend.red, 0.15)
                textColor: ThemeBackend.red
                horizontalPadding: rootObj.s(16)
                cornerRadius: 10
                textFontSize: 14
                maxWidth: rootObj.s(220)
                onTriggered: {
                    keepTimer.stop();
                    arrangeRoot.applyPositions(arrangeRoot.positionsList(arrangeRoot.revertPositions));
                    arrangeRoot.revertPositions = null;
                    arrangeRoot.keepSeconds = 15;
                }
            }

            FillButton {
                visible: !arrangeRoot.applyBusy && arrangeRoot.revertPositions !== null
                Layout.preferredHeight: rootObj.s(38)
                buttonText: I18n.t("guide.display.arrange.keep") + " (" + arrangeRoot.keepSeconds + "s)"
                buttonIcon: ""
                accentColor: ThemeBackend.green
                baseColor: ThemeBackend.surface0
                hoverColor: Qt.alpha(ThemeBackend.green, 0.15)
                textColor: ThemeBackend.green
                horizontalPadding: rootObj.s(16)
                cornerRadius: 10
                textFontSize: 14
                maxWidth: rootObj.s(240)
                onTriggered: arrangeRoot.keepLayout()
            }
        }
    }
}
