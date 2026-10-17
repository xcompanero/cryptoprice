/*
 * SPDX-FileCopyrightText: 2026 Crypto Price contributors
 * SPDX-License-Identifier: MIT
 *
 * Plasma 6 port of the Crypto Currency Price plasmoid.
 *
 * The one structural difference worth calling out: the price is computed in
 * recompute() as a real number and stored in lastGoodRate. The Plasma 5
 * original did its arithmetic inside a text binding, on a string property,
 * so every re-evaluation re-multiplied an already-rounded value. Here the
 * text binding only ever reads a finished number.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "priceutils.js" as PriceUtils

PlasmoidItem {
    id: root

    property var cfg: plasmoid.configuration

    Layout.fillHeight: true


    // No implicitWidth/implicitHeight binding here on purpose. The Plasma 5
    // original did not set one, and the shell manages this applet's implicit
    // size itself -- a QML binding on it fights the shell for the same
    // property.

    // ---------------------------------------------------------------- data

    // The last *fully* computed rate. A conversion factor that has not
    // arrived yet must not wipe out a price we were happily showing, so the
    // composite only advances when every enabled stage has a value.
    property real lastGoodRate: 0
    property bool hasRate: false
    property double lastGoodMs: 0
    property double nowMs: Date.now()
    property string lastError: ""

    RateFetcher {
        id: fetcherA
        url: root.cfg.sourceUrl
        jsonPath: root.cfg.sourcePath
        userAgent: root.cfg.customUserAgent
        timeoutSeconds: root.cfg.timeoutSeconds
    }

    RateFetcher {
        id: fetcherB
        enabled: root.cfg.multiExternalB
        url: root.cfg.xeUrlB
        jsonPath: root.cfg.xeKeyB
        userAgent: root.cfg.customUserAgent
        timeoutSeconds: root.cfg.timeoutSeconds
    }

    RateFetcher {
        id: fetcherC
        enabled: root.cfg.multiExternalC
        url: root.cfg.xeUrlC
        jsonPath: root.cfg.xeKeyC
        userAgent: root.cfg.customUserAgent
        timeoutSeconds: root.cfg.timeoutSeconds
    }

    // ------------------------------------------------------------- derived

    // The price as it appears in the panel, prefix and suffix included --
    // the Plasma 5 widget showed these in the panel too, not just the tooltip.
    readonly property string displayText: {
        if (!hasRate) {
            return "";
        }
        let price = PriceUtils.formatRate(lastGoodRate, cfg.controlDecimals, cfg.decPlaces);
        if (cfg.showPricePrefix) {
            price = cfg.pricePrefix + price;
        }
        if (cfg.showPriceSuffix) {
            price = price + cfg.priceSuffix;
        }
        return price;
    }

    readonly property string labelText: (cfg.tooltipLabel || "").trim()

    /**
     * A string shaped like the price but with fixed digits, used by TickerRow
     * to reserve a stable width. Built from the configured decimals and
     * affixes so it matches whatever the user will actually see.
     */
    readonly property string referencePriceText: {
        const dp = cfg.controlDecimals ? Math.max(0, cfg.decPlaces) : 2;
        // Five integer digits covers any real crypto price.
        let s = "8".repeat(5) + (dp > 0 ? "." + "8".repeat(dp) : "");
        if (cfg.showPricePrefix) {
            s = cfg.pricePrefix + s;
        }
        if (cfg.showPriceSuffix) {
            s = s + cfg.priceSuffix;
        }
        return s;
    }

    readonly property int ageSeconds: lastGoodMs > 0
        ? Math.floor((nowMs - lastGoodMs) / 1000)
        : -1

    // Stale a little past the refresh interval, so the value only dims once
    // a refresh has genuinely been missed rather than mid-cycle.
    readonly property bool stale: hasRate
        && ageSeconds >= Math.max(600, cfg.refreshRate * 90)

    // ------------------------------------------------------------- actions

    function refreshAll() {
        fetcherA.fetch();
        if (cfg.multiExternalB) {
            fetcherB.fetch();
        }
        if (cfg.multiExternalC) {
            fetcherC.fetch();
        }
        updateTooltip();
    }

    function recompute() {
        var complete = true;
        var result = 0;

        if (!fetcherA.hasValue) {
            complete = false;
        } else {
            result = fetcherA.value;

            if (cfg.multiExternalB) {
                if (fetcherB.hasValue) {
                    result *= fetcherB.value;
                } else {
                    complete = false;
                }
            }
            if (cfg.multiExternalC) {
                if (fetcherC.hasValue) {
                    result *= fetcherC.value;
                } else {
                    complete = false;
                }
            }
            if (cfg.multiFixed) {
                result *= Number(cfg.multiFixedInput);
            }
        }

        if (complete) {
            lastGoodRate = result;
            hasRate = true;
            lastGoodMs = Date.now();
            lastError = "";
        }

        updateTooltip();
    }

    function describeFailure(reason, detail) {
        switch (reason) {
        case "timeout":
            return i18n("Timed out after %1 seconds", cfg.timeoutSeconds);
        case "network":
            return i18n("Could not reach the server");
        case "http":
            return i18n("Server replied with HTTP %1", detail);
        case "parse":
            return i18n("The server did not return valid JSON");
        case "path":
            return i18n("No number found at JSON path ‘%1’", detail);
        case "config":
            return i18n("The source is not fully configured");
        default:
            return i18n("Unknown error");
        }
    }

    function onFetchFailed(fetcher, reason, detail) {
        // A stage we deliberately switched off is not a failure to report.
        if (!fetcher.enabled) {
            return;
        }
        lastError = describeFailure(reason, detail);
        updateTooltip();
    }

    // Source settings changed: drop the price built from the old settings and
    // fetch again immediately. Timer.restart() fires straight away.
    function reconfigure() {
        hasRate = false;
        lastError = "";
        refreshTimer.restart();
    }

    // Built in a function rather than a binding -- the Plasma 5 version
    // assigned to toolTipSubText from inside a text binding, which meant it
    // could run at surprising times and more than once per change.
    function updateTooltip() {
        var heading = labelText !== "" ? labelText : i18n("Price");
        Plasmoid.toolTipMainText = heading;

        var price = displayText !== "" ? displayText : i18n("no data");

        var lines = ["<b>" + price + "</b>"];

        if (cfg.multiFixed) {
            lines.push(i18n("Holding: %1", Number(cfg.multiFixedInput)));
        }
        if (lastError !== "") {
            lines.push("<i>" + lastError + "</i>");
        }
        if (cfg.showAge && ageSeconds >= 0) {
            lines.push(i18n("Updated %1 ago", PriceUtils.formatAge(ageSeconds)));
        }

        Plasmoid.toolTipSubText = lines.join("<br />");
    }

    // --------------------------------------------------------------- timers

    Timer {
        id: refreshTimer
        // Clamped: the Plasma 5 version multiplied the configured value into a
        // timer interval unchecked, so 0 would have been a hot loop.
        interval: Math.max(1, Math.min(1440, root.cfg.refreshRate)) * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    Timer {
        id: uiTick
        interval: 20000
        repeat: true
        running: true
        onTriggered: {
            root.nowMs = Date.now();
            root.updateTooltip();
        }
    }

    // ------------------------------------------------------------- wiring

    Component.onCompleted: {
        // Assigned here rather than as a binding: preferredRepresentation is
        // QQmlComponent*, but a binding on it is evaluated before
        // compactRepresentation has been created, so it reads undefined and
        // logs "Unable to assign [undefined]".
        if (Plasmoid.compactRepresentation) {
            Plasmoid.preferredRepresentation = Plasmoid.compactRepresentation;
        }
        Plasmoid.toolTipTextFormat = Text.RichText;
        updateTooltip();
    }

    Connections {
        target: fetcherA
        function onUpdated() { root.recompute(); }
        function onFailed(reason, detail) { root.onFetchFailed(fetcherA, reason, detail); }
    }

    Connections {
        target: fetcherB
        function onUpdated() { root.recompute(); }
        function onFailed(reason, detail) { root.onFetchFailed(fetcherB, reason, detail); }
    }

    Connections {
        target: fetcherC
        function onUpdated() { root.recompute(); }
        function onFailed(reason, detail) { root.onFetchFailed(fetcherC, reason, detail); }
    }

    Connections {
        target: plasmoid.configuration

        function onSourceUrlChanged() { root.reconfigure(); }
        function onSourcePathChanged() { root.reconfigure(); }
        function onMultiExternalBChanged() { root.reconfigure(); }
        function onXeUrlBChanged() { root.reconfigure(); }
        function onXeKeyBChanged() { root.reconfigure(); }
        function onMultiExternalCChanged() { root.reconfigure(); }
        function onXeUrlCChanged() { root.reconfigure(); }
        function onXeKeyCChanged() { root.reconfigure(); }

        function onMultiFixedChanged() { root.recompute(); }
        function onMultiFixedInputChanged() { root.recompute(); }
        function onRefreshRateChanged() { refreshTimer.restart(); }
        function onShowAgeChanged() { root.updateTooltip(); }
        function onControlDecimalsChanged() { root.updateTooltip(); }
        function onDecPlacesChanged() { root.updateTooltip(); }
        function onTooltipLabelChanged() { root.updateTooltip(); }
        function onShowPricePrefixChanged() { root.updateTooltip(); }
        function onPricePrefixChanged() { root.updateTooltip(); }
        function onShowPriceSuffixChanged() { root.updateTooltip(); }
        function onPriceSuffixChanged() { root.updateTooltip(); }
    }

    // ------------------------------------------------------ representation

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh now")
            icon.name: "view-refresh"
            onTriggered: root.refreshAll()
        },
        PlasmaCore.Action {
            text: i18n("Open source in browser")
            icon.name: "applications-internet"
            enabled: root.cfg.sourceUrl !== ""
            onTriggered: Qt.openUrlExternally(root.cfg.sourceUrl)
        }
    ]

    Plasmoid.backgroundHints: cfg.showBackground
        ? PlasmaCore.Types.DefaultBackground
        : PlasmaCore.Types.NoBackground

    // preferredRepresentation is deliberately not set: Plasmoid.CompactRepresentation
    // and Plasmoid.FullRepresentation are undefined on Plasma 6.6, and assigning
    // one logs "Unable to assign [undefined]". Plasma picks a working default.

    compactRepresentation: Component {
        TickerRow {
            iconMode: root.cfg.iconMode
            coinIcon: root.cfg.coinIcon
            iconName: root.cfg.iconName
            showIcon: root.cfg.showIcon
            showText: root.cfg.showText
            showLabel: false
            adaptToHeight: false
            fontSizeOverride: root.cfg.fontSizePx
            priceText: root.displayText
            referenceText: root.referencePriceText
            busy: fetcherA.busy
            stale: root.stale
            failed: !root.hasRate
        }
    }

    fullRepresentation: Component {
        TickerRow {
            iconMode: root.cfg.iconMode
            coinIcon: root.cfg.coinIcon
            iconName: root.cfg.iconName
            showIcon: root.cfg.showIcon
            showText: root.cfg.showText
            showLabel: root.cfg.showLabel
            adaptToHeight: root.cfg.fontSizePx === 0
            fontSizeOverride: root.cfg.fontSizePx
            priceText: root.displayText
            referenceText: root.referencePriceText
            labelText: root.labelText
            busy: fetcherA.busy
            stale: root.stale
            failed: !root.hasRate
        }
    }
}