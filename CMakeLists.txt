cmake_minimum_required(VERSION 3.16)
include(ExternalProject)
set(TARGET caesium_image_compressor)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
if (WIN32)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
else ()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations -Wno-deprecated-register -Wno-deprecated")
endif ()
set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM 1)

if (APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
    project(${TARGET} LANGUAGES CXX OBJCXX)
else ()
    project(${TARGET} LANGUAGES CXX)
endif ()

find_program(CARGO "cargo" REQUIRED)

add_compile_definitions(QT_DISABLE_DEPRECATED_BEFORE=0x050F00)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_AUTOUIC_SEARCH_PATHS views)

if (APPLE)
    set(MACOSX_BUNDLE_ICON_FILE icon.icns)
    set(CAESIUM_ICON ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons/icon.icns)
    set_source_files_properties(${CAESIUM_ICON} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
elseif (WIN32)
    set(CAESIUM_ICON ${CMAKE_CURRENT_SOURCE_DIR}/resources/icons.rc)
endif ()

if (NOT (DEFINED ENV{CMAKE_PREFIX_PATH} OR DEFINED CMAKE_PREFIX_PATH))
    message(FATAL_ERROR "CMAKE_PREFIX_PATH is not defined. Cannot find Qt dir.")
endif ()

if (WIN32)
    set(WINSPARKLE_LIB_DIR ${CMAKE_BINARY_DIR}/libwinsparkle-prefix/src/libwinsparkle/x64/Release)
    link_directories(${WINSPARKLE_LIB_DIR})
endif ()

if (APPLE OR WIN32)
    if (APPLE)
        if (NOT DEFINED SPARKLE_INCLUDE_DIR)
            message(FATAL_ERROR "SPARKLE_INCLUDE_DIR is not defined. Cannot find sparkle include dir.")
        else ()
            include_directories(${SPARKLE_INCLUDE_DIR})
        endif ()

        if (NOT DEFINED LIBSSH_INCLUDE_DIR)
            message(FATAL_ERROR "LIBSSH_INCLUDE_DIR is not defined. Cannot find libssh include dir.")
        else ()
            include_directories(${LIBSSH_INCLUDE_DIR})
        endif ()
    endif ()
endif ()

set(LIBCAESIUM_SOURCE_DIR ${CMAKE_BINARY_DIR}/libcaesium-prefix/src/libcaesium)
string(TOLOWER ${CMAKE_BUILD_TYPE} LIBCAESIUM_BUILD_TYPE)
if (WIN32)
    link_directories(${LIBCAESIUM_SOURCE_DIR}/target/x86_64-pc-windows-gnu/${LIBCAESIUM_BUILD_TYPE})
else ()
    link_directories(${LIBCAESIUM_SOURCE_DIR}/target/${LIBCAESIUM_BUILD_TYPE})
endif ()

find_package(QT NAMES Qt6 Qt5 COMPONENTS Widgets Core Gui Concurrent Svg Network LinguistTools REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} COMPONENTS Widgets Core Gui Concurrent Svg Network LinguistTools REQUIRED)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/include)

set(SOURCES
        src/main.cpp
        src/MainWindow.cpp
        src/models/CImage.cpp
        src/models/CImageTreeItem.cpp
        src/models/CImageTreeModel.cpp
        src/models/CImageSortFilterProxyModel.cpp
        src/utils/Utils.cpp
        src/dialogs/AboutDialog.cpp
        src/widgets/QDropTreeView.cpp
        src/widgets/QZoomGraphicsView.cpp
        src/widgets/QCaesiumMessageBox.cpp
        src/widgets/QMainCheckBox.cpp
        src/delegates/HtmlDelegate.cpp
        src/exceptions/ImageNotSupportedException.cpp
        src/exceptions/ImageTooBigException.cpp
        src/dialogs/PreferencesDialog.cpp
        src/network/NetworkOperations.cpp
        )

set(HEADERS
        src/MainWindow.h
        src/models/CImage.h
        src/models/CImageTreeItem.h
        src/models/CImageTreeModel.h
        src/models/CImageSortFilterProxyModel.h
        src/utils/Utils.h
        src/dialogs/AboutDialog.h
        src/widgets/QDropTreeView.h
        src/widgets/QZoomGraphicsView.h
        src/widgets/QCaesiumMessageBox.h
        src/widgets/QMainCheckBox.h
        src/delegates/HtmlDelegate.h
        src/exceptions/ImageNotSupportedException.h
        src/exceptions/ImageTooBigException.h
        src/dialogs/PreferencesDialog.h
        src/network/NetworkOperations.h
        )

if (APPLE)
    set(OSX_SOURCES
            src/updater/osx/AutoUpdater.cpp
            src/updater/osx/CocoaInitializer.mm
            src/updater/osx/SparkleAutoUpdater.mm
            )
    set(OSX_HEADERS
            src/updater/osx/AutoUpdater.h
            src/updater/osx/SparkleAutoUpdater.h
            )

