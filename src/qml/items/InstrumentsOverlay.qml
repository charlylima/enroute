/***************************************************************************
 *   Copyright (C) 2026 by EnrouteCL contributors                         *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 ***************************************************************************/

import QtQuick

import akaflieg_freiburg.enroute

Item {
    id: root

    property real compassSize: 120
    property real visibleCompassFraction: 0.70
    property real topHeadroom: compassSize * 0.12

    property bool trackValid: false
    property real bearing: 0
    property bool headingBugVisible: false
    property real headingBugCourse: 0

    property real sideTapeWidthFactor: 0.22
    property real sideTapeGapFactor: 0.03

    readonly property bool ilsVisible: SyntheticIlsManager.ilsVisible
    readonly property real ilsLocalizerDeviation: SyntheticIlsManager.ilsLocalizerDeviation
    readonly property real ilsGlideslopeDeviation: SyntheticIlsManager.ilsGlideslopeDeviation

    width: compassSize
    height: compassSize * visibleCompassFraction + topHeadroom

    opacity: (trackValid || ilsVisible) ? 1 : 0
    z: 1

    Behavior on opacity {
        NumberAnimation {
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    Item {
        id: compassViewport
        anchors.fill: parent
        clip: true

        Compass {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.topHeadroom
            bearing: root.trackValid ? root.bearing : Number.NaN
            headingBugVisible: root.trackValid && root.headingBugVisible
            headingBugCourse: root.headingBugCourse
            ilsVisible: root.ilsVisible
            ilsLocalizerDeviation: root.ilsLocalizerDeviation
            ilsGlideslopeDeviation: root.ilsGlideslopeDeviation
            size: root.compassSize
        }
    }

    SpeedTape {
        id: speedTape
        x: -width - root.compassSize * root.sideTapeGapFactor
        y: root.topHeadroom
        width: root.compassSize * root.sideTapeWidthFactor
        height: root.height - root.topHeadroom
        visible: root.visible
        opacity: root.opacity
        z: root.z
        speedText: Navigator.aircraft.horizontalSpeedToString(PositionProvider.positionInfo.groundSpeed())
    }

    AltitudeTape {
        id: altitudeTape
        x: root.width + root.compassSize * root.sideTapeGapFactor
        y: root.topHeadroom
        width: root.compassSize * root.sideTapeWidthFactor
        height: root.height - root.topHeadroom
        visible: root.visible
        opacity: root.opacity
        z: root.z
        altitudeValid: PositionProvider.pressureAltitude.isFinite() && !PositionProvider.pressureAltitude.isNegative()
        altitudeFeet: altitudeValid ? Math.round(PositionProvider.pressureAltitude.toFeet()) : 0
    }
}
