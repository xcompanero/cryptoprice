/*
 * SPDX-FileCopyrightText: 2026 Crypto Price contributors
 * SPDX-License-Identifier: MIT
 *
 * Curated sources, and the bundled icon list.
 *
 * Every endpoint here was checked by hand in October 2026. Roughly half of
 * the presets in the Plasma 5 version of this widget are dead -- Bittrex
 * v1.1, BTCC, the CoinMarketCap v1 API, the LocalBitcoins average endpoint
 * and Poloniex all fail now, and so does fixer.io, which was the *default*
 * fiat source, so that feature was broken out of the box.
 *
 * Exchange endpoints move around and break without notice. When one does,
 * the Presets page has a "Test connection" button so you find out in the
 * config dialog instead of by staring at the panel.
 */
.pragma library

/** Bundled coin glyphs, drawn as plain symbols so there is no logo licensing to worry about. */
var coins = {
    names: [
        "Bitcoin (BTC)",
        "Ethereum (ETH)",
        "Litecoin (LTC)",
        "Monero (XMR)",
        "Bitcoin Cash (BCH)",
        "Solana (SOL)",
        "Dogecoin (DOGE)",
        "Cardano (ADA)",
        "Generic coin"
    ],
    files: [
        "btc.svg",
        "eth.svg",
        "ltc.svg",
        "xmr.svg",
        "bch.svg",
        "sol.svg",
        "doge.svg",
        "ada.svg",
        "coin.svg"
    ]
};

/** Direct price sources. Load one from the Presets page. */
var sources = [
    {
        title: "Bitstamp BTC-USD",
        url: "https://www.bitstamp.net/api/ticker/",
        path: "last",
        label: "Bitstamp BTC-USD",
        symbol: "$",
        coin: "btc.svg"
    },
    {
        title: "Binance BTC-USDT",
        url: "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT",
        path: "price",
        label: "Binance BTC-USDT",
        symbol: "$",
        coin: "btc.svg"
    },
    {
        title: "Binance ETH-BTC",
        url: "https://api.binance.com/api/v3/ticker/price?symbol=ETHBTC",
        path: "price",
        label: "Binance ETH-BTC",
        symbol: "₿",
        coin: "eth.svg"
    },
    {
        title: "Binance ETH-USDT",
        url: "https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT",
        path: "price",
        label: "Binance ETH-USDT",
        symbol: "$",
        coin: "eth.svg"
    },
    {
        title: "Bitfinex BTC-USD",
        url: "https://api.bitfinex.com/v1/pubticker/BTCUSD",
        path: "last_price",
        label: "Bitfinex BTC-USD",
        symbol: "$",
        coin: "btc.svg"
    },
    {
        title: "bitFlyer BTC-JPY",
        url: "https://api.bitflyer.com/v1/getticker?product_code=BTC_JPY",
        path: "ltp",
        label: "bitFlyer BTC-JPY",
        symbol: "¥",
        coin: "btc.svg"
    },
    {
        title: "Bithumb BTC-KRW",
        url: "https://api.bithumb.com/public/ticker/BTC",
        path: "data.closing_price",
        label: "Bithumb BTC-KRW",
        symbol: "₩",
        coin: "btc.svg"
    },
    {
        title: "Gemini BTC-USD",
        url: "https://api.gemini.com/v1/pubticker/btcusd",
        path: "last",
        label: "Gemini BTC-USD",
        symbol: "$",
        coin: "btc.svg"
    },
    {
        title: "Kraken BTC-USD",
        url: "https://api.kraken.com/0/public/Ticker?pair=XBTUSD",
        path: "result.XXBTZUSD.c[0]",
        label: "Kraken BTC-USD",
        symbol: "$",
        coin: "btc.svg"
    },
    {
        title: "Coinbase BTC-USD",
        url: "https://api.coinbase.com/v2/prices/BTC-USD/spot",
        path: "data.amount",
        label: "Coinbase BTC-USD",
        symbol: "$",
        coin: "btc.svg"
    },
    {
        title: "CoinGecko BTC-USD",
        url: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd",
        path: "bitcoin.usd",
        label: "CoinGecko BTC-USD",
        symbol: "$",
        coin: "btc.svg"
    }
];

/**
 * Conversion factors, for the "multiply by a second/third source" stages.
 *
 * fixer.io, which the Plasma 5 widget shipped as its default, now answers
 * 404 without a paid key. Both of these are free, keyless and verified
 * working.
 */
var factors = [
    {
        title: "Fiat: open.er-api.com → EUR",
        url: "https://open.er-api.com/v6/latest/USD",
        path: "rates.EUR"
    },
    {
        title: "Fiat: open.er-api.com → GBP",
        url: "https://open.er-api.com/v6/latest/USD",
        path: "rates.GBP"
    },
    {
        title: "Fiat: Frankfurter (ECB) → EUR",
        url: "https://api.frankfurter.app/latest?from=USD",
        path: "rates.EUR"
    },
    {
        title: "Base to fiat: Kraken BTC-USD",
        url: "https://api.kraken.com/0/public/Ticker?pair=XBTUSD",
        path: "result.XXBTZUSD.c[0]"
    },
    {
        title: "Base to fiat: Coinbase BTC-USD",
        url: "https://api.coinbase.com/v2/prices/BTC-USD/spot",
        path: "data.amount"
    }
];