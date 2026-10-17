/*
 * SPDX-FileCopyrightText: 2026 xcompanero
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-system-network"
        source: "config/General.qml"
    }

    ConfigCategory {
        name: i18n("Conversion")
        icon: "accessories-calculator"
        source: "config/Conversion.qml"
    }
}