import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../../reusables"
import "../../../"

Item {
    id: iconsFaceRoot
    property var widget: null

    implicitWidth: wsRow.implicitWidth
    implicitHeight: wsRow.implicitHeight

    property int revision: 0

    Connections {
        target: Hyprland
        ignoreUnknownSignals: true
        function onRawEvent() { iconsFaceRoot.revision++; }
        function onFocusedWorkspaceChanged() { iconsFaceRoot.revision++; }
    }

    function appIdForWindow(win) {
        if (!win) return "";
        if (win.wayland && win.wayland.appId) return win.wayland.appId;
        let ipc = win.lastIpcObject;
        if (ipc) {
            if (ipc.class) return ipc.class;
            if (ipc.initialClass) return ipc.initialClass;
        }
        return "";
    }

    function iconForAppId(appId) {
        if (!appId || appId.length === 0) return "";
        let lowId0 = appId.toLowerCase();
        if (lowId0 === "ai.opencode" || lowId0 === "ai.opencode.desktop")
            return "/usr/share/icons/hicolor/128x128/apps/ai.opencode.png";
        if (typeof DesktopEntries === "undefined") return "";
        let candidates = [appId, appId + ".desktop", appId.toLowerCase(), appId.toLowerCase() + ".desktop"];
        for (let i = 0; i < candidates.length; i++) {
            let entry = DesktopEntries.byId(candidates[i]);
            if (entry && entry.icon && entry.icon.length > 0) return entry.icon;
        }
        let entry = DesktopEntries.heuristicLookup(appId);
        if (entry && entry.icon && entry.icon.length > 0) return entry.icon;
        let apps = DesktopEntries.applications;
        if (apps && apps.values) {
            let lower = appId.toLowerCase();
            let vals = apps.values;
            for (let j = 0; j < vals.length; j++) {
                let e = vals[j];
                if (!e || !e.icon || e.icon.length === 0) continue;
                let name = (e.name || "").toLowerCase();
                let id = (e.id || "").toLowerCase();
                if (name === lower || id === lower || id.indexOf(lower) !== -1) return e.icon;
            }
        }
        return "";
    }

    function isShown(index) {
        if (!widget) return true;
        if (typeof widget.isShown === "function") return widget.isShown(index);
        return true;
    }

    function getAppIcon(wsId) {
        let dummy = revision;
        let toplevels = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (let i = 0; i < toplevels.length; i++) {
            let win = toplevels[i];
            if (!win || !win.workspace || win.workspace.id !== wsId) continue;
            let appId = appIdForWindow(win);
            if (appId.length > 0) return iconForAppId(appId);
        }
        return "";
    }

    RowLayout {
        id: wsRow
        spacing: widget ? widget.s(6) : 6
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: widget ? widget.workspaceCount : 6

            Rectangle {
                id: wsTile
                required property int index

                readonly property int wsId: index + 1
                readonly property bool isActive: widget ? (widget.activeIndex === index) : false
                readonly property string appIconName: getAppIcon(wsId)
                readonly property bool hasApp: appIconName !== ""
                readonly property bool shown: {
                    let dummy = iconsFaceRoot.revision;
                    if (widget) {
                        widget.hideEmptyWorkspaces;
                        widget.activeIndex;
                    }
                    if (widget && widget.hideEmptyWorkspaces === false) return true;
                    return isShown(index) && (isActive || hasApp);
                }

                visible: shown
                width: shown ? (widget ? widget.s(26) : 26) : 0
                height: widget ? widget.s(26) : 26
                radius: widget ? widget.s(6) : 6
                opacity: shown ? 1.0 : 0.0

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                color: isActive ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.08)
                border.width: isActive ? 1 : 0
                border.color: isActive ? ThemeBackend.mauve : "transparent"

                Image {
                    id: iconImageItem
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    asynchronous: true
                    anchors.centerIn: parent
                    width: widget ? widget.s(16) : 16
                    height: width
                    source: {
                        if (!wsTile.hasApp) return "";
                        let ic = wsTile.appIconName;
                        if (ic.startsWith("file://") || ic.startsWith("image://") || ic.startsWith("http")) return ic;
                        if (ic.startsWith("/")) return "file://" + ic;
                        return Quickshell.iconPath(ic);
                    }
                    visible: wsTile.hasApp && status !== Image.Error
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("IconsFace: failed to load icon for ws", wsTile.wsId, "name:", wsTile.appIconName);
                        }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: widget ? widget.s(5) : 5
                    height: width
                    radius: width / 2
                    color: ThemeBackend.mauve
                    visible: (!wsTile.hasApp || iconImageItem.status === Image.Error) && wsTile.isActive
                }


                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (widget) widget.focusWorkspace(wsTile.index);
                    }
                }
            }
        }
    }
}
