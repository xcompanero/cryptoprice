/*
 * SPDX-FileCopyrightText: 2026 Crypto Price contributors
 * SPDX-License-Identifier: MIT
 *
 * A "Test connection" button for one source. Used by both the General and
 * Conversion pages so a dead preset shows up in the config dialog rather
 * than as a widget that silently never updates.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import ".."
import org.kde.kirigami as Kirigami

RowLayout {
    id: tester

    property string url: ""
    property string jsonPath: ""

    property bool testing: false
    property bool lastResultOk: false
    property string status: ""

    function test() {
        if (tester.url === "" || tester.jsonPath === "") {
            tester.lastResultOk = false;
            tester.status = i18n("Fill in the URL and JSON path first.");
            return;
        }
        tester.testing = true;
        tester.status = "";
        fetcher.fetch();
    }

    function clearStatus() {
        tester.status = "";
    }

    RateFetcher {
        id: fetcher
        url: tester.url
        jsonPath: tester.jsonPath
        timeoutSeconds: 20

        onUpdated: function (newValue) {
            tester.testing = false;
            tester.lastResultOk = true;
            tester.status = i18n("OK — found %1").arg(newValue);
        }

        onFailed: function (reason, detail) {
            tester.testing = false;
            tester.lastResultOk = false;
            switch (reason) {
            case "timeout":
                tester.status = i18n("Timed out.");
                break;
            case "network":
                tester.status = i18n("Could not reach the server.");
                break;
            case "http":
                tester.status = i18n("Server replied with HTTP %1.").arg(detail);
                break;
            case "parse":
                tester.status = i18n("The server did not return valid JSON.");
                break;
            case "path":
                tester.status = i18n("No number at “%1”.").arg(detail);
                break;
            default:
                tester.status = i18n("The source is not fully configured.");
                break;
            }
        }
    }

    PlasmaComponents.Button {
        id: testButton
        text: tester.testing ? i18n("Testing…") : i18n("Test connection")
        enabled: !tester.testing
        onClicked: tester.test()
    }

    Label {
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        visible: tester.status !== ""
        text: tester.status
        // Fall back to literal colours: not every Kirigami build exposes these.
        color: tester.lastResultOk
            ? (Kirigami.Theme.positiveTextColor || "#26a269")
            : (Kirigami.Theme.negativeTextColor || "#da4453")
    }
}