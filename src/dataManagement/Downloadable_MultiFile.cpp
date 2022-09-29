/***************************************************************************
 *   Copyright (C) 2022 by Stefan Kebekus                                  *
 *   stefan.kebekus@gmail.com                                              *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 3 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#include "Downloadable_MultiFile.h"


DataManagement::Downloadable_MultiFile::Downloadable_MultiFile(QObject* parent)
    : Downloadable_Abstract(parent)
{
    m_contentType = MapSet;
}



//
// Getter methods
//

auto DataManagement::Downloadable_MultiFile::description() -> QString
{
    QString result;

    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        switch(map->contentType())
        {
        case Downloadable_SingleFile::AviationMap:
            result += "<h3>"+tr("Aviation Map")+"</h3>";
            break;
        case Downloadable_SingleFile::BaseMapVector:
            result += "<h3>"+tr("Base Map")+"</h3>";
            break;
        case Downloadable_SingleFile::BaseMapRaster:
            result += "<h3>"+tr("Raster Map")+"</h3>";
            break;
        case Downloadable_SingleFile::Data:
            result += "<h3>"+tr("Data")+"</h3>";
            break;
        case Downloadable_SingleFile::TerrainMap:
            result += "<h3>"+tr("Terrain Map")+"</h3>";
            break;
        case Downloadable_SingleFile::MapSet:
            result += "<h3>"+tr("Map Set")+"</h3>";
            break;
        }
        result += map->description();
    }
    return result;
}


auto DataManagement::Downloadable_MultiFile::downloading() -> bool
{
    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        if (map->downloading())
        {
            return true;
        }
    }
    return false;
}


auto DataManagement::Downloadable_MultiFile::hasFile() -> bool
{
    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        if (map->hasFile())
        {
            return true;
        }
    }
    return false;
}


auto DataManagement::Downloadable_MultiFile::infoText() -> QString
{
    QString result;

    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        if (!result.isEmpty())
        {
            result += QLatin1String("<br>");
        }
        switch(map->contentType())
        {
        case Downloadable_SingleFile::AviationMap:
            result += QStringLiteral("%1: %2").arg(tr("Aviation Map"), map->infoText());
            break;
        case Downloadable_SingleFile::BaseMapRaster:
            result += QStringLiteral("%1: %2").arg(tr("Raster Map"), map->infoText());
            break;
        case Downloadable_SingleFile::BaseMapVector:
            result += QStringLiteral("%1: %2").arg(tr("Base Map"), map->infoText());
            break;
        case Downloadable_SingleFile::Data:
            result += QStringLiteral("%1: %2").arg(tr("Data"), map->infoText());
            break;
        case Downloadable_SingleFile::MapSet:
            result += QStringLiteral("%1: %2").arg(tr("Map Set"), map->infoText());
            break;
        case Downloadable_SingleFile::TerrainMap:
            result += QStringLiteral("%1: %2").arg(tr("Terrain Map"), map->infoText());
            break;
        }
    }
    return result;
}


auto DataManagement::Downloadable_MultiFile::updateSize() -> qsizetype
{
    if (!hasFile())
    {
        return 0;
    }

    m_maps.removeAll(nullptr);
    qsizetype result = 0;
    foreach(auto map, m_maps)
    {
        if (map->hasFile())
        {
            result += map->updateSize();
        }
        else
        {
            result += map->remoteFileSize();
        }
    }
    return result;
}



//
// Methods
//

void DataManagement::Downloadable_MultiFile::deleteFiles()
{
    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        map->deleteFiles();
    }
}


void DataManagement::Downloadable_MultiFile::startDownload()
{
    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        map->startDownload();
    }
}


void DataManagement::Downloadable_MultiFile::stopDownload()
{
    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        map->stopDownload();
    }
}


void DataManagement::Downloadable_MultiFile::update()
{
    if (updateSize() == 0)
    {
        return;
    }

    m_maps.removeAll(nullptr);
    foreach(auto map, m_maps)
    {
        if (map->hasFile())
        {
            map->update();
        }
        else
        {
            map->startDownload();
        }
    }
}


void DataManagement::Downloadable_MultiFile::add(DataManagement::Downloadable_SingleFile* map)
{
    if (map == nullptr)
    {
        return;
    }

    setObjectName(map->objectName());
    setSection(map->section());

    if (m_maps.contains(map))
    {
        return;
    }

    m_maps.append(map);

    connect(map, &DataManagement::Downloadable_SingleFile::descriptionChanged, this, &DataManagement::Downloadable_Abstract::descriptionChanged);
    connect(map, &DataManagement::Downloadable_SingleFile::downloadingChanged, this, &DataManagement::Downloadable_MultiFile::downloadingChanged);
    connect(map, &DataManagement::Downloadable_SingleFile::error, this, &DataManagement::Downloadable_MultiFile::error);
    connect(map, &DataManagement::Downloadable_SingleFile::fileContentChanged, this, &DataManagement::Downloadable_MultiFile::fileContentChanged);
    connect(map, &DataManagement::Downloadable_SingleFile::hasFileChanged, this, &DataManagement::Downloadable_MultiFile::hasFileChanged);
    connect(map, &DataManagement::Downloadable_SingleFile::hasFileChanged, this, &DataManagement::Downloadable_MultiFile::updateSizeChanged);
    connect(map, &DataManagement::Downloadable_SingleFile::infoTextChanged, this, &DataManagement::Downloadable_MultiFile::infoTextChanged);
    connect(map, &DataManagement::Downloadable_SingleFile::updateSizeChanged, this, &DataManagement::Downloadable_MultiFile::updateSizeChanged);
}