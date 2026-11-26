import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../reusables"
import "../../reusables/guide"
import "../../reusables/buttons"

GuideTab {
    id: loginTab
    subTabIndex: 3

    property var themes: []
    property string currentTheme: ""
    property bool loading: true
    property bool applying: false
    property string pendingTheme: ""
    property string statusText: ""
    property bool statusIsError: false
    property string searchText: ""
    property string deleteTarget: ""
    property string deleteTargetTitle: ""
    property bool deleteTargetSymlink: false

    readonly property var filteredThemes: {
        let q = loginTab.searchText.trim().toLowerCase();
        if (q === "") return loginTab.themes;
        return loginTab.themes.filter(function(t) {
            let hay = (t.title + " " + t.name + " " + (t.description || "")).toLowerCase();
            return hay.indexOf(q) !== -1;
        });
    }

    property string pendingPreviewTheme: ""

    function previewTheme(name) {
        if (!name) return;
        let item = loginTab.themes.find(function(t) { return t.name === name; });
        if (item && item.valid === false) {
            loginTab.statusIsError = true;
            loginTab.statusText = I18n.t("guide.display.login.invalid_error", "Theme này bị lỗi QML, không thể xem trước hoặc áp dụng.");
            return;
        }
        // đóng Cài đặt trước, đợi hiệu ứng đóng xong rồi mới mở preview
        if (rootObj && typeof rootObj.closePopup === "function") rootObj.closePopup();
        loginTab.pendingPreviewTheme = name;
        previewLaunchTimer.restart();
    }

    Timer {
        id: previewLaunchTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (loginTab.pendingPreviewTheme === "") return;
            let theme = loginTab.pendingPreviewTheme;
            loginTab.pendingPreviewTheme = "";
            Quickshell.execDetached(["bash", Caching.home + "/.local/bin/sddm-theme-preview", theme]);
        }
    }

    function reload(keepStatus) {
        loginTab.loading = true;
        if (keepStatus !== true) {
            loginTab.statusText = "";
            loginTab.statusIsError = false;
        }
        listProc.running = true;
    }

    function applyTheme(name) {
        if (!name || loginTab.applying) return;
        let item = loginTab.themes.find(function(t) { return t.name === name; });
        if (item && item.valid === false) {
            loginTab.statusIsError = true;
            loginTab.statusText = I18n.t("guide.display.login.invalid_error", "Theme này bị lỗi QML, không thể xem trước hoặc áp dụng.");
            return;
        }
        loginTab.applying = true;
        loginTab.pendingTheme = name;
        loginTab.statusText = "";
        applyProc.command = ["sudo", "-n", "/usr/local/bin/sddm-theme-set", name];
        applyProc.running = true;
    }

    function requestDelete(name, title, isSymlink) {
        if (!name) return;
        loginTab.deleteTarget = name;
        loginTab.deleteTargetTitle = title || name;
        loginTab.deleteTargetSymlink = isSymlink === true;
    }

    function cancelDelete() {
        loginTab.deleteTarget = "";
        loginTab.deleteTargetTitle = "";
        loginTab.deleteTargetSymlink = false;
    }

    function doDelete() {
        if (loginTab.deleteTarget === "") return;
        deleteProc.target = loginTab.deleteTarget;
        deleteProc.command = ["sudo", "-n", "/usr/local/bin/sddm-theme-delete", loginTab.deleteTarget];
        deleteProc.running = true;
    }

    function typeLabel(t) {
        if (t === "video") return I18n.t("guide.display.login.type_video", "Video");
        if (t === "color") return I18n.t("guide.display.login.type_color", "Màu nền");
        if (t === "pure") return I18n.t("guide.display.login.type_pure", "Tối giản");
        return I18n.t("guide.display.login.type_image", "Ảnh nền");
    }

    Process {
        id: listProc
        command: [Caching.home + "/.local/bin/sddm-theme-list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") {
                    loginTab.themes = [];
                    loginTab.loading = false;
                    return;
                }
                try {
                    let list = JSON.parse(raw);
                    loginTab.themes = list;
                    let cur = list.find(function(t) { return t.current; });
                    loginTab.currentTheme = cur ? cur.name : "";
                } catch (e) {
                    loginTab.themes = [];
                    loginTab.currentTheme = "";
                    loginTab.statusText = I18n.t("guide.display.login.error", "Không đọc được danh sách theme SDDM");
                    loginTab.statusIsError = true;
                }
                loginTab.loading = false;
            }
        }
        onExited: function(code) {
            if (code !== 0 && loginTab.loading) {
                loginTab.loading = false;
                loginTab.statusText = I18n.t("guide.display.login.error", "Không đọc được danh sách theme SDDM");
                loginTab.statusIsError = true;
            }
        }
    }

    Process {
        id: applyProc
        onExited: function(code) {
            loginTab.applying = false;
            if (code === 0) {
                loginTab.statusIsError = false;
                loginTab.statusText = I18n.t("guide.display.login.applied", "Đã đặt theme. Có hiệu lực ở lần đăng xuất hoặc khởi động lại tiếp theo.");
                loginTab.reload(true);
            } else {
                loginTab.statusIsError = true;
                loginTab.statusText = I18n.t("guide.display.login.apply_error", "Không thể đổi theme. Kiểm tra quyền sudo.");
            }
        }
    }

    Process {
        id: deleteProc
        property string target: ""
        onExited: function(code) {
            loginTab.cancelDelete();
            if (code === 0) {
                loginTab.statusIsError = false;
                loginTab.statusText = I18n.t("guide.display.login.deleted", "Đã xóa theme.");
                loginTab.reload(true);
            } else {
                loginTab.statusIsError = true;
                loginTab.statusText = I18n.t("guide.display.login.delete_error", "Không thể xóa theme (có thể là theme đang dùng).");
            }
        }
    }

    Component.onCompleted: {
        loginTab.searchText = "";
        reload();
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: rootObj.s(4)
        anchors.leftMargin: rootObj.s(8)
        anchors.rightMargin: rootObj.s(8)
        anchors.bottomMargin: rootObj.s(4)
        contentHeight: loginCol.implicitHeight + rootObj.s(16)
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar {
            active: parent.moving || parent.movingVertically
            width: rootObj.s(4)
            policy: ScrollBar.AsNeeded
            contentItem: Rectangle {
                implicitWidth: rootObj.s(4)
                radius: rootObj.s(2)
                color: ThemeBackend.surface2
            }
        }

        ColumnLayout {
            id: loginCol
            width: parent.width - (parent.contentHeight > parent.height ? rootObj.s(6) : 0)
            spacing: rootObj.s(6)

            SettingsRow {
                rootObj: loginTab.rootObj
                settingId: "login_screen_theme"
                icon: "󰍃"
                title: I18n.t("guide.display.login.title", "Giao diện đăng nhập")
                description: I18n.t("guide.display.login.desc", "Chọn giao diện SDDM hiển thị khi khởi động máy")
                searchKeywords: "login screen sddm theme đăng nhập khởi động boot"

                RowLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: rootObj.s(6)

                    ClickButton {
                        Layout.alignment: Qt.AlignVCenter
                        maxWidth: rootObj.s(130)
                        implicitHeight: rootObj.s(32)
                        cornerRadius: ThemeBackend.borderRadius
                        buttonText: I18n.t("guide.display.login.preview", "Xem trước")
                        buttonIcon: "󰈈"
                        iconFontSize: rootObj.s(14)
                        textFontSize: rootObj.s(12)
                        accentColor: ThemeBackend.mauve
                        textColor: ThemeBackend.crust
                        enabled: loginTab.currentTheme !== ""
                        opacity: enabled ? 1.0 : 0.45
                        onClicked: loginTab.previewTheme(loginTab.currentTheme)
                    }

                    ClickButton {
                        Layout.alignment: Qt.AlignVCenter
                        maxWidth: rootObj.s(130)
                        implicitHeight: rootObj.s(32)
                        cornerRadius: ThemeBackend.borderRadius
                        buttonText: I18n.t("guide.display.login.refresh", "Làm mới")
                        buttonIcon: "󰑓"
                        iconFontSize: rootObj.s(14)
                        textFontSize: rootObj.s(12)
                        accentColor: ThemeBackend.mauve
                        textColor: ThemeBackend.crust
                        onClicked: loginTab.reload()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: hintText.implicitHeight + rootObj.s(20)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.35)

                Text {
                    id: hintText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: rootObj.s(12)
                    anchors.rightMargin: rootObj.s(12)
                    text: I18n.t("guide.display.login.hint", "Theme chỉ đổi ở màn hình đăng nhập. Thay đổi áp dụng sau khi đăng xuất hoặc khởi động lại, không ảnh hưởng phiên đang dùng.")
                        + "\n" + I18n.t("guide.display.login.preview_hint", "Bấm thẻ để xem trước • Bấm “Áp dụng” để đổi theme. Cài đặt tự đóng khi xem; nhấn Super+Q để đóng cửa sổ xem trước.")
                        + "\n" + I18n.t("guide.display.login.preview_warning", "Cửa sổ xem trước chỉ để xem giao diện — đừng nhập mật khẩu hay bấm Restart/Shutdown.")
                    color: ThemeBackend.subtext0
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: rootObj.s(11)
                    wrapMode: Text.WordWrap
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: rootObj.s(8)

                Input {
                    id: searchInput
                    Layout.fillWidth: true
                    implicitHeight: rootObj.s(34)
                    placeholderText: I18n.t("guide.display.login.search", "Tìm theme...")
                    baseColor: Qt.alpha(ThemeBackend.surface0, 0.5)
                    accentColor: ThemeBackend.mauve
                    textColor: ThemeBackend.text
                    subTextColor: ThemeBackend.subtext0
                    borderColor: Qt.alpha(ThemeBackend.surface2, 0.6)
                    cornerRadius: ThemeBackend.borderRadius
                    fontPixelSize: rootObj.s(11)
                    charSpacing: 1
                    onTextEdited: function(newText) { loginTab.searchText = newText; }
                }

                Text {
                    Layout.alignment: Qt.AlignVCenter
                    text: loginTab.filteredThemes.length + " / " + loginTab.themes.length
                    color: ThemeBackend.subtext0
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: rootObj.s(10)
                }
            }

            Text {
                Layout.fillWidth: true
                visible: loginTab.statusText !== ""
                text: loginTab.statusText
                color: loginTab.statusIsError ? ThemeBackend.red : ThemeBackend.mauve
                font.family: ThemeBackend.fontFamily
                font.pixelSize: rootObj.s(11)
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: rootObj.s(72)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.3)
                visible: loginTab.loading

                RowLayout {
                    anchors.centerIn: parent
                    spacing: rootObj.s(8)
                    BusyIndicator {
                        running: loginTab.loading
                        implicitWidth: rootObj.s(18)
                        implicitHeight: rootObj.s(18)
                        palette.accent: ThemeBackend.mauve
                    }
                    Text {
                        text: I18n.t("guide.display.login.loading", "Đang tải theme...")
                        color: ThemeBackend.subtext0
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: rootObj.s(11)
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: rootObj.s(8)
                columnSpacing: rootObj.s(8)
                visible: !loginTab.loading && loginTab.filteredThemes.length > 0

                Repeater {
                    model: loginTab.filteredThemes
                    delegate: Item {
                        id: themeCard
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: rootObj.s(150)
                        scale: cardHover.hovered ? 1.02 : 1.0
                        opacity: themeCard.modelData.valid === false ? 0.62 : 1.0
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                        HoverHandler { id: cardHover }

                        Rectangle {
                            anchors.fill: parent
                            radius: ThemeBackend.borderRadius
                            color: Qt.alpha(ThemeBackend.surface0, 0.5)
                            border.width: themeCard.modelData.current ? 2 : 1
                            border.color: themeCard.modelData.valid === false
                                ? ThemeBackend.red
                                : (themeCard.modelData.current
                                    ? ThemeBackend.mauve
                                    : Qt.alpha(ThemeBackend.surface2, cardHover.hovered ? 0.9 : 0.5))
                            clip: true

                            Item {
                                id: previewArea
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: rootObj.s(94)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    visible: themeCard.modelData.preview !== ""
                                    source: themeCard.modelData.preview !== "" ? "file://" + themeCard.modelData.preview : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                    mipmap: true
                                    sourceSize: Qt.size(480, 270)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: themeCard.modelData.preview === "" && themeCard.modelData.type === "color"
                                    color: themeCard.modelData.color !== "" ? themeCard.modelData.color : ThemeBackend.surface1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰏘"
                                        color: Qt.rgba(0.55, 0.55, 0.55, 0.65)
                                        font.family: ThemeBackend.iconFont
                                        font.pixelSize: rootObj.s(30)
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: themeCard.modelData.preview === "" && themeCard.modelData.type !== "color"
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: ThemeBackend.surface1 }
                                        GradientStop { position: 1.0; color: ThemeBackend.surface0 }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰍃"
                                        color: Qt.alpha(ThemeBackend.text, 0.5)
                                        font.family: ThemeBackend.iconFont
                                        font.pixelSize: rootObj.s(30)
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    height: rootObj.s(26)
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: Qt.alpha(ThemeBackend.surface0, 0.75) }
                                    }
                                }

                                Rectangle {
                                    visible: themeCard.modelData.current
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: rootObj.s(6)
                                    implicitWidth: currentLabel.implicitWidth + rootObj.s(12)
                                    implicitHeight: rootObj.s(18)
                                    radius: rootObj.s(9)
                                    color: ThemeBackend.mauve
                                    Text {
                                        id: currentLabel
                                        anchors.centerIn: parent
                                        text: I18n.t("guide.display.login.current", "Đang dùng")
                                        color: ThemeBackend.crust
                                        font.family: ThemeBackend.fontFamily
                                        font.pixelSize: rootObj.s(9)
                                        font.bold: true
                                    }
                                }



                                Rectangle {
                                    anchors.fill: parent
                                    visible: loginTab.applying && loginTab.pendingTheme === themeCard.modelData.name
                                    color: Qt.rgba(0, 0, 0, 0.55)
                                    Text {
                                        anchors.centerIn: parent
                                        text: I18n.t("guide.display.login.applying", "Đang áp dụng...")
                                        color: "white"
                                        font.family: ThemeBackend.fontFamily
                                        font.pixelSize: rootObj.s(11)
                                    }
                                }
                            }

                            Column {
                                anchors.top: previewArea.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: rootObj.s(10)
                                anchors.rightMargin: rootObj.s(34)
                                anchors.topMargin: rootObj.s(5)
                                spacing: rootObj.s(1)

                                Text {
                                    width: parent.width
                                    text: themeCard.modelData.title
                                    color: ThemeBackend.text
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: rootObj.s(12)
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Text {
                                    width: parent.width
                                    text: loginTab.typeLabel(themeCard.modelData.type)
                                        + (themeCard.modelData.font ? " • " + themeCard.modelData.font : "")
                                    color: ThemeBackend.subtext0
                                    font.family: ThemeBackend.fontFamily
                                    font.pixelSize: rootObj.s(9)
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof Sounds !== "undefined") Sounds.playSfx("reusables/clickbutton/click.wav");
                                loginTab.previewTheme(themeCard.modelData.name);
                            }
                        }

                        Rectangle {
                            z: 20
                            visible: !themeCard.modelData.current && themeCard.modelData.valid !== false
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: rootObj.s(6)
                            implicitWidth: applyLabel.implicitWidth + rootObj.s(14)
                            implicitHeight: rootObj.s(20)
                            radius: rootObj.s(10)
                            color: ThemeBackend.mauve

                            Text {
                                id: applyLabel
                                anchors.centerIn: parent
                                text: I18n.t("guide.display.login.apply", "Áp dụng")
                                color: ThemeBackend.crust
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(9)
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: loginTab.applyTheme(themeCard.modelData.name)
                            }
                        }

                        Rectangle {
                            z: 20
                            visible: themeCard.modelData.valid === false && !themeCard.modelData.current
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: rootObj.s(6)
                            implicitWidth: invalidLabel.implicitWidth + rootObj.s(14)
                            implicitHeight: rootObj.s(20)
                            radius: rootObj.s(10)
                            color: ThemeBackend.red

                            Text {
                                id: invalidLabel
                                anchors.centerIn: parent
                                text: I18n.t("guide.display.login.invalid", "Theme lỗi")
                                color: ThemeBackend.crust
                                font.family: ThemeBackend.fontFamily
                                font.pixelSize: rootObj.s(9)
                                font.bold: true
                            }
                        }

                        Rectangle {
                            z: 20
                            width: rootObj.s(24)
                            height: rootObj.s(24)
                            radius: rootObj.s(12)
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: rootObj.s(6)
                            color: Qt.alpha(ThemeBackend.surface0, 0.78)
                            border.width: 1
                            border.color: Qt.alpha(ThemeBackend.surface2, 0.7)

                            Text {
                                anchors.centerIn: parent
                                text: "󰈈"
                                color: ThemeBackend.text
                                font.family: ThemeBackend.iconFont
                                font.pixelSize: rootObj.s(13)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: loginTab.previewTheme(themeCard.modelData.name)
                            }
                        }

                        Rectangle {
                            z: 20
                            visible: !themeCard.modelData.current
                            width: rootObj.s(22)
                            height: rootObj.s(22)
                            radius: rootObj.s(11)
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: rootObj.s(6)
                            color: Qt.alpha(ThemeBackend.surface0, 0.8)
                            border.width: 1
                            border.color: Qt.alpha(ThemeBackend.surface2, 0.6)

                            Text {
                                anchors.centerIn: parent
                                text: "󰩹"
                                color: ThemeBackend.red
                                font.family: ThemeBackend.iconFont
                                font.pixelSize: rootObj.s(12)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: loginTab.requestDelete(
                                    themeCard.modelData.name,
                                    themeCard.modelData.title,
                                    themeCard.modelData.symlink
                                )
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: rootObj.s(64)
                radius: ThemeBackend.borderRadius
                color: Qt.alpha(ThemeBackend.surface0, 0.3)
                visible: !loginTab.loading && loginTab.filteredThemes.length === 0

                Text {
                    anchors.centerIn: parent
                    text: loginTab.themes.length === 0 ? I18n.t("guide.display.login.empty", "Không tìm thấy theme SDDM nào trong /usr/share/sddm/themes") : I18n.t("guide.display.login.no_results", "Không tìm thấy theme phù hợp với từ khoá.")
                    color: ThemeBackend.subtext0
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: rootObj.s(11)
                }
            }
        }
    }

    Rectangle {
        id: deleteOverlay
        anchors.fill: parent
        z: 100
        visible: loginTab.deleteTarget !== ""
        color: Qt.rgba(0, 0, 0, 0.55)

        MouseArea {
            anchors.fill: parent
            onClicked: loginTab.cancelDelete()
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - rootObj.s(40), rootObj.s(400))
            implicitHeight: deleteCol.implicitHeight + rootObj.s(28)
            radius: ThemeBackend.borderRadius
            color: ThemeBackend.surface0
            border.width: 1
            border.color: Qt.alpha(ThemeBackend.red, 0.5)

            ColumnLayout {
                id: deleteCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: rootObj.s(16)
                spacing: rootObj.s(8)

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("guide.display.login.delete_title", "Xóa theme?")
                    color: ThemeBackend.text
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: rootObj.s(14)
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: loginTab.deleteTargetTitle
                    color: ThemeBackend.mauve
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: rootObj.s(12)
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: loginTab.deleteTargetSymlink
                        ? I18n.t("guide.display.login.delete_symlink", "Đây là liên kết Qylock — chỉ xóa liên kết, bộ Qylock gốc vẫn còn.")
                        : I18n.t("guide.display.login.delete_folder", "Thư mục theme sẽ bị xóa khỏi SDDM.")
                    color: ThemeBackend.subtext0
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: rootObj.s(10)
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("guide.display.login.delete_warning", "Không thể hoàn tác.")
                    color: ThemeBackend.red
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: rootObj.s(10)
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    spacing: rootObj.s(8)

                    ClickButton {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        implicitHeight: rootObj.s(32)
                        cornerRadius: ThemeBackend.borderRadius
                        buttonText: I18n.t("guide.display.login.cancel", "Hủy")
                        buttonIcon: "󰅖"
                        iconFontSize: rootObj.s(13)
                        textFontSize: rootObj.s(11)
                        accentColor: ThemeBackend.surface1
                        textColor: ThemeBackend.text
                        onClicked: loginTab.cancelDelete()
                    }

                    ClickButton {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        implicitHeight: rootObj.s(32)
                        cornerRadius: ThemeBackend.borderRadius
                        buttonText: I18n.t("guide.display.login.delete", "Xóa")
                        buttonIcon: "󰩹"
                        iconFontSize: rootObj.s(13)
                        textFontSize: rootObj.s(11)
                        accentColor: ThemeBackend.red
                        textColor: ThemeBackend.crust
                        onClicked: loginTab.doDelete()
                    }
                }
            }
        }
    }
}
