import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "../"
import "../reusables"
import "../reusables/guide"

GuideTab {
    id: batteryTabRoot

    readonly property var dev: UPower.displayDevice
    readonly property bool ready: dev ? dev.ready : false
    readonly property bool isLaptop: ready && dev.isLaptopBattery

    readonly property int capacity: ready ? Math.round(dev.percentage * 100) : 0
    readonly property int deviceState: ready ? dev.state : UPowerDeviceState.Unknown
    readonly property bool charging: deviceState === UPowerDeviceState.Charging || deviceState === UPowerDeviceState.PendingCharge
    readonly property bool full: deviceState === UPowerDeviceState.FullyCharged
    readonly property bool discharging: deviceState === UPowerDeviceState.Discharging
    readonly property int timeLeft: charging ? dev.timeToFull : (discharging ? dev.timeToEmpty : 0)

    property real sysFullWh: 0
    property real sysDesignWh: 0

    readonly property int healthPercent: {
        if (batteryTabRoot.sysDesignWh > 0)
            return Math.round(batteryTabRoot.sysFullWh / batteryTabRoot.sysDesignWh * 100);
        if (!ready || !dev.healthSupported) return -1;
        let h = dev.healthPercentage;
        if (h <= 1.0) h = h * 100.0;
        return Math.round(h);
    }
    readonly property real energyNow: ready ? dev.energy : 0
    readonly property real energyFull: ready ? dev.energyCapacity : 0

    property int cycles: -1
    property string tempC: ""
    property bool conservationOn: false

    property bool limitEnabled: Config.getSetting("battery.enabled", true)
    property int limitTarget: Config.getSetting("battery.target", 80)
    readonly property int limitResume: Math.max(50, limitTarget - 5)

    function stateLabel() {
        if (!ready) return I18n.t("guide.battery.unknown", "Unknown");
        if (full) return I18n.t("guide.battery.state_full", "Fully charged");
        if (charging) return I18n.t("guide.battery.state_charging", "Charging");
        if (discharging) return I18n.t("guide.battery.state_discharging", "Discharging");
        return I18n.t("guide.battery.state_idle", "Not charging");
    }

    function fmtTime(sec) {
        if (!sec || sec <= 0) return "--";
        let h = Math.floor(sec / 3600);
        let m = Math.round((sec % 3600) / 60);
        if (m === 60) { h += 1; m = 0; }
        return h + "h " + m + "m";
    }

    function saveLimit() {
        Config.setSetting("battery", {
            "enabled": batteryTabRoot.limitEnabled,
            "target": batteryTabRoot.limitTarget,
            "resume": batteryTabRoot.limitResume
        });
    }

    Process {
        id: batSysProc
        command: ["bash", "-c",
            "B=/sys/class/power_supply/BAT1; " +
            "C=/sys/devices/pci0000:00/0000:00:1f.0/PNP0C09:00/VPC2004:00/conservation_mode; " +
            "echo \"cycles=$(cat $B/cycle_count 2>/dev/null)\"; " +
            "echo \"temp=$(cat $B/temp 2>/dev/null)\"; " +
            "echo \"cons=$(cat $C 2>/dev/null)\"; " +
            "echo \"efull=$(cat $B/energy_full 2>/dev/null)\"; " +
            "echo \"edesign=$(cat $B/energy_full_design 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let map = {};
                let lines = (this.text || "").trim().split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let idx = lines[i].indexOf("=");
                    if (idx > 0) map[lines[i].slice(0, idx).trim()] = lines[i].slice(idx + 1).trim();
                }
                let cy = parseInt(map["cycles"]);
                batteryTabRoot.cycles = isNaN(cy) ? -1 : cy;
                let t = parseInt(map["temp"]);
                batteryTabRoot.tempC = isNaN(t) ? "" : (t / 10.0).toFixed(1);
                batteryTabRoot.conservationOn = (map["cons"] || "") === "1";
                let ef = parseInt(map["efull"]);
                let ed = parseInt(map["edesign"]);
                batteryTabRoot.sysFullWh = isNaN(ef) ? 0 : ef / 1000000.0;
                batteryTabRoot.sysDesignWh = isNaN(ed) ? 0 : ed / 1000000.0;
            }
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: batteryTabRoot.visible
        triggeredOnStart: true
        onTriggered: {
            if (!batSysProc.running) batSysProc.running = true;
        }
    }

    Connections {
        target: typeof Config !== "undefined" ? Config : null
        function onSettingsLoaded() {
            batteryTabRoot.limitEnabled = Config.getSetting("battery.enabled", true);
            batteryTabRoot.limitTarget = Config.getSetting("battery.target", 80);
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: rootObj.s(8)
        anchors.leftMargin: rootObj.s(8)
        anchors.rightMargin: rootObj.s(8)
        anchors.bottomMargin: rootObj.s(8)
        contentHeight: settingsCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: settingsCol
            width: parent.width
            spacing: rootObj.s(6)

            SettingsBlob {
                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰂅"
                    iconAccentColor: ThemeBackend.green
                    title: I18n.t("guide.battery.title", "Battery")
                    titleBold: true
                    description: batteryTabRoot.ready
                        ? batteryTabRoot.stateLabel() + (batteryTabRoot.timeLeft > 0 ? " · " + batteryTabRoot.fmtTime(batteryTabRoot.timeLeft) : "")
                        : I18n.t("guide.battery.not_detected", "No battery detected")

                    Text {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        text: batteryTabRoot.ready ? batteryTabRoot.capacity + "%" : "--"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: rootObj.s(22)
                        font.bold: true
                        color: ThemeBackend.text
                    }
                }

                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰚥"
                    title: I18n.t("guide.battery.state_title", "Status")
                    description: batteryTabRoot.ready ? batteryTabRoot.stateLabel() : "--"
                }

                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰔚"
                    title: batteryTabRoot.charging
                        ? I18n.t("guide.battery.until_full", "Time until full")
                        : I18n.t("guide.battery.remaining", "Time remaining")
                    description: batteryTabRoot.timeLeft > 0 ? batteryTabRoot.fmtTime(batteryTabRoot.timeLeft) : "--"
                }
            }

            SettingsBlob {
                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰓅"
                    title: I18n.t("guide.battery.health_title", "Battery health")
                    description: batteryTabRoot.sysDesignWh > 0
                        ? batteryTabRoot.sysFullWh.toFixed(1) + " / " + batteryTabRoot.sysDesignWh.toFixed(1) + " Wh (" + I18n.t("guide.battery.design_capacity", "design") + ")"
                        : I18n.t("guide.battery.health_desc", "Maximum capacity compared to design capacity")

                    Text {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        text: batteryTabRoot.healthPercent >= 0 ? batteryTabRoot.healthPercent + "%" : "--"
                        font.family: ThemeBackend.fontFamily
                        font.pixelSize: rootObj.s(13)
                        font.bold: true
                        color: batteryTabRoot.healthPercent >= 0 && batteryTabRoot.healthPercent < 80 ? ThemeBackend.red : ThemeBackend.text
                    }
                }

                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰔄"
                    title: I18n.t("guide.battery.cycles_title", "Charge cycles")
                    description: batteryTabRoot.cycles >= 0 ? String(batteryTabRoot.cycles) : "--"
                }

                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰔏"
                    title: I18n.t("guide.battery.temp_title", "Battery temperature")
                    description: (batteryTabRoot.tempC !== "" && parseFloat(batteryTabRoot.tempC) > 0) ? batteryTabRoot.tempC + " °C" : "--"
                }
            }

            SettingsBlob {
                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰂅"
                    iconAccentColor: ThemeBackend.mauve
                    title: I18n.t("guide.battery.limit_title", "Charge limit")
                    titleBold: true
                    wrapText: true
                    description: I18n.t("guide.battery.limit_desc", "Stop charging at the set level to slow down battery wear")

                    Toggle {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        checked: batteryTabRoot.limitEnabled
                        accentColor: ThemeBackend.mauve
                        baseColor: ThemeBackend.surface1
                        handleColor: ThemeBackend.crust
                        handleOffColor: ThemeBackend.text
                        onToggled: function(c) {
                            batteryTabRoot.limitEnabled = c;
                            batteryTabRoot.saveLimit();
                        }
                    }
                }

                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰚥"
                    title: I18n.t("guide.battery.target_title", "Maximum charge level")
                    wrapText: true
                    description: I18n.t("guide.battery.target_desc", "Charging stops here and resumes when the level drops {resume}%")
                        .replace("{resume}", batteryTabRoot.limitResume)
                    opacity: batteryTabRoot.limitEnabled ? 1.0 : 0.5

                    NumberSelector {
                        enabled: batteryTabRoot.limitEnabled
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        value: batteryTabRoot.limitTarget
                        from: 60
                        to: 100
                        stepSize: 5
                        suffix: "%"
                        fontFamily: ThemeBackend.fontFamily
                        baseColor: Qt.alpha(ThemeBackend.surface0, 0.7)
                        accentColor: ThemeBackend.mauve
                        buttonColor: ThemeBackend.surface1
                        buttonTextColor: ThemeBackend.text
                        textColor: ThemeBackend.text
                        subTextColor: ThemeBackend.subtext0
                        borderColor: Qt.alpha(ThemeBackend.surface2, 0.5)
                        cornerRadius: ThemeBackend.borderRadius
                        onValueChanged: {
                            if (Math.round(value) !== batteryTabRoot.limitTarget) {
                                batteryTabRoot.limitTarget = Math.round(value);
                                batteryTabRoot.saveLimit();
                            }
                        }
                    }
                }

                SettingsRow {
                    rootObj: batteryTabRoot.rootObj
                    icon: "󰄬"
                    title: I18n.t("guide.battery.applied_title", "Current charge protection")
                    description: batteryTabRoot.conservationOn
                        ? I18n.t("guide.battery.applied_on", "Active — charging is currently blocked")
                        : I18n.t("guide.battery.applied_off", "Inactive — the battery may charge normally")
                    opacity: 0.85
                }
            }
        }
    }
}
