/*
 * SPDX-FileCopyrightText: 2026 Crypto Price contributors
 * SPDX-License-Identifier: MIT
 *
 * The panel/desktop presentation: an optional icon, an optional label and the
 * price itself. Shared by the compact and full representations so the two can
 * never drift apart.
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root

    /** "none", "coin" (bundled svg) or "custom" (theme name / path). */
    property string iconMode: "none"
    property string coinIcon: "btc.svg"
    property string iconName: ""

    property bool showIcon: true
    property bool showText: true
    property bool showLabel: false

    property string priceText: ""
    property string labelText: ""

    /** True while a request is in flight -- used to dim the previous price. */
    property bool busy: false
    /** True when we are showing a price that is older than the refresh rate. */
    property bool stale: false
    /** True when we have never managed to fetch anything. */
    property bool failed: false

    /**
     * Square icon size. Anchoring the RowLayout to fill gives each child the
     * full applet height, so the icon needs its own bound: without one it is
     * stretched to 22x500 and PreserveAspectFit renders a 22px dot.
     */
    readonly property int iconSize: Math.round(
        Math.max(Kirigami.Units.iconSizes.small,
                 Math.min(height * 0.7, Kirigami.Units.iconSizes.huge)))

    /**
     * Font sizes derived from the applet's own height.
     *
     * The obvious-looking choice here is fontSizeMode: Text.Fit with a large
     * base font, and it is wrong for a panel applet: Text reports
     * implicitWidth measured at the *base* font size, and only then shrinks
     * to fit. So the applet asks the panel for ~270px to render ~107px of
     * text, ends up far wider than its content, and visibly overlaps the
     * applets either side of it. Scaling the font directly keeps implicitWidth
     * honest at every panel height.
     */
    readonly property int priceFontSize: Math.max(
        8, Math.min(Kirigami.Units.largeSpacing * 7, Math.round(height * 0.75)))
    readonly property int labelFontSize: Math.max(
        7, Math.min(Kirigami.Units.largeSpacing * 5, Math.round(height * 0.5)))

    readonly property real effectiveOpacity: failed ? 0.45 : (busy || stale ? 0.6 : 1.0)

    /**
     * A custom icon is a path to an image, not a theme icon name.
     *
     * Plasma 5 had KQuickAddons.IconDialog for picking a themed icon. That
     * type no longer exists in Qt 6, and PlasmaCore.IconItem is missing from
     * some Plasma 6 builds too (including Ubuntu 26.04, where
     * org.kde.plasma.quick is not installed) -- referencing it makes the whole
     * widget fail to load. Plain Image has no such dependency, and matches
     * how the original widget's own README suggested using it: point it at a
     * downloaded coin image.
     */
    function customIconSource() {
        const name = (iconName || "").trim();
        if (name === "") {
            return "";
        }
        if (name.charAt(0) === "/") {
            return "file://" + name;
        }
        return name;
    }

    // Hard guarantee: whatever size the shell hands us, nothing is ever
    // painted outside it. Without this the applet draws straight over its
    // neighbours, because a panel does not clip between applets.
    clip: true

    /**
     * A stand-in string with the shape of the real price, used to reserve
     * width.
     *
     * The panel takes the applet's size hint once, early -- when the price is
     * still empty and has no width. The applet then keeps that small hint for
     * its whole life and the text spills out over whatever is next to it.
     * Reserving a fixed width from a reference string means the right amount
     * of space is claimed from the very first frame, and the widget also stops
     * jittering every time the price changes length.
     */
    property string referenceText: ""

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    // Off-screen, but implicitWidth still measures it.
    Text {
        id: referencePrice
        visible: false
        font.pixelSize: root.priceFontSize
        text: root.referenceText
    }

    Text {
        id: referenceLabel
        visible: false
        font.pixelSize: root.labelFontSize
        text: root.labelText
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing
        // Plasma 6 lays panel applets out edge to edge with no gap between
        // them, so the separation from neighbouring applets has to come from
        // here. Without it this widget looks like it is sitting on top of
        // whatever sits next to it.
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing

        PlasmaComponents.BusyIndicator {
            Layout.fillHeight: true
            Layout.maximumWidth: Kirigami.Units.iconSizes.small
            Layout.maximumHeight: Kirigami.Units.iconSizes.small
            visible: root.busy
            running: root.busy
        }

        Image {
            id: coinImage
            Layout.fillHeight: true
            Layout.preferredWidth: root.iconSize
            Layout.maximumWidth: root.iconSize
            Layout.minimumWidth: root.iconSize
            Layout.maximumHeight: root.iconSize
            visible: root.showIcon && root.iconMode === "coin"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            source: root.coinIcon !== ""
                ? Qt.resolvedUrl("../images/coins/" + root.coinIcon)
                : ""
        }

        Image {
            id: customIcon
            Layout.fillHeight: true
            Layout.preferredWidth: root.iconSize
            Layout.maximumWidth: root.iconSize
            Layout.minimumWidth: root.iconSize
            Layout.maximumHeight: root.iconSize
            visible: root.showIcon && root.iconMode === "custom"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            source: root.customIconSource()
        }

        Text {
            id: labelText
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: root.labelText !== "" ? referenceLabel.implicitWidth : 0
            Layout.alignment: Qt.AlignVCenter
            visible: root.showLabel && root.labelText !== ""
            text: root.labelText
            color: Kirigami.Theme.textColor
            opacity: 0.6
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: root.labelFontSize
        }

        Text {
            id: priceText
            Layout.fillHeight: true
            Layout.fillWidth: true
            // Reserve room for a typical price, but still grow if a real one
            // is longer (a sudden 6-figure move should not get clipped).
            Layout.minimumWidth: referencePrice.implicitWidth
            visible: root.showText
            text: root.priceText
            color: Kirigami.Theme.textColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: root.priceFontSize
            opacity: root.effectiveOpacity
        }
    }
}