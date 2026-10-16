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

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.BusyIndicator {
            Layout.fillHeight: true
            Layout.maximumWidth: Kirigami.Units.iconSizes.small
            visible: root.busy
            running: root.busy
        }

        Image {
            id: coinImage
            Layout.fillHeight: true
            Layout.preferredWidth: root.iconSize
            Layout.maximumWidth: root.iconSize
            Layout.minimumWidth: root.iconSize
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
            visible: root.showIcon && root.iconMode === "custom"
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            source: root.customIconSource()
        }

        Text {
            id: labelText
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            visible: root.showLabel && root.labelText !== ""
            text: root.labelText
            color: Kirigami.Theme.textColor
            opacity: 0.6
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            // Grown then shrunk to fit, which is how applet text normally
            // scales with the panel height without hardcoded pixel sizes.
            font.pixelSize: Kirigami.Units.largeSpacing * 6
            fontSizeMode: Text.Fit
            minimumPixelSize: 6
        }

        Text {
            id: priceText
            Layout.fillHeight: true
            visible: root.showText
            text: root.priceText
            color: Kirigami.Theme.textColor
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Kirigami.Units.largeSpacing * 7
            fontSizeMode: Text.Fit
            minimumPixelSize: 6
            opacity: root.effectiveOpacity
        }
    }
}