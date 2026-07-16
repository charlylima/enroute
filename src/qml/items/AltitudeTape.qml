/***************************************************************************
 *   Copyright (C) 2026 by EnrouteCL contributors                         *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 ***************************************************************************/

import QtQuick

Item {
    id: root

    property bool altitudeValid: false
    property int altitudeFeet: 0
    property int tickStep: 100
    property int majorStep: 500
    property int valueRange: 1200
    readonly property real tapeCenterY: Math.round(height / 2)
    readonly property int altitudeStepRemainder: altitudeValid ? ((altitudeFeet % tickStep) + tickStep) % tickStep : 0
    readonly property int altitudeStepBase: altitudeValid ? (altitudeFeet - altitudeStepRemainder) : 0
    readonly property real pixelsPerUnit: root.height / Math.max(1, valueRange)

    clip: true

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.0, 0.0, 0.0, 0.24)
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.52)
        radius: 2
    }

    Repeater {
        model: 19
        delegate: Item {
            required property int index

            readonly property int offset: 9 - index
            readonly property int value: Math.max(0, root.altitudeStepBase + offset * root.tickStep)
            readonly property bool isMajor: (value % root.majorStep) === 0
            x: 0
            y: root.tapeCenterY
               - ((offset * root.tickStep) - root.altitudeStepRemainder) * root.pixelsPerUnit
               - height / 2
            width: root.width
            height: 16

            Rectangle {
                id: tickLine
                x: 1
                y: (parent.height - 2) / 2
                width: parent.width * (isMajor ? 0.22 : 0.12)
                height: isMajor ? 2 : 1
                color: Qt.rgba(1.0, 1.0, 1.0, isMajor ? 0.90 : 0.70)
            }

            Text {
                visible: isMajor
                anchors.left: tickLine.right
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                text: value
                color: Qt.rgba(1.0, 1.0, 1.0, 0.92)
                font.pixelSize: root.width * 0.18
                font.bold: (offset === 0)
            }
        }
    }

    Rectangle {
        id: readout
        x: 1
        width: root.width - 2
        height: root.height * 0.20
        y: root.tapeCenterY - height / 2
        radius: 2
        color: Qt.rgba(0.0, 0.0, 0.0, 0.82)
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.65)

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: root.altitudeValid ? root.altitudeFeet : "-"
            color: "white"
            font.pixelSize: root.width * 0.29
            font.bold: true
        }
    }

}
