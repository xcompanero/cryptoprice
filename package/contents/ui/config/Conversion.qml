/*
 * SPDX-FileCopyrightText: 2026 Crypto Price contributors
 * SPDX-License-Identifier: MIT
 *
 * The three-stage price pipeline, which is the part of the Plasma 5 widget
 * that made it more than a one-number ticker: fetch a base price, optionally
 * multiply by a conversion factor, optionally multiply by a second one, and
 * optionally multiply by how much of the coin you actually hold.
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

    readonly property var factorTitles: {
        const titles = [i18n("Custom")];
        for (let i = 0; i < Presets.factors.length; i++) {
            titles.push(Presets.factors[i].title);
        }
        return titles;
    }

    property alias cfg_multiFixed: multiFixed.checked
    property double cfg_multiFixedInput: 1.0
    property alias cfg_multiExternalB: multiExternalB.checked
    property alias cfg_xeUrlB: xeUrlB.text
    property alias cfg_xeKeyB: xeKeyB.text
    property alias cfg_multiExternalC: multiExternalC.checked
    property alias cfg_xeUrlC: xeUrlC.text
    property alias cfg_xeKeyC: xeKeyC.text

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

        // ------------------------------------------------------------- holding

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Holding")
        }

        CheckBox {
            id: multiFixed
            text: i18n("Multiply the price by an amount you hold")
        }

        // A TextField rather than a SpinBox: Qt Quick Controls 2 SpinBox has no
        // "decimals" property (that was a Controls 1 thing), and a holding is
        // almost always a fraction like 0.42 rather than a whole number.
        TextField {
            id: multiFixedInput
            Kirigami.FormData.label: i18n("Amount")
            Layout.fillWidth: true
            enabled: multiFixed.checked
            text: String(page.cfg_multiFixedInput)
            validator: DoubleValidator {
                bottom: 0
                top: 2000000000
                notation: DoubleValidator.StandardNotation
            }
            onEditingFinished: {
                const parsed = parseFloat(text);
                if (!isNaN(parsed)) {
                    page.cfg_multiFixedInput = parsed;
                } else {
                    text = String(page.cfg_multiFixedInput);
                }
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            visible: multiFixed.checked
            text: i18n("With 0.42 selected, a BTC price of $80,000 is shown as $33,600.")
        }

        // ----------------------------------------------------- stage two

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Second stage")
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("Multiplies the first price by a value fetched elsewhere, for example turning a BTC price into a USD price.")
        }

        CheckBox {
            id: multiExternalB
            text: i18n("Multiply by a second source")
        }

        PlasmaComponents.ComboBox {
            id: factorBCombo
            Kirigami.FormData.label: i18n("Known factor")
            Layout.fillWidth: true
            enabled: multiExternalB.checked
            model: page.factorTitles
            onActivated: {
                if (currentIndex > 0) {
                    xeUrlB.text = Presets.factors[currentIndex - 1].url;
                    xeKeyB.text = Presets.factors[currentIndex - 1].path;
                }
            }
        }

        TextField {
            id: xeUrlB
            Kirigami.FormData.label: i18n("URL")
            Layout.fillWidth: true
            enabled: multiExternalB.checked
        }

        TextField {
            id: xeKeyB
            Kirigami.FormData.label: i18n("JSON path")
            Layout.fillWidth: true
            enabled: multiExternalB.checked
            placeholderText: "rates.EUR"
        }

        SourceTester {
            Layout.fillWidth: true
            visible: multiExternalB.checked
            url: xeUrlB.text
            jsonPath: xeKeyB.text
        }

        // ----------------------------------------------------- stage three

        PlasmaComponents.Label {
            Layout.fillWidth: true
            font.bold: true
            font.pointSize: Kirigami.Units.largeSpacing
            text: i18n("Third stage")
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.7
            text: i18n("One more multiplication, for example converting a USD price into EUR.")
        }

        CheckBox {
            id: multiExternalC
            text: i18n("Multiply by a third source")
        }

        PlasmaComponents.ComboBox {
            id: factorCCombo
            Kirigami.FormData.label: i18n("Known factor")
            Layout.fillWidth: true
            enabled: multiExternalC.checked
            model: page.factorTitles
            onActivated: {
                if (currentIndex > 0) {
                    xeUrlC.text = Presets.factors[currentIndex - 1].url;
                    xeKeyC.text = Presets.factors[currentIndex - 1].path;
                }
            }
        }

        TextField {
            id: xeUrlC
            Kirigami.FormData.label: i18n("URL")
            Layout.fillWidth: true
            enabled: multiExternalC.checked
        }

        TextField {
            id: xeKeyC
            Kirigami.FormData.label: i18n("JSON path")
            Layout.fillWidth: true
            enabled: multiExternalC.checked
            placeholderText: "rates.EUR"
        }

        SourceTester {
            Layout.fillWidth: true
            visible: multiExternalC.checked
            url: xeUrlC.text
            jsonPath: xeKeyC.text
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.smallSpacing * 2
        }
    }
}
}

