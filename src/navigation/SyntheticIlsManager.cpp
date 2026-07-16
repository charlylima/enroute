/***************************************************************************
 *   Copyright (C) 2026 by EnrouteCL contributors                         *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 ***************************************************************************/

#include "navigation/SyntheticIlsManager.h"

#include <QDebug>
#include <QRegularExpression>

#include <algorithm>
#include <cmath>

#include "geomaps/GeoMapProvider.h"
#include "positioning/PositionProvider.h"

namespace {

constexpr double ilsActivationDistanceM = 15000.0;
constexpr double ilsGlideslopeDeg = 3.0;
constexpr double ilsLocalizerFullScaleDeg = 5.0;
constexpr double ilsGlideslopeFullScaleDeg = 1.4;
constexpr double pi = 3.14159265358979323846;

[[nodiscard]] auto normalizeDegrees(double deg) -> double
{
    auto d = std::fmod(deg, 360.0);
    if (d > 180.0) {
        d -= 360.0;
    }
    if (d < -180.0) {
        d += 360.0;
    }
    return d;
}

[[nodiscard]] auto clamp(double value, double lo, double hi) -> double
{
    return std::clamp(value, lo, hi);
}

[[nodiscard]] auto runwayAlignedCourse(const GeoMaps::Waypoint& waypoint,
                                       const Units::Angle& fallbackCourse) -> Units::Angle
{
    const auto runwayRegex = QRegularExpression(QStringLiteral("\\b([0-3][0-9])[LRC]?\\b"));
    QList<double> runwayHeadings;

    for (const auto& line : waypoint.tabularDescription()) {
        if (!line.startsWith(QStringLiteral("RWY "))) {
            continue;
        }

        auto it = runwayRegex.globalMatch(line);
        while (it.hasNext()) {
            const auto match = it.next();
            bool ok = false;
            const auto runwayNumber = match.captured(1).toInt(&ok);
            if (!ok || runwayNumber < 1 || runwayNumber > 36) {
                continue;
            }

            runwayHeadings.append((runwayNumber == 36) ? 0.0 : runwayNumber * 10.0);
        }
    }

    if (runwayHeadings.isEmpty()) {
        return fallbackCourse;
    }

    if (!fallbackCourse.isFinite()) {
        return Units::Angle::fromDEG(runwayHeadings.first());
    }

    const auto target = fallbackCourse.toDEG();
    auto bestHeading = runwayHeadings.first();
    auto bestAbsDiff = std::abs(normalizeDegrees(bestHeading - target));

    for (auto heading : std::as_const(runwayHeadings)) {
        const auto absDiff = std::abs(normalizeDegrees(heading - target));
        if (absDiff < bestAbsDiff) {
            bestAbsDiff = absDiff;
            bestHeading = heading;
        }
    }

    return Units::Angle::fromDEG(bestHeading);
}

} // namespace

Navigation::SyntheticIlsManager::SyntheticIlsManager(QObject* parent) : GlobalObject(parent)
{
}

void Navigation::SyntheticIlsManager::deferredInitialization()
{
    connect(GlobalObject::positionProvider(),
            &Positioning::PositionProvider::positionInfoChanged,
            this,
            &Navigation::SyntheticIlsManager::updateGuidance);
    updateGuidance();
}

void Navigation::SyntheticIlsManager::updateGuidance()
{
    qDebug() << "SyntheticIlsManager::updateGuidance() called";

    auto visible = false;
    auto localizerDeviation = 0.0;
    auto glideslopeDeviation = 0.0;

    const auto ownInfo = GlobalObject::positionProvider()->positionInfo();
    if (ownInfo.isValid()) {
        const auto ownCoord = ownInfo.coordinate();
        GeoMaps::Waypoint targetAirfield;

        // Pick nearest aerodrome from map provider (already distance-sorted).
        const auto nearbyAD = GlobalObject::geoMapProvider()->nearbyWaypoints(ownCoord, QStringLiteral("AD"));
        if (!nearbyAD.isEmpty()) {
            targetAirfield = nearbyAD.first();
        }

        if (targetAirfield.isValid()) {
            const auto thresholdCoord = targetAirfield.coordinate();
            const auto inboundFallback = Units::Angle::fromDEG(ownCoord.azimuthTo(thresholdCoord));
            const auto inboundCourse = runwayAlignedCourse(targetAirfield, inboundFallback);

            if (thresholdCoord.isValid() && inboundCourse.isFinite()) {
                const auto distanceToThresholdM = ownCoord.distanceTo(thresholdCoord);
                if (std::isfinite(distanceToThresholdM) && distanceToThresholdM <= ilsActivationDistanceM) {
                    const auto thresholdToOwnRadialDeg = thresholdCoord.azimuthTo(ownCoord);
                    const auto approachRadialDeg = std::fmod(inboundCourse.toDEG() + 180.0, 360.0);
                    const auto localizerErrorDeg = normalizeDegrees(thresholdToOwnRadialDeg - approachRadialDeg);

                    visible = true;
                    if (std::isfinite(localizerErrorDeg)) {
                        localizerDeviation = clamp(localizerErrorDeg / ilsLocalizerFullScaleDeg, -1.0, 1.0);
                    } else {
                        // Exactly at threshold or degenerate azimuth: keep CDI centered.
                        localizerDeviation = 0.0;
                    }

                    const auto ownAltitude = ownInfo.trueAltitudeAMSL();
                    const auto thresholdAltitudeM = thresholdCoord.altitude();
                    if (ownAltitude.isFinite() && std::isfinite(thresholdAltitudeM)) {
                        const auto pathAngleDeg = std::atan2(ownAltitude.toM() - thresholdAltitudeM,
                                                             std::max(1.0, distanceToThresholdM)) * 180.0 / pi;
                        const auto glideslopeErrorDeg = pathAngleDeg - ilsGlideslopeDeg;
                        glideslopeDeviation = clamp(glideslopeErrorDeg / ilsGlideslopeFullScaleDeg, -1.0, 1.0);
                    }
                }
            }
        }
    }

    if (m_ilsVisible != visible) {
        m_ilsVisible = visible;
        qDebug() << "SyntheticIlsManager: ilsVisible changed to" << m_ilsVisible;
        emit ilsVisibleChanged();
    }
    if (!qFuzzyCompare(m_ilsLocalizerDeviation, localizerDeviation)) {
        m_ilsLocalizerDeviation = localizerDeviation;
        qDebug() << "SyntheticIlsManager: ilsLocalizerDeviation changed to" << m_ilsLocalizerDeviation;
        emit ilsLocalizerDeviationChanged();
    }
    if (!qFuzzyCompare(m_ilsGlideslopeDeviation, glideslopeDeviation)) {
        m_ilsGlideslopeDeviation = glideslopeDeviation;
        qDebug() << "SyntheticIlsManager: ilsGlideslopeDeviation changed to" << m_ilsGlideslopeDeviation;
        emit ilsGlideslopeDeviationChanged();
    }
}
