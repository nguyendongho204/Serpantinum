import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import "../"

// Alt+Tab kieu Windows 11, nhung gom theo workspace ("trang"):
// moi workspace = 1 o, hien luoi thumbnail cac cua so trong workspace do.
// Giu Alt de chon, tha Alt de chuyen workspace.
PanelWindow {
    id: root

    WlrLayershell.namespace: "workspace-switcher"
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

    function s(val) {
        return (typeof Scaler !== "undefined") ? Scaler.s(val) : val;
    }

    readonly property var targetScreen: {
        let screens = Quickshell.screens || [];
        let count = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0);
        let mon = (typeof Hyprland !== "undefined") ? Hyprland.focusedMonitor : null;
        let monName = mon ? mon.name : "";
        for (let i = 0; i < count; i++) {
            let sc = screens[i] !== undefined ? screens[i] : screens.get(i);
            if (sc && sc.name === monName) return sc;
        }
        if (count > 0) return screens[0] !== undefined ? screens[0] : screens.get(0);
        return null;
    }

    screen: root.targetScreen

    property bool active: false
    property int sel: 1
    property var spaces: []
    property int currentSpace: 0
    property string spacesSig: ""

    // Luon map san surface; mask = null khi an => click-through.
    visible: true

    FileView {
        id: stateView
        path: (typeof Caching !== "undefined" && Caching.runDir) ? (Caching.runDir + "/workspace-switcher.state") : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyState(text())
    }

    Component.onCompleted: root.ensureStateFile()

    function ensureStateFile() {
        if (typeof Caching === "undefined" || !Caching.runDir) return;
        let dir = Caching.runDir;
        let file = dir + "/workspace-switcher.state";
        Quickshell.execDetached(["bash", "-c", "mkdir -p '" + dir + "'; [ -f '" + file + "' ] || printf '{\"active\":false,\"sel\":1,\"spaces\":[]}' > '" + file + "'"]);
    }

    function applyState(text) {
        let lines = String(text || "").trim().split("\n");
        let line = lines.length > 0 ? lines[lines.length - 1] : "";
        let obj;
        try {
            obj = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (!obj || typeof obj !== "object") return;

        let list = Array.isArray(obj.spaces) ? obj.spaces : [];

        // Cache: chi dung lai delegate (va khung hinh da chup) khi bo cuc khong doi.
        let sig = "";
        for (let i = 0; i < list.length; i++) {
            let sp = list[i];
            sig += sp.id + ":" + sp.wins.length + ":";
            for (let j = 0; j < sp.wins.length; j++) {
                let w = sp.wins[j];
                sig += w.address + "," + w.x + "," + w.y + "," + w.w + "," + w.h + ";";
            }
        }
        if (sig !== root.spacesSig) {
            root.spacesSig = sig;
            root.spaces = list;
        }

        root.currentSpace = obj.cur || 0;
        root.sel = (obj.sel && obj.sel > 0) ? obj.sel : 1;
        root.active = !!obj.active && list.length > 0;
    }

    function toplevelFor(address) {
        if (!address) return null;
        let tls = (typeof Hyprland !== "undefined" && Hyprland.toplevels) ? Hyprland.toplevels.values : [];
        for (let i = 0; i < tls.length; i++) {
            let win = tls[i];
            if (!win) continue;
            let ipc = win.lastIpcObject;
            if (ipc && ipc.address === address) return win;
        }
        return null;
    }

    function iconForClass(cls) {
        if (!cls || cls.length === 0) return "";
        try {
            let low = cls.toLowerCase();
            if (low.indexOf("opencode") !== -1)
                return "/usr/share/icons/hicolor/128x128/apps/ai.opencode.png";
            let p = Quickshell.iconPath(low);
            if (p && p.length > 0) return p;
            p = Quickshell.iconPath(cls);
            return p ? p : "";
        } catch (e) {
            return "";
        }
    }

    function iconsForSpace(space) {
        let out = [];
        let seen = ({});
        let wins = space && space.wins ? space.wins : [];
        for (let i = 0; i < wins.length && out.length < 4; i++) {
            let ic = iconForClass(wins[i].class);
            if (ic === "" || seen[ic]) continue;
            seen[ic] = true;
            out.push(ic);
        }
        return out;
    }

    // Bo cuc thu nho: dua tren toa do/kich thuoc that cua tung cua so trong workspace.
    function layoutFor(space) {
        let wins = space && space.wins ? space.wins : [];
        if (wins.length === 0) return ({ bw: 1, bh: 1, cells: [] });

        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (let i = 0; i < wins.length; i++) {
            let w = wins[i];
            minX = Math.min(minX, w.x);
            minY = Math.min(minY, w.y);
            maxX = Math.max(maxX, w.x + w.w);
            maxY = Math.max(maxY, w.y + w.h);
        }
        if (!isFinite(minX) || !isFinite(minY)) return ({ bw: 1, bh: 1, cells: [] });

        let bw = Math.max(1, maxX - minX);
        let bh = Math.max(1, maxY - minY);

        let cells = [];
        for (let i = 0; i < wins.length; i++) {
            let w = wins[i];
            cells.push({
                address: w.address,
                fx: (w.x - minX) / bw,
                fy: (w.y - minY) / bh,
                fw: Math.max(0.02, w.w / bw),
                fh: Math.max(0.02, w.h / bh)
            });
        }
        return ({ bw: bw, bh: bh, cells: cells });
    }

    readonly property int count: root.spaces.length
    readonly property real spacing: root.s(10)
    readonly property real cardW: {
        let n = Math.max(1, root.count);
        let avail = Math.max(root.s(190), root.width - root.s(140) - (n - 1) * root.spacing);
        return Math.round(Math.min(root.s(300), avail / n));
    }
    readonly property real cardH: Math.round(root.cardW * 0.64 + root.s(34))

    Rectangle {
        id: panel

        property real anim: root.active ? 1.0 : 0.0
        Behavior on anim {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        visible: root.active || anim > 0.001
        opacity: anim
        scale: 0.97 + 0.03 * anim

        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.round(panelContent.implicitWidth + root.s(32))
        height: Math.round(panelContent.implicitHeight + root.s(28))
        radius: root.s(18)
        color: Qt.alpha(ThemeBackend.base, 0.72)
        border.width: 1
        border.color: Qt.alpha(ThemeBackend.overlay0, 0.25)

        Column {
            id: panelContent
            x: Math.round((parent.width - implicitWidth) / 2)
            y: root.s(14)
            spacing: root.s(10)

        Row {
            id: panelRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.spacing

            Repeater {
                model: root.spaces

                Rectangle {
                    id: tile

                    required property var modelData
                    required property int index

                    readonly property bool isSelected: (index + 1) === root.sel
                    readonly property bool isCurrentSpace: modelData && modelData.id === root.currentSpace
                    readonly property var winsInSpace: modelData && modelData.wins ? modelData.wins : []
                    readonly property int winCount: winsInSpace.length
                    readonly property var icons: root.iconsForSpace(modelData)

                    width: root.cardW
                    height: root.cardH
                    radius: root.s(12)
                    color: isSelected ? Qt.alpha(ThemeBackend.surface0, 0.62) : Qt.alpha(ThemeBackend.base, 0.30)
                    border.width: isSelected ? 2 : 1
                    border.color: isSelected ? ThemeBackend.mauve : Qt.alpha(ThemeBackend.overlay0, 0.22)

                    Rectangle {
                        id: thumbArea

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: root.s(6)
                        height: tile.height - root.s(36)
                        radius: root.s(8)
                        color: "black"
                        clip: true

                        Item {
                            id: miniMap
                            anchors.fill: parent

                            readonly property var layout: root.layoutFor(tile.modelData)
                            readonly property real fit: Math.min(
                                width / Math.max(1, layout.bw),
                                height / Math.max(1, layout.bh)
                            )
                            readonly property real offX: (width - layout.bw * fit) / 2
                            readonly property real offY: (height - layout.bh * fit) / 2

                            Repeater {
                                model: miniMap.layout.cells

                                Rectangle {
                                    required property var modelData

                                    x: Math.round(miniMap.offX + modelData.fx * miniMap.layout.bw * miniMap.fit) + 1
                                    y: Math.round(miniMap.offY + modelData.fy * miniMap.layout.bh * miniMap.fit) + 1
                                    width: Math.max(root.s(6), Math.round(modelData.fw * miniMap.layout.bw * miniMap.fit) - 2)
                                    height: Math.max(root.s(6), Math.round(modelData.fh * miniMap.layout.bh * miniMap.fit) - 2)
                                    radius: root.s(4)
                                    color: "black"
                                    clip: true

                                    ScreencopyView {
                                        anchors.fill: parent
                                        captureSource: root.toplevelFor(modelData.address) ? root.toplevelFor(modelData.address).wayland : null
                                        live: root.active && tile.isCurrentSpace
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: tile.winCount === 0
                            text: "Trống"
                            color: Qt.alpha(ThemeBackend.subtext0, 0.6)
                            font.pixelSize: root.s(10)
                        }
                    }

                    Rectangle {
                        visible: tile.winCount > 1
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: root.s(10)
                        width: root.s(20)
                        height: width
                        radius: width / 2
                        color: Qt.alpha(ThemeBackend.mauve, 0.92)

                        Text {
                            anchors.centerIn: parent
                            text: tile.winCount
                            color: ThemeBackend.base
                            font.pixelSize: root.s(11)
                            font.bold: true
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.leftMargin: root.s(9)
                        anchors.rightMargin: root.s(9)
                        anchors.bottomMargin: root.s(5)
                        height: root.s(22)
                        spacing: root.s(6)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tile.modelData.id
                            color: tile.isSelected ? ThemeBackend.mauve : ThemeBackend.text
                            font.pixelSize: root.s(14)
                            font.bold: true
                        }

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.s(3)

                            Repeater {
                                model: tile.icons

                                Image {
                                    required property var modelData
                                    width: root.s(16)
                                    height: width
                                    source: modelData
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tile.winCount + " cửa sổ"
                            color: Qt.alpha(ThemeBackend.subtext0, 0.8)
                            font.pixelSize: root.s(10)
                        }
                    }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Thả Alt để chuyển  •  Esc để huỷ"
            color: Qt.alpha(ThemeBackend.subtext0, 0.8)
            font.pixelSize: root.s(11)
        }
        }
    }

    mask: Region {
        item: root.active ? panel : null
    }
}