else ()
    set(WIN_HEADERS
            src/updater/win/winsparkle.h
            )
endif ()

set(UI
        views/MainWindow.ui
        views/AboutDialog.ui
        views/PreferencesDialog.ui)

SET(TS_FILES
        resources/i18n/caesium_en_US.ts
        resources/i18n/caesium_it_IT.ts
        resources/i18n/caesium_fr_FR.ts
        resources/i18n/caesium_zh_CN.ts
        resources/i18n/caesium_ja_JP.ts
        resources/i18n/caesium_es_ES.ts
        resources/i18n/caesium_ar_EG.ts)

set_source_files_properties(${TS_FILES} PROPERTIES OUTPUT_LOCATION ${CMAKE_BINARY_DIR}/i18n)
if (QT_VERSION_MAJOR EQUAL "6")
    qt6_create_translation(QM_FILES
            ${CMAKE_SOURCE_DIR}
            ${TS_FILES})
else ()
    qt5_create_translation(QM_FILES
            ${CMAKE_SOURCE_DIR}
            ${TS_FILES})
endif ()
configure_file(resources/languages.qrc ${CMAKE_BINARY_DIR} COPYONLY)

set(RESOURCES
        ${CMAKE_BINARY_DIR}/languages.qrc
        resources/resources.qrc)

if (WIN32)
    add_executable(${TARGET} WIN32 ${SOURCES} ${HEADERS} ${WIN_HEADERS} ${UI} ${RESOURCES} ${CAESIUM_ICON} ${QM_FILES})
else ()
    add_executable(${TARGET} MACOSX_BUNDLE ${SOURCES} ${OSX_SOURCES} ${HEADERS} ${OSX_HEADERS} ${UI} ${RESOURCES} ${CAESIUM_ICON} ${QM_FILES})
endif ()

# --- libcaesium ---
if (CMAKE_BUILD_TYPE MATCHES Debug)
    set(CARGO_BUILD_FLAGS "")
else ()
    set(CARGO_BUILD_FLAGS "--release")
endif ()

set(CARGO_TARGET "")
if (WIN32)
    set(CARGO_TARGET "--target=x86_64-pc-windows-gnu")
endif ()

ExternalProject_Add(
        libcaesium
        GIT_REPOSITORY https://github.com/Lymphatus/libcaesium
        GIT_TAG 0.8.1
        CONFIGURE_COMMAND ""
        BUILD_COMMAND ${CARGO} build ${CARGO_BUILD_FLAGS} ${CARGO_TARGET}
        INSTALL_COMMAND ""
        BINARY_DIR ${LIBCAESIUM_SOURCE_DIR}
        LOG_BUILD ON
)

add_dependencies(caesium_image_compressor libcaesium)

# --- WinSparkle ---
if (WIN32)
    ExternalProject_Add(
            libwinsparkle
            URL https://github.com/vslavik/winsparkle/releases/download/v0.7.0/WinSparkle-0.7.0.zip
            CONFIGURE_COMMAND ""
            BUILD_COMMAND ""
            INSTALL_COMMAND cmake -E echo "Skipping install step."
            LOG_BUILD ON
    )
    add_dependencies(caesium_image_compressor libwinsparkle)
endif ()

if (APPLE)
    set(OSX_FRAMEWORKS "-framework AppKit -framework Carbon -framework Foundation -framework ApplicationServices -framework Sparkle")
    set_target_properties(${TARGET} PROPERTIES MACOSX_BUNDLE_INFO_PLIST "${CMAKE_SOURCE_DIR}/Info.plist" LINK_FLAGS "-F/Library/Frameworks -Wl -rpath @loader_path/../Frameworks")
endif ()

set_target_properties(${TARGET} PROPERTIES OUTPUT_NAME "Caesium Image Compressor")
if (APPLE)
    target_link_libraries(${TARGET} PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Gui Qt${QT_VERSION_MAJOR}::Concurrent Qt${QT_VERSION_MAJOR}::Svg Qt${QT_VERSION_MAJOR}::Network ${OSX_FRAMEWORKS} caesium)
elseif (WIN32)
    target_link_libraries(${TARGET} PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Gui Qt${QT_VERSION_MAJOR}::Concurrent Qt${QT_VERSION_MAJOR}::Svg Qt${QT_VERSION_MAJOR}::Network winsparkle caesium)
else ()
    target_link_libraries(${TARGET} PRIVATE Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Gui Qt${QT_VERSION_MAJOR}::Concurrent Qt${QT_VERSION_MAJOR}::Svg Qt${QT_VERSION_MAJOR}::Network caesium)
endif ()

add_subdirectory(tests)
add_test(NAME CsTests COMMAND CsTests)
