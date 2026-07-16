/***************************************************************************
 *   Copyright (C) 2026 by EnrouteCL contributors                         *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 ***************************************************************************/

#pragma once

#include <QQmlEngine>

#include "GlobalObject.h"

namespace Navigation {

class SyntheticIlsManager : public GlobalObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit SyntheticIlsManager(QObject* parent = nullptr);

    // No default constructor, important for QML singleton
    explicit SyntheticIlsManager() = delete;

    static Navigation::SyntheticIlsManager* create(QQmlEngine* /*unused*/, QJSEngine* /*unused*/)
    {
        return GlobalObject::syntheticIlsManager();
    }

    Q_PROPERTY(bool ilsVisible READ ilsVisible NOTIFY ilsVisibleChanged)
    [[nodiscard]] bool ilsVisible() const { return m_ilsVisible; }

    Q_PROPERTY(double ilsLocalizerDeviation READ ilsLocalizerDeviation NOTIFY ilsLocalizerDeviationChanged)
    [[nodiscard]] double ilsLocalizerDeviation() const { return m_ilsLocalizerDeviation; }

    Q_PROPERTY(double ilsGlideslopeDeviation READ ilsGlideslopeDeviation NOTIFY ilsGlideslopeDeviationChanged)
    [[nodiscard]] double ilsGlideslopeDeviation() const { return m_ilsGlideslopeDeviation; }

signals:
    void ilsVisibleChanged();
    void ilsLocalizerDeviationChanged();
    void ilsGlideslopeDeviationChanged();

protected:
    void deferredInitialization() override;

private:
    void updateGuidance();

    bool m_ilsVisible {false};
    double m_ilsLocalizerDeviation {0.0};
    double m_ilsGlideslopeDeviation {0.0};
};

} // namespace Navigation
