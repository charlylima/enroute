/***************************************************************************
 *   Copyright (C) 2021 by Stefan Kebekus                                  *
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

#include <QApplication>
#include <QDBusInterface>
#include <QDBusReply>

#include "dataManagement/DataManager.h"
#include "GlobalObject.h"
#include "platform/Notifier_Linux.h"


// This implementation of notifications uses the specification found here:
// https://specifications.freedesktop.org/notification-spec/latest/ar01s09.html
//
// Help with DBus programming is found here:
// https://develop.kde.org/docs/d-bus/accessing_dbus_interfaces/

Platform::Notifier::Notifier(QObject *parent)
    : Platform::Notifier::Notifier_Abstract(parent)
{
    notficationInterface = new QDBusInterface("org.freedesktop.Notifications",
                                              "/org/freedesktop/Notifications",
                                              "org.freedesktop.Notifications",
                                              QDBusConnection::sessionBus(), this);
    connect(notficationInterface, SIGNAL(ActionInvoked(uint,QString)), this, SLOT(onActionInvoked(uint,QString)));
    connect(notficationInterface, SIGNAL(NotificationClosed(uint,uint)), this, SLOT(onNotificationClosed(uint,uint)));
}


Platform::Notifier::~Notifier()
{
    if (!notficationInterface.isNull()) {
        foreach(auto notificationID, notificationIDs) {
            if (notificationID == 0) {
                continue;
            }
            notficationInterface->call("CloseNotification", notificationID);
        }
    }

}


void Platform::Notifier::hideNotification(Platform::Notifier::NotificationTypes notificationType)
{

    auto notificationID = notificationIDs.value(notificationType, 0);
    if (notificationID == 0) {
        return;
    }
    if (notficationInterface.isNull()) {
        return;
    }

    notficationInterface->call("CloseNotification", notificationID);
    notificationIDs.remove(notificationType);

}


void Platform::Notifier::onActionInvoked(uint id, QString key)
{

    if (key == "GeoMap_Dismiss") {
        // The method onNotificationClosed will later be called. The following line ensures
        // that the signal notificationClicked() is then no longer emitted.
        notificationIDs.remove(GeoMapUpdatePending);
    }
    if (key == "GeoMap_Update") {
        GlobalObject::dataManager()->geoMaps()->updateAll();

        // The method onNotificationClosed will later be called. The following line ensures
        // that the signal notificationClicked() is then no longer emitted.
        notificationIDs.remove(GeoMapUpdatePending);
    }

}


void Platform::Notifier::onNotificationClosed(uint id, uint reason)
{
    // reason == 2 means: notification is closed because user clicked on it
    if (reason != 2) {
        return;
    }

    // Find notification type and emit signal
    NotificationTypes type;
    bool haveType = false;
    QMap<NotificationTypes, uint>::const_iterator i = notificationIDs.constBegin();
    while (i != notificationIDs.constEnd()) {
        if (i.value() == id) {
            // We do not emit here because that will change the QMap while
            // we iterate over it -> crash
            haveType = true;
            type = i.key();
        }
        i++;
    }
    if (haveType) {
        emit notificationClicked(type);
    }
}


void Platform::Notifier::showNotification(NotificationTypes notificationType, const QString& text, const QString& longText)
{
    Q_UNUSED(text)
    Q_UNUSED(longText)

    // Paranoid safety checks
    if (notficationInterface.isNull()) {
        return;
    }

    // Close pending notification, if any
    hideNotification(notificationType);

    QStringList actions;
    if (notificationType == GeoMapUpdatePending) {
        actions << "GeoMap_Update" << tr("Update");
        actions << "GeoMap_Dismiss" << tr("Dismiss");
    }

    QDBusReply<uint> reply = notficationInterface->call("Notify",
                                                        "Enroute Flight Navigation",
                                                        notificationIDs.value(notificationType, 0), // Notification to replace. 0 means: do not replace
                                                        "", // Icon
                                                        "Enroute Flight Navigation", // Title
                                                        title(notificationType), // Summary
                                                        actions, // actions_list
                                                        QMap<QString,QVariant>(), // hint
                                                        0); // time: 0 means: never expire.
    if (reply.isValid()) {
        notificationIDs.insert(notificationType, reply.value());
    }

}
