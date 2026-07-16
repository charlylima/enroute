/***************************************************************************
 *   Copyright (C) 2026 by EnrouteCL contributors                         *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 ***************************************************************************/

import QtQuick
import QtQuick.Controls

// Round compass rose that rotates to show the aircraft's true track.
//
// Usage:
//   Compass {
//       bearing: flightMap.animatedTT   // aircraft true track in degrees
//       size:    120
//   }

Item {
    id: root

    // Aircraft true track in degrees (0 = N, positive clockwise)
    property real bearing: 0
    readonly property bool trackValid: isFinite(bearing)

    // Heading bug (typically next-leg true course in degrees).
    property bool headingBugVisible: false
    property real headingBugCourse: 0
    property real headingBugTopOverflow: size * 0.10

    // Synthetic ILS guidance: normalized angular deviations in [-1, 1].
    property bool ilsVisible: false
    property real ilsLocalizerDeviation: 0
    property real ilsGlideslopeDeviation: 0

    // Overall diameter of the widget
    property real size: 120

    width:  size
    height: size

    onBearingChanged: {
        headingBugCanvas.requestPaint()
        referenceBugCanvas.requestPaint()
    }
    onTrackValidChanged: {
        headingBugCanvas.requestPaint()
        referenceBugCanvas.requestPaint()
    }
    onHeadingBugCourseChanged: headingBugCanvas.requestPaint()
    onHeadingBugVisibleChanged: {
        headingBugCanvas.requestPaint()
        referenceBugCanvas.requestPaint()
    }

    // ── Rotating rose ────────────────────────────────────────────────────────
    Item {
        id: rose
        anchors.centerIn: parent
        width:  root.size
        height: root.size
        rotation: root.trackValid ? -root.bearing : 0

        Behavior on rotation {
            RotationAnimation {
                direction: RotationAnimation.Shortest
                duration:  400
            }
        }

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                const cx  = width  / 2
                const cy  = height / 2
                const r   = width  / 2 - 2

                if (r <= 0) return
                ctx.clearRect(0, 0, width, height)

                // ── Background: light smoky disc, more transparent than before ──
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, 2 * Math.PI)
                const bgGrad = ctx.createRadialGradient(cx, cy - r * 0.12, r * 0.05,
                                                        cx, cy,             r)
                bgGrad.addColorStop(0.00, "rgba(95,95,95,0.10)")
                bgGrad.addColorStop(0.60, "rgba(55,55,55,0.14)")
                bgGrad.addColorStop(1.00, "rgba(10,10,10,0.21)")
                ctx.fillStyle = bgGrad
                ctx.fill()

                // ── Tick marks: every 2.5° with clear 2.5/5/10/30/90 hierarchy ──
                const tickOuter = r - 4
                for (let i = 0; i < 144; i++) {
                    const deg     = i * 2.5
                    const a       = (deg - 90) * Math.PI / 180
                    const isCard  = (i % 36 === 0)  // 90°
                    const is30    = !isCard && (i % 12 === 0)
                    const is10    = !isCard && !is30 && (i % 4 === 0)
                    const is5     = !isCard && !is30 && !is10 && (i % 2 === 0)

                    let tickLen, lw, col
                    if (isCard) {
                        tickLen = r * 0.115; lw = 1.7
                        col = "rgba(255,255,255,0.96)"
                    } else if (is30) {
                        tickLen = r * 0.085; lw = 1.25
                        col = "rgba(255,255,255,0.90)"
                    } else if (is10) {
                        tickLen = r * 0.062; lw = 1.0
                        col = "rgba(255,255,255,0.82)"
                    } else if (is5) {
                        tickLen = r * 0.045; lw = 0.85
                        col = "rgba(255,255,255,0.74)"
                    } else {
                        tickLen = r * 0.030; lw = 0.7
                        col = "rgba(255,255,255,0.66)"
                    }

                    ctx.beginPath()
                    ctx.moveTo(cx + tickOuter             * Math.cos(a),
                               cy + tickOuter             * Math.sin(a))
                    ctx.lineTo(cx + (tickOuter - tickLen) * Math.cos(a),
                               cy + (tickOuter - tickLen) * Math.sin(a))
                    ctx.strokeStyle = col
                    ctx.lineWidth   = lw
                    ctx.stroke()
                }

                // Inner rings to mimic instrument-style rose layering.
                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.72, 0, 2 * Math.PI)
                ctx.strokeStyle = "rgba(255,255,255,0.26)"
                ctx.lineWidth = 1.0
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, r * 0.46, 0, 2 * Math.PI)
                ctx.strokeStyle = "rgba(255,255,255,0.20)"
                ctx.lineWidth = 1.0
                ctx.stroke()
            }
        }

        // Course numbers every 30° (3,6,9,...,33,36) rotating with the rose.
        Repeater {
            model: 12
            delegate: Text {
                required property int index

                readonly property int angle: index * 30
                readonly property string courseText: angle === 0 ? "36" : String(angle / 10)
                visible: angle % 90 !== 0

                x: root.size/2
                         + (root.size/2 - root.size * 0.120) * Math.sin(angle * Math.PI/180)
                   - width/2
                y: root.size/2
                         - (root.size/2 - root.size * 0.120) * Math.cos(angle * Math.PI/180)
                   - height/2

                text: courseText
                color: Qt.rgba(1.0, 1.0, 1.0, 0.78)
                    font.pixelSize: root.size * 0.058
                font.bold: false
                font.family: "sans-serif"
                style: Text.Outline
                styleColor: Qt.rgba(0.0, 0.0, 0.0, 0.55)
                transformOrigin: Item.Center
                rotation: angle
            }
        }

        // Subtle cardinal letters, much smaller than before.
        Repeater {
            model: [
                { label: "N", angle:   0 },
                { label: "E", angle:  90 },
                { label: "S", angle: 180 },
                { label: "W", angle: 270 }
            ]
            delegate: Text {
                required property var modelData

                // Position along the inside edge, inset enough to clear the ticks
                x: root.size/2
                         + (root.size/2 - root.size * 0.135) * Math.sin(modelData.angle * Math.PI/180)
                   - width/2
                y: root.size/2
                         - (root.size/2 - root.size * 0.135) * Math.cos(modelData.angle * Math.PI/180)
                   - height/2

                text:  modelData.label
                color: Qt.rgba(1.0, 1.0, 1.0, 0.88)
                    font.pixelSize: root.size * 0.078
                font.bold:      false
                font.family:    "sans-serif"
                style:          Text.Outline
                styleColor:     Qt.rgba(0.0, 0.0, 0.0, 0.70)
                transformOrigin: Item.Center
                rotation: modelData.angle
            }
        }
    }

    // ── Fixed center marker (white dot with black outline) ──────────────────
    Canvas {
        id: aircraftSymbol
        anchors.centerIn: parent
        width: root.size * 0.068
        height: root.size * 0.068

        onPaint: {
            const ctx = getContext("2d")
            const w = width
            const h = height
            if (w <= 0 || h <= 0) return
            ctx.clearRect(0, 0, w, h)

            const cx = w / 2
            const cy = h / 2
            const radius = Math.min(w, h) * 0.33

            const dotGrad = ctx.createRadialGradient(
                cx - radius * 0.40, cy - radius * 0.40, radius * 0.15,
                cx,                 cy,                 radius
            )
            dotGrad.addColorStop(0.00, "rgba(255,255,255,0.98)")
            dotGrad.addColorStop(0.70, "rgba(238,238,238,0.97)")
            dotGrad.addColorStop(1.00, "rgba(190,190,190,0.96)")

            ctx.beginPath()
            ctx.arc(cx, cy, radius, 0, 2 * Math.PI)
            ctx.fillStyle = dotGrad
            ctx.fill()

            ctx.strokeStyle = "rgba(0,0,0,0.92)"
            ctx.lineWidth = Math.max(1, radius * 0.18)
            ctx.stroke()
        }
    }

    // ── Metallic rim + glass lens overlay (fixed, on top of everything) ──────
    Canvas {
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            const cx  = width  / 2
            const cy  = height / 2
            const r   = width  / 2 - 2

            if (r <= 0) return
            ctx.clearRect(0, 0, width, height)

            // ── Metallic bevelled rim ─────────────────────────────────────
            // Simulates a polished chrome ring lit from the top: bright at
            // 12 o'clock, mid-grey at 3/9, dark at 6 o'clock.
            const rimW   = Math.max(1, r * 0.020)
            const rimGrad = ctx.createLinearGradient(cx, cy - r, cx, cy + r)
            rimGrad.addColorStop(0.00, "rgba(255,255,255,0.75)")
            rimGrad.addColorStop(0.25, "rgba(180,180,180,0.48)")
            rimGrad.addColorStop(0.55, "rgba(85,85,85,0.40)")
            rimGrad.addColorStop(1.00, "rgba(25,25,25,0.62)")
            ctx.beginPath()
            ctx.arc(cx, cy, r - rimW/2, 0, 2 * Math.PI)
            ctx.strokeStyle = rimGrad
            ctx.lineWidth   = rimW
            ctx.stroke()

            // Fine inner edge highlight for a crisp instrument bezel.
            ctx.beginPath()
            ctx.arc(cx, cy, r - rimW - 1, 0, 2 * Math.PI)
            ctx.strokeStyle = "rgba(255,255,255,0.25)"
            ctx.lineWidth = 1
            ctx.stroke()

            // ── Glass lens: bright crescent clipped to upper hemisphere ───
            // A clip region (upper half circle) keeps the highlight from
            // bleeding into the lower half, giving a realistic convex-lens look.
            ctx.save()
            ctx.beginPath()
            ctx.arc(cx, cy, r - rimW, -Math.PI, 0)   // upper semicircle
            ctx.lineTo(cx + (r - rimW), cy)
            ctx.closePath()
            ctx.clip()

            const lensGrad = ctx.createRadialGradient(
                cx,          cy - r * 0.42, r * 0.02,  // highlight spot near top
                cx,          cy,            r * 0.90
            )
            lensGrad.addColorStop(0.00, "rgba(255,255,255,0.36)")
            lensGrad.addColorStop(0.25, "rgba(255,255,255,0.16)")
            lensGrad.addColorStop(0.55, "rgba(255,255,255,0.03)")
            lensGrad.addColorStop(1.00, "rgba(255,255,255,0.00)")
            ctx.beginPath()
            ctx.arc(cx, cy, r - rimW, 0, 2 * Math.PI)
            ctx.fillStyle = lensGrad
            ctx.fill()
            ctx.restore()

            // Faint darkening at the very bottom edge (depth illusion)
            const shadowGrad = ctx.createRadialGradient(cx, cy + r * 0.55, r * 0.30,
                                                        cx, cy,             r - rimW)
            shadowGrad.addColorStop(0.00, "rgba(0,0,0,0.00)")
            shadowGrad.addColorStop(1.00, "rgba(0,0,0,0.18)")
            ctx.beginPath()
            ctx.arc(cx, cy, r - rimW, 0, 2 * Math.PI)
            ctx.fillStyle = shadowGrad
            ctx.fill()
        }
    }

    // ── Blue heading bug (route-course marker) ──────────────────────────────
    Canvas {
        id: headingBugCanvas
        anchors.fill: parent
        visible: root.headingBugVisible && root.trackValid

        onPaint: {
            const ctx = getContext("2d")
            const cx = width / 2
            const cy = height / 2
            const r  = width / 2 - 2

            ctx.clearRect(0, 0, width, height)
            if (!root.trackValid || !root.headingBugVisible || r <= 0 || !isFinite(root.headingBugCourse))
                return

            const tipR = r - Math.max(1, r * 0.010)
            const depth = Math.max(6, r * 0.100)
            const halfW = Math.max(5, r * 0.050)

            // Angle relative to screen top after rose rotation.
            const relDeg = root.headingBugCourse - root.bearing
            const a = (relDeg - 90) * Math.PI / 180

            const tipX = cx + tipR * Math.cos(a)
            const tipY = cy + tipR * Math.sin(a)

            // Unit vectors: inward radial and tangent.
            const inX = -Math.cos(a)
            const inY = -Math.sin(a)
            const tanX = -Math.sin(a)
            const tanY =  Math.cos(a)

            const baseCX = tipX + inX * depth
            const baseCY = tipY + inY * depth

            const p1X = baseCX + tanX * halfW
            const p1Y = baseCY + tanY * halfW
            const p2X = baseCX - tanX * halfW
            const p2Y = baseCY - tanY * halfW

            ctx.beginPath()
            ctx.moveTo(tipX, tipY)
            ctx.lineTo(p1X, p1Y)
            ctx.lineTo(p2X, p2Y)
            ctx.closePath()
            ctx.fillStyle = "rgba(85,190,255,0.95)"
            ctx.fill()
            ctx.strokeStyle = "rgba(0,0,0,0.85)"
            ctx.lineWidth = 1.2
            ctx.stroke()
        }
    }

    // ── Fixed black reference bug in top overflow area ──────────────────────
    Canvas {
        id: referenceBugCanvas
        x: 0
        y: -root.headingBugTopOverflow
        width: root.width
        height: root.height + root.headingBugTopOverflow
        visible: root.trackValid

        onPaint: {
            const ctx = getContext("2d")
            const cx = width / 2
            const cy = root.height / 2 + root.headingBugTopOverflow
            const r  = root.width / 2 - 2

            ctx.clearRect(0, 0, width, height)
            if (!root.trackValid || r <= 0)
                return

            const tipR = r - Math.max(1, r * 0.010)
            const depth = Math.max(6, r * 0.100)
            const halfW = Math.max(5, r * 0.050)

            // Fixed at top center with a small outward shift; points inward.
            const a = -Math.PI / 2
            const rimShift = depth * 0.40

            const rimX = cx + (tipR + rimShift) * Math.cos(a)
            const rimY = cy + (tipR + rimShift) * Math.sin(a)

            const inX = -Math.cos(a)
            const inY = -Math.sin(a)
            const tanX = -Math.sin(a)
            const tanY =  Math.cos(a)

            const tipX = rimX + inX * depth
            const tipY = rimY + inY * depth
            const baseCX = rimX
            const baseCY = rimY

            const p1X = baseCX + tanX * halfW
            const p1Y = baseCY + tanY * halfW
            const p2X = baseCX - tanX * halfW
            const p2Y = baseCY - tanY * halfW

            const metalGrad = ctx.createLinearGradient(baseCX, baseCY, tipX, tipY)
            metalGrad.addColorStop(0.00, "rgba(28,28,28,0.96)")
            metalGrad.addColorStop(0.45, "rgba(92,92,92,0.95)")
            metalGrad.addColorStop(1.00, "rgba(185,185,185,0.92)")

            ctx.beginPath()
            ctx.moveTo(tipX, tipY)
            ctx.lineTo(p1X, p1Y)
            ctx.lineTo(p2X, p2Y)
            ctx.closePath()
            ctx.fillStyle = metalGrad
            ctx.fill()
            ctx.strokeStyle = "rgba(20,20,20,0.95)"
            ctx.lineWidth = 1.2
            ctx.stroke()
        }
    }

    Item {
        id: ilsIndicator
        anchors.centerIn: parent
        width: root.size * 0.62
        height: width
        visible: root.ilsVisible

        // Keep bars strictly inside the inner compass area.
        readonly property real maxDeflection: width * 0.28
        readonly property real locX: Math.max(-1, Math.min(1, root.ilsLocalizerDeviation)) * maxDeflection
        readonly property real gsY: Math.max(-1, Math.min(1, root.ilsGlideslopeDeviation)) * maxDeflection

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.46
            height: 1
            color: Qt.rgba(1.0, 1.0, 1.0, 0.36)
        }

        Rectangle {
            anchors.centerIn: parent
            width: 1
            height: parent.height * 0.46
            color: Qt.rgba(1.0, 1.0, 1.0, 0.36)
        }

        Rectangle {
            width: 2
            height: parent.height * 0.76
            radius: 1
            x: parent.width / 2 + parent.locX - width / 2
            y: (parent.height - height) / 2
            color: Qt.rgba(0.22, 0.85, 1.0, 0.96)
        }

        Rectangle {
            width: parent.width * 0.76
            height: 2
            radius: 1
            x: (parent.width - width) / 2
            y: parent.height / 2 + parent.gsY - height / 2
            color: Qt.rgba(0.22, 0.85, 1.0, 0.96)
        }
    }

}
