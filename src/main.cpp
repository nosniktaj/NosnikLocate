#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>

#include "locationmanager.h"
#include "usermanager.h"
#include "friendmanager.h"
#include "networkmanager.h"
#include "settingsmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    app.setApplicationName("NosnikLocate");
    app.setOrganizationName("Nosniktaj");
    app.setOrganizationDomain("nosniktaj.com");
    app.setApplicationVersion("1.0.0");

    QQuickStyle::setStyle("Material");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", "Dark");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_ACCENT", "#BB86FC");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_PRIMARY", "#121212");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_BACKGROUND", "#1E1E2E");

    qmlRegisterSingletonType<NetworkManager>("NosnikLocate", 1, 0, "NetworkManager",
        [](QQmlEngine *engine, QJSEngine *) -> QObject * {
            Q_UNUSED(engine)
            return NetworkManager::instance();
        });

    qmlRegisterSingletonType<SettingsManager>("NosnikLocate", 1, 0, "SettingsManager",
        [](QQmlEngine *engine, QJSEngine *) -> QObject * {
            Q_UNUSED(engine)
            return SettingsManager::instance();
        });

    qmlRegisterSingletonType<UserManager>("NosnikLocate", 1, 0, "UserManager",
        [](QQmlEngine *engine, QJSEngine *) -> QObject * {
            Q_UNUSED(engine)
            return UserManager::instance();
        });

    qmlRegisterSingletonType<LocationManager>("NosnikLocate", 1, 0, "LocationManager",
        [](QQmlEngine *engine, QJSEngine *) -> QObject * {
            Q_UNUSED(engine)
            return LocationManager::instance();
        });

    qmlRegisterSingletonType<FriendManager>("NosnikLocate", 1, 0, "FriendManager",
        [](QQmlEngine *engine, QJSEngine *) -> QObject * {
            Q_UNUSED(engine)
            return FriendManager::instance();
        });

    QQmlApplicationEngine engine;

    const QUrl url(u"qrc:/NosnikLocate/qml/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
