# Changelog

## Unreleased

- **Fixed: applet painted over its neighbours in the panel.** The panel takes
  the applet's size hint once, early -- when the price is still empty and has
  no width -- and keeps it. The applet then reserved only its icon, and the
  text drew outside it across whatever came next. The price and label now
  reserve width from a reference string of the right shape, built from the
  configured decimals and affixes, so the correct amount is claimed from the
  first frame and the widget no longer jitters as prices change length. The
  applet's own implicit size also mirrors the live representation, and the
  representation is clipped, so it cannot paint outside its slot even if the
  shell hands it less space than asked for.
- **Fixed: parameterised strings were not being substituted.** Plasma's
  `i18n()` takes the arguments directly; `i18n("...").arg()` does not feed
  them back, and the journal was full of "0 instead of 1 arguments to message
  ... supplied before conversion".

- **Fixed: the widget painted over its neighbours in the panel.** Using
  `fontSizeMode: Text.Fit` with a large base font made the text report an
  implicitWidth of 271px while rendering 107px, so the applet claimed far
  more width than it drew; the text then overflowed its slot and, with
  nothing to elide against, drew straight over whatever applet was next to it.
  The font is now derived from the applet's own height, so implicitWidth
  matches what is rendered (137px instead of 297px at a 30px panel height), and
  the text fills its slot and elides rather than overflowing.
- Icon height is bounded, so a large custom image (a photo, say) can no longer
  inflate the applet's implicit height.
- Both config pages are scrollable. The General page is 1579px of content in a
  ~460px dialog, so everything below the fold was unreachable.
- Panel applets sit edge to edge in Plasma 6, so the widget now carries its own
  left/right margin.

## 1.0.0

First Plasma 6 release. Ported from
[spmdrd/plasma-applet-cryptocurrency-price](https://github.com/spmdrd/plasma-applet-cryptocurrency-price)
1.4 (MIT), which was Plasma 5 / Qt 5 only.

Feature parity with 1.4:

- arbitrary source URL and JSON path
- three-stage price multiplication (base × factor × factor × holding)
- fixed-amount multiplier
- decimal place control
- price prefix and suffix, shown in the panel as well as the tooltip
- tooltip label
- icon / text / background toggles
- refresh interval and click-to-refresh
- curated source presets

Fixes over 1.4:

- **Request timeout now works.** `xhr.timeout` is not a member of QML's
  `XMLHttpRequest` and was silently ignored. Replaced with a watchdog `Timer`
  and `abort()`.
- **No more permanent spinner.** The busy flag was only cleared on HTTP 200,
  so any error left the indicator spinning over the price forever. Every exit
  path now clears it.
- **Failures are named.** Timeout, DNS/TLS failure, HTTP status, malformed
  JSON and a path that finds nothing are distinguished, and reported in the
  tooltip.
- **The last good price survives a failure** instead of disappearing.
- **Arithmetic is numeric.** The price was a string property multiplied inside
  a text binding, so re-evaluation re-multiplied an already-rounded value.
- **JSON paths handle arrays.** `a[0].b`, `a.0.b` and `a.b` are equivalent; the
  old tokenizer mangled `data[0].price` into `data0`.
- **No exponent notation** when decimals are left on automatic.
- **Refresh interval is clamped**, so `0` cannot become a hot loop.
- **Default refresh is 30 minutes**, not 10, to stay well inside exchange API
  rate limits.
- **Dead presets removed.** Bittrex v1.1, BTCC, CoinMarketCap v1, the
  LocalBitcoins average endpoint and Poloniex no longer answer. fixer.io —
  the previous default fiat source — returns 404, so conversion did not work
  out of the box; it now defaults to open.er-api.com.
- **Every preset has a "Test connection" button**, so a rotted endpoint is
  diagnosed in the config dialog.

Plasma 6 API migration:

- `compactRepresentation` / `fullRepresentation` are `Component`s
- `plasmoid.setAction()` → `Plasmoid.contextualActions`
- QtQuick.Controls 1.4 and QtQuick.Dialogs 1.2 → Controls 2 / Dialogs
- config UI → `org.kde.plasma.configuration` with `ConfigModel`
- `metadata.desktop` → `metadata.json` with `X-Plasma-API-Minimum-Version`
- `PlasmaCore.IconItem` and `PlasmaComponents.Heading` are unavailable on
  Plasma 6.6; avoided
- `KQuickAddons.IconDialog` no longer exists in Qt 6; replaced with a bundled
  glyph picker

Added:

- nine bundled coin glyphs, drawn as original geometric marks rather than
  project logos
- custom icon by image path
- configurable request timeout
- price age in the tooltip, and a dimmed state once a refresh has been missed
- *Open source in browser* and *Refresh now* contextual actions