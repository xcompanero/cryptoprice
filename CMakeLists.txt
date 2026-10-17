# SPDX-FileCopyrightText: 2026 Crypto Price contributors
# SPDX-License-Identifier: BSD-2-Clause
#
# Build/install rules for the Crypto Price plasmoid.
#
# The widget itself is pure QML, so nothing needs to be compiled -- the only
# requirement is Extra CMake Modules, which provides plasma_install_package().
#
#   sudo apt install extra-cmake-modules
#   cmake -B build -S . -G Ninja
#   cmake --build build
#   cmake --install build
#
# For day-to-day development you do not need CMake at all:
#
#   kpackagetool6 --type Plasma/Applet --install package
#   plasmoidviewer --applet com.github.xcompanero.cryptoprice

cmake_minimum_required(VERSION 3.16)

project(cryptoprice-plasmoid)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ECM_KDE_MODULE_DIR})

find_package(Plasma REQUIRED)

plasma_install_package(package com.github.xcompanero.cryptoprice)