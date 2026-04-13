cmake_minimum_required(VERSION 3.21)

project(NosnikLocate VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS
    Quick
    QuickControls2
    Positioning
    Location
    Network
    Sql
    Svg
)

qt_standard_project_setup(REQUIRES 6.5)

set(CPP_SOURCES
    src/main.cpp
    src/locationmanager.cpp
    src/usermanager.cpp
    src/friendmanager.cpp
    src/friendmodel.cpp
    src/networkmanager.cpp
    src/settingsmanager.cpp
)

set(CPP_HEADERS
    src/locationmanager.h
    src/usermanager.h
    src/friendmanager.h
    src/friendmodel.h
    src/networkmanager.h
    src/settingsmanager.h
)

set(QML_FILES
    qml/Main.qml
    qml/LoginPage.qml
    qml/RegisterPage.qml
    qml/VerifyEmailPage.qml
    qml/MapPage.qml
    qml/FriendsPage.qml
    qml/NotificationsPage.qml
    qml/SettingsPage.qml
    qml/components/NosnikButton.qml
    qml/components/NosnikTextField.qml
    qml/components/AvatarCircle.qml
    qml/components/FriendCard.qml
    qml/components/FriendRequestCard.qml
    qml/components/AddFriendDialog.qml
    qml/components/MapFriendMarker.qml
)

qt_add_executable(NosnikLocate
    ${CPP_SOURCES}
    ${CPP_HEADERS}
)

qt_add_qml_module(NosnikLocate
    URI NosnikLocate
    VERSION 1.0
    QML_FILES ${QML_FILES}
    SOURCES ${CPP_HEADERS}
)

target_link_libraries(NosnikLocate PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Positioning
    Qt6::Location
    Qt6::Network
    Qt6::Sql
    Qt6::Svg
)

target_include_directories(NosnikLocate PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/src)

# Android-specific settings
if(ANDROID)
    # Detect host OS for OpenSSL path
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set(OPENSSL_ROOT_DIR "C:/android_openssl" CACHE PATH "Path to android_openssl")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
        set(OPENSSL_ROOT_DIR "$ENV{HOME}/android_openssl" CACHE PATH "Path to android_openssl")
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")  # macOS
        set(OPENSSL_ROOT_DIR "$ENV{HOME}/android_openssl" CACHE PATH "Path to android_openssl")
    endif()

    if(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
        set(_SSL_ABI_DIR "${OPENSSL_ROOT_DIR}/ssl_3/x86_64")
    elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
        set(_SSL_ABI_DIR "${OPENSSL_ROOT_DIR}/ssl_3/arm64-v8a")
    elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
        set(_SSL_ABI_DIR "${OPENSSL_ROOT_DIR}/ssl_3/armeabi-v7a")
    elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
        set(_SSL_ABI_DIR "${OPENSSL_ROOT_DIR}/ssl_3/x86")
    endif()

    # Validate the path exists before using it
    if(NOT EXISTS "${_SSL_ABI_DIR}/libssl_3.so")
        message(WARNING "OpenSSL not found at ${_SSL_ABI_DIR}. "
                        "Clone it with: git clone https://github.com/KDAB/android_openssl.git ${OPENSSL_ROOT_DIR}")
    endif()

    set(ANDROID_EXTRA_LIBS
        "${_SSL_ABI_DIR}/libssl_3.so"
        "${_SSL_ABI_DIR}/libcrypto_3.so"
        CACHE INTERNAL ""
    )

    set_target_properties(NosnikLocate PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
        QT_ANDROID_TARGET_SDK_VERSION 34
        QT_ANDROID_MIN_SDK_VERSION 26
        QT_ANDROID_EXTRA_LIBS "${ANDROID_EXTRA_LIBS}"
    )

    set(QT_ANDROID_PERMISSIONS
        "android.permission.ACCESS_FINE_LOCATION"
        "android.permission.ACCESS_COARSE_LOCATION"
        "android.permission.ACCESS_BACKGROUND_LOCATION"
        "android.permission.INTERNET"
        "android.permission.ACCESS_NETWORK_STATE"
    )
endif()

# iOS-specific settings
if(APPLE AND NOT MACOS)
    set_target_properties(NosnikLocate PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.nosniktaj.nosniklocate"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.nosniktaj.nosniklocate"
    )

    target_link_libraries(NosnikLocate PRIVATE
        "-framework CoreLocation"
    )
endif()

install(TARGETS NosnikLocate
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
