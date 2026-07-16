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

    property string speedText: "-"
    property int tickStep: 10
    property int valueRange: 60
    readonly property real tapeCenterY: Math.round(height / 2)
    readonly property bool speedValueValid: speedText.match(/-?\d+/) !== null
    readonly property int speedStepRemainder: speedValueValid ? ((speedValue % tickStep) + tickStep) % tickStep : 0
    readonly property int speedStepBase: speedValueValid ? (speedValue - speedStepRemainder) : 0
    readonly property real pixelsPerUnit: root.height / Math.max(1, valueRange)

    clip: true

    readonly property int speedValue: {
        const match = speedText.match(/-?\d+/)
        return match ? parseInt(match[0]) : 0
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.0, 0.0, 0.0, 0.24)
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.52)
        radius: 2
    }

    Repeater {
        model: 9
        delegate: Item {
            required property int index

            readonly property int offset: 4 - index
            readonly property int value: Math.max(0, root.speedStepBase + offset * root.tickStep)
            x: 0
            y: root.tapeCenterY
               - ((offset * root.tickStep) - root.speedStepRemainder) * root.pixelsPerUnit
               - height / 2
            width: root.width
            height: 16

            Rectangle {
                id: tickLine
                x: parent.width * 0.74
                y: (parent.height - 2) / 2
                width: parent.width * 0.22
                height: 2
                color: Qt.rgba(1.0, 1.0, 1.0, 0.86)
            }

            Text {
                anchors.right: tickLine.left
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                text: value
                color: Qt.rgba(1.0, 1.0, 1.0, 0.92)
                font.pixelSize: root.width * 0.18
                font.bold: offset === 0
            }
        }
    }

    Rectangle {
        x: 2
        width: root.width - 4
        height: root.height * 0.22
        y: root.tapeCenterY - height / 2
        radius: 3
        color: Qt.rgba(0.0, 0.0, 0.0, 0.82)
        border.width: 1
        border.color: Qt.rgba(1.0, 1.0, 1.0, 0.65)

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1
            text: root.speedValueValid ? root.speedValue : "-"
            color: "white"
            font.pixelSize: root.width * 0.30
            font.bold: true
        }
    }
}
