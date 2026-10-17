/*
 * SPDX-FileCopyrightText: 2026 Crypto Price contributors
 * SPDX-License-Identifier: MIT
 *
 * Everything about where the price comes from and how it looks.
 *
 * The preset loader lives on this page rather than on its own category on
 * purpose. Two config pages both declaring cfg_sourceUrl would each hold
 * their own copy of the value, and whichever loaded first would win on save.
 * Keeping every key on exactly one page avoids that entirely.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import "presets.js" as Presets

Item {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property var iconModes: ["none", "coin", "custom"]

    property var cfg_iconMode: ""
    property string cfg_coinIcon: ""

    property alias cfg_sourceUrl: sourceUrl.text
    property alias cfg_sourcePath: sourcePath.text
    property alias cfg_tooltipLabel: tooltipLabel.text
    property alias cfg_customUserAgent: customUserAgent.text
    property alias cfg_timeoutSeconds: timeoutSeconds.value

    property alias cfg_refreshRate: refreshRate.value
    property alias cfg_showAge: showAge.checked

    property alias cfg_showIcon: showIcon.checked
    property alias cfg_showText: showText.checked
    property alias cfg_showBackground: showBackground.checked
    property alias cfg_showLabel: showLabel.checked

    property alias cfg_showPricePrefix: showPricePrefix.checked
    property alias cfg_pricePrefix: pricePrefix.text
    property alias cfg_showPriceSuffix: showPriceSuffix.checked
    property alias cfg_priceSuffix: priceSuffix.text

    property alias cfg_controlDecimals: controlDecimals.checked
    property alias cfg_decPlaces: decPlaces.value
    property alias cfg_fontSizePx: fontSize.value

    property alias cfg_iconName: iconName.text

    // A config page gets a fixed height from the dialog, and both of these
    // pages are taller than that. Without a scroll view everything below the
    // fold is simply unreachable. Same pattern as finstats.
    ScrollView {
        id: scroll
        anchors.fill: parent
        clip: true
        // Pin the content width to the viewport, otherwise the vertical
        // scrollbar's own width makes the content overflow sideways and a
        // horizontal scrollbar appears.
        contentWidth: availableWidth

        Kirigami.FormLayout {
            width: scroll.availableWidth

        // ------------------------------------------------------------ presets

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Presets")
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: i18n("Load a source to fill in the fields below. You can adjust anything afterwards.")
        }

        PlasmaComponents.ComboBox {
            id: sourceCombo
            Layout.fillWidth: true
            model: {
                const titles = [];
                for (let i = 0; i < Presets.sources.length; i++) {
                    titles.push(Presets.sources[i].title);
                }
                return titles;
            }
        }

        RowLayout {
            Layout.fillWidth: true

            PlasmaComponents.Button {
                text: i18n("Load selected")
                enabled: sourceCombo.currentIndex >= 0
                onClicked: {
                    const preset = Presets.sources[sourceCombo.currentIndex];

                    sourceUrl.text = preset.url;
                    sourcePath.text = preset.path;
                    tooltipLabel.text = preset.label;
                    pricePrefix.text = preset.symbol;
                    showPricePrefix.checked = true;

                    const coinIndex = Presets.coins.files.indexOf(preset.coin);
                    coinIconCombo.currentIndex = coinIndex >= 0 ? coinIndex : coinIconCombo.count - 1;
                    page.cfg_coinIcon = Presets.coins.files[coinIconCombo.currentIndex];

                    iconModeCombo.currentIndex = 1;
                    page.cfg_iconMode = "coin";

                    loadedLabel.text = i18n("Loaded “%1”.", preset.title);
                    tester.clearStatus();
                }
            }

            PlasmaComponents.Button {
                text: i18n("Test selected preset")
                enabled: sourceCombo.currentIndex >= 0
                onClicked: {
                    const preset = Presets.sources[sourceCombo.currentIndex];
                    probe.url = preset.url;
                    probe.jsonPath = preset.path;
                    probe.test();
                }
            }
        }

        Label {
            id: loadedLabel
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            visible: text !== ""
            text: ""
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("The endpoints were checked by hand in October 2026. Exchange APIs change without warning, so if one stops working the widget will say so in its tooltip rather than silently freezing.")
        }

        // ------------------------------------------------------------- source

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Source")
        }

        TextField {
            id: sourceUrl
            Kirigami.FormData.label: i18n("URL")
            Layout.fillWidth: true
            placeholderText: "https://api.example.com/ticker"
        }

        TextField {
            id: sourcePath
            Kirigami.FormData.label: i18n("JSON path")
            Layout.fillWidth: true
            placeholderText: "result.XXBTZUSD.c[0]"
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("Dots walk objects and brackets walk arrays, so a.b, a.0.b and a[0].b are all understood.")
        }

        TextField {
            id: tooltipLabel
            Kirigami.FormData.label: i18n("Label")
            Layout.fillWidth: true
        }

        PlasmaComponents.SpinBox {
            id: timeoutSeconds
            Kirigami.FormData.label: i18n("Timeout (seconds)")
            from: 1
            to: 120
            stepSize: 1
        }

        TextField {
            id: customUserAgent
            Kirigami.FormData.label: i18n("User-Agent override")
            Layout.fillWidth: true
            placeholderText: i18n("leave empty for the default")
        }

        // Tests whatever is in the fields, which is the more common case.
        SourceTester {
            id: tester
            Layout.fillWidth: true
            url: sourceUrl.text
            jsonPath: sourcePath.text
        }

        // Tests the highlighted preset without touching the fields.
        SourceTester {
            id: probe
            Layout.fillWidth: true
            visible: sourceCombo.currentIndex >= 0
        }

        // ------------------------------------------------------------ updates

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Updates")
        }

        PlasmaComponents.SpinBox {
            id: refreshRate
            Kirigami.FormData.label: i18n("Refresh every (minutes)")
            from: 1
            to: 1440
            stepSize: 1
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("Longer intervals cost nothing but freshness. Exchange APIs rate-limit, so polling faster rarely buys anything.")
        }

        CheckBox {
            id: showAge
            text: i18n("Show how old the price is in the tooltip")
        }

        // ---------------------------------------------------------- appearance

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Appearance")
        }

        CheckBox {
            id: showIcon
            text: i18n("Show an icon")
        }

        PlasmaComponents.ComboBox {
            id: iconModeCombo
            Kirigami.FormData.label: i18n("Icon source")
            Layout.fillWidth: true
            enabled: showIcon.checked
            model: [i18n("None"), i18n("Bundled coin icon"), i18n("Custom icon name or path")]

            onActivated: {
                page.cfg_iconMode = page.iconModes[currentIndex];
            }
        }

        PlasmaComponents.ComboBox {
            id: coinIconCombo
            Kirigami.FormData.label: i18n("Coin")
            Layout.fillWidth: true
            enabled: showIcon.checked && page.cfg_iconMode === "coin"
            model: Presets.coins.names

            onActivated: {
                page.cfg_coinIcon = Presets.coins.files[currentIndex];
            }
        }

        TextField {
            id: iconName
            Kirigami.FormData.label: i18n("Icon name or path")
            Layout.fillWidth: true
            enabled: showIcon.checked && page.cfg_iconMode === "custom"
            placeholderText: "view-refresh"
        }

        CheckBox {
            id: showText
            text: i18n("Show the price")
        }

        CheckBox {
            id: showLabel
            text: i18n("Show the label beside the price")
        }

        CheckBox {
            id: showBackground
            text: i18n("Show the widget background")
        }

        // ------------------------------------------------------------- format

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Formatting")
        }

        CheckBox {
            id: showPricePrefix
            text: i18n("Show a prefix")
        }

        TextField {
            id: pricePrefix
            Layout.preferredWidth: 8 * Kirigami.Units.gridUnit
            enabled: showPricePrefix.checked
            Kirigami.FormData.label: i18n("Prefix")
        }

        CheckBox {
            id: showPriceSuffix
            text: i18n("Show a suffix")
        }

        TextField {
            id: priceSuffix
            Layout.preferredWidth: 8 * Kirigami.Units.gridUnit
            enabled: showPriceSuffix.checked
            Kirigami.FormData.label: i18n("Suffix")
        }

        CheckBox {
            id: controlDecimals
            text: i18n("Round to a fixed number of decimals")
        }

        PlasmaComponents.SpinBox {
            id: decPlaces
            Kirigami.FormData.label: i18n("Decimal places")
            from: 0
            to: 12
            stepSize: 1
            enabled: controlDecimals.checked
        }

        Component.onCompleted: {
            const modeIndex = page.iconModes.indexOf(page.cfg_iconMode);
            iconModeCombo.currentIndex = modeIndex >= 0 ? modeIndex : 1;

            const coinIndex = Presets.coins.files.indexOf(page.cfg_coinIcon);
            coinIconCombo.currentIndex = coinIndex >= 0 ? coinIndex : 0;
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
        }
    }
}
}

