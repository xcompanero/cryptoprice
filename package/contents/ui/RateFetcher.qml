/*
 * SPDX-FileCopyrightText: 2026 xcompanero
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * One HTTP fetch of one JSON value, with honest failure handling.
 *
 * This deliberately replaces what the Plasma 5 widget did, which had three
 * problems worth not repeating:
 *
 *  1. It set xhr.timeout, which QML's XMLHttpRequest silently ignores -- the
 *     request was never actually timed out. We use a watchdog Timer and
 *     abort() instead.
 *  2. It only cleared its "busy" flag on HTTP 200, so any error left a
 *     spinner running over the price forever. Here every path clears busy.
 *  3. It reported success and failure identically (both were just "the
 *     callback did not fire"), so nothing could tell the user what broke.
 *     We emit a machine-readable reason plus a detail string.
 */
import QtQuick
import "priceutils.js" as PriceUtils

QtObject {
    id: fetcher

    /** Endpoint to fetch. Ignored while enabled is false. */
    property string url: ""
    /** Dot/bracket path to the value inside the JSON response. */
    property string jsonPath: ""
    /** Some APIs reject the default QML user agent; set this to override. */
    property string userAgent: ""
    /** Wall-clock budget for the request before we abort it. */
    property int timeoutSeconds: 15
    /** Disabled fetchers report "config" instead of hitting the network. */
    property bool enabled: true

    property bool busy: false
    /** Stays true once a price has ever arrived, even if we then go stale. */
    property bool hasValue: false
    property real value: 0
    property int consecutiveFailures: 0
    /** Date.now() of the last successful fetch, or 0. */
    property double lastSuccessMs: 0
    /** Reason from the most recent failure, or "" while healthy. */
    property string errorReason: ""

    signal updated(real newValue)
    /** reason is one of: config, network, timeout, http, parse, path */
    signal failed(string reason, string detail)

    property var _xhr: null
    property bool _settled: false

    // A QtObject has no default property, so the Timer cannot just be
    // declared as a bare child -- it has to be assigned to something.
    property Timer watchdog: Timer {
        interval: Math.max(1, fetcher.timeoutSeconds) * 1000
        repeat: false
        onTriggered: {
            if (fetcher._settled) {
                return;
            }
            fetcher._settled = true;
            console.warn("[cryptoprice] timeout after", interval + "ms:", fetcher.url);
            try {
                if (fetcher._xhr) {
                    fetcher._xhr.abort();
                }
            } catch (e) {
                // abort() on an already-finished request is harmless
            }
            fetcher._xhr = null;
            fetcher._fail("timeout", "");
        }
    }

    /**
     * Kick off a fetch. No-ops while one is already in flight, so a timer
     * tick landing on top of a manual click cannot stack up requests.
     */
    function fetch() {
        if (busy) {
            return;
        }
        if (!enabled) {
            return;
        }
        if (url === "" || jsonPath === "") {
            // An unconfigured source is not an error worth counting, but the
            // UI does need to know there is nothing to show.
            _fail("config", url === "" ? "url" : "path");
            return;
        }

        _settled = false;
        busy = true;

        var xhr = new XMLHttpRequest();
        _xhr = xhr;

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) {
                return;
            }
            if (fetcher._settled) {
                return; // the watchdog already dealt with this one
            }
            fetcher._settled = true;
            watchdog.stop();
            fetcher._xhr = null;
            fetcher.busy = false;

            // status 0 means the request never reached a server: DNS, TLS or
            // a dead host. Anything else is a real HTTP response.
            if (xhr.status === 0) {
                fetcher._fail("network", "");
                return;
            }
            if (xhr.status !== 200) {
                fetcher._fail("http", xhr.status);
                return;
            }

            var data;
            try {
                data = JSON.parse(xhr.responseText.toString());
            } catch (e) {
                fetcher._fail("parse", (e && e.message) ? e.message : String(e));
                return;
            }

            var resolved = PriceUtils.resolvePath(data, fetcher.jsonPath);
            if (!PriceUtils.isUsableNumber(resolved)) {
                // Almost always a typo in the path, or an API answering 200
                // with an error envelope ({"error": "invalid key"}).
                fetcher._fail("path", fetcher.jsonPath);
                return;
            }

            fetcher.value = Number(resolved);
            fetcher.hasValue = true;
            fetcher.consecutiveFailures = 0;
            fetcher.errorReason = "";
            fetcher.lastSuccessMs = Date.now();
            fetcher.updated(fetcher.value);
        };

        try {
            xhr.open("GET", url, true);
            if (userAgent !== "") {
                xhr.setRequestHeader("User-Agent", userAgent);
            }
            watchdog.restart();
            xhr.send(null);
        } catch (e) {
            watchdog.stop();
            _settled = true;
            busy = false;
            _xhr = null;
            _fail("config", (e && e.message) ? e.message : String(e));
        }
    }

    function _fail(reason, detail) {
        busy = false;
        errorReason = reason;
        consecutiveFailures++;
        failed(reason, detail);
    }

    /** Forget any previously fetched price (used when settings change). */
    function reset() {
        hasValue = false;
        value = 0;
        lastSuccessMs = 0;
        errorReason = "";
        consecutiveFailures = 0;
        busy = false;
    }
}