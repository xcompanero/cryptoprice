/*
 * SPDX-FileCopyrightText: 2026 xcompanero
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * Pure helpers for the Crypto Price plasmoid. No side effects, no Qt types,
 * so this file can be reasoned about (and tested) on its own.
 */
.pragma library

/**
 * Split a JSON path into lookup tokens.
 *
 * Accepts every form users are used to typing, because the exchange APIs
 * that get pasted into the config box use all of them:
 *
 *   last                     -> ["last"]
 *   result.XETHZUSD.a        -> ["result", "XETHZUSD", "a"]
 *   0.price_usd              -> ["0", "price_usd"]
 *   result.XXBTZUSD.c.0      -> ["result", "XXBTZUSD", "c", "0"]
 *   result.XXBTZUSD.c[0]     -> ["result", "XXBTZUSD", "c", "0"]
 *   data[0].price            -> ["data", "0", "price"]
 *   rates.EUR                -> ["rates", "EUR"]
 *
 * Note that array indices are kept as strings: JavaScript arrays answer to
 * both arr["0"] and arr[0], so there is nothing to gain by converting.
 */
function tokenize(path) {
    var tokens = [];
    if (path === undefined || path === null) {
        return tokens;
    }

    var text = String(path);
    var buffer = "";
    var i = 0;

    function flush() {
        if (buffer !== "") {
            tokens.push(buffer);
            buffer = "";
        }
    }

    while (i < text.length) {
        var ch = text.charAt(i);

        if (ch === ".") {
            flush();
            i++;
        } else if (ch === "[") {
            flush();
            i++;
            var index = "";
            while (i < text.length && text.charAt(i) !== "]") {
                index += text.charAt(i);
                i++;
            }
            if (i < text.length) {
                i++; // consume the closing bracket
            }
            index = index.trim();
            if (index !== "") {
                tokens.push(index);
            }
        } else if (ch === "]") {
            i++; // tolerate a stray bracket
        } else {
            buffer += ch;
            i++;
        }
    }
    flush();

    return tokens;
}

/**
 * Walk `data` along `path` and return the value found there.
 *
 * Returns undefined when any step is missing, so callers can tell the user
 * which part of their path is wrong instead of silently printing "undefined".
 */
function resolvePath(data, path) {
    if (data === undefined || data === null || path === undefined || path === null) {
        return undefined;
    }

    var tokens = tokenize(path);
    if (tokens.length === 0) {
        return undefined;
    }

    var current = data;
    for (var i = 0; i < tokens.length; i++) {
        if (current === undefined || current === null) {
            return undefined;
        }
        if (typeof current !== "object") {
            return undefined;
        }
        current = current[tokens[i]];
    }

    return current;
}

/**
 * True when `value` is something we can reasonably print as a price.
 * Booleans and nulls are rejected on purpose -- they come from APIs that
 * answer 200 with an error object, and printing "true" as a price helps
 * nobody.
 */
function isUsableNumber(value) {
    if (value === undefined || value === null || typeof value === "boolean") {
        return false;
    }
    var n = Number(value);
    return isFinite(n);
}

/**
 * Render a price for the panel.
 *
 * With fixed decimals we use toFixed(). Without them we aim to avoid
 * JavaScript's exponent notation ("1.2e-7"), which is never what someone
 * wants to read in a panel -- so fall back to a plain fixed rendering for
 * anything the default String() would mangle.
 */
function formatRate(value, useFixedDecimals, decimalPlaces) {
    if (!isUsableNumber(value)) {
        return "";
    }

    var n = Number(value);

    if (useFixedDecimals) {
        return n.toFixed(Math.max(0, Math.min(20, decimalPlaces)));
    }

    var plain = String(n);
    if (plain.indexOf("e") === -1 && plain.indexOf("E") === -1) {
        return plain;
    }

    for (var places = 2; places <= 20; places++) {
        var candidate = n.toFixed(places);
        if (Number(candidate) === n) {
            return candidate;
        }
    }

    return n.toFixed(8);
}

/**
 * Human-readable "how long ago was this price fetched" text.
 * Returns an empty string for a price that has never arrived.
 */
function formatAge(seconds) {
    if (seconds === undefined || seconds === null || seconds < 0) {
        return "";
    }
    if (seconds < 60) {
        return seconds + "s";
    }
    if (seconds < 3600) {
        return Math.floor(seconds / 60) + "m";
    }
    return Math.floor(seconds / 3600) + "h " + Math.floor((seconds % 3600) / 60) + "m";
}