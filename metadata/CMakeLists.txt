#
# Configure files
#

if (NOT ANDROID)
  # Source files in enrouteText are named after the upstream APP_ID.
  # Fall back to the upstream name when no file with the current APP_ID exists.
  set(_METADATA_SRC_ID ${APP_ID})
  if (NOT EXISTS ${CMAKE_SOURCE_DIR}/3rdParty/enrouteText/desktop/linux/${APP_ID}.appdata.xml.in)
    set(_METADATA_SRC_ID de.akaflieg_freiburg.enroute)
  endif()

  configure_file(${CMAKE_SOURCE_DIR}/3rdParty/enrouteText/desktop/linux/${_METADATA_SRC_ID}.appdata.xml.in ${APP_ID}.appdata.xml)
  configure_file(${CMAKE_SOURCE_DIR}/3rdParty/enrouteText/desktop/linux/${_METADATA_SRC_ID}.desktop.in ${APP_ID}.desktop)
  configure_file(${APP_ID}.svg ${APP_ID}.svg)
  
  install(FILES ${PROJECT_BINARY_DIR}/metadata/${APP_ID}.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
  install(FILES ${PROJECT_BINARY_DIR}/metadata/${APP_ID}.appdata.xml DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/metainfo)
  install(FILES ${PROJECT_SOURCE_DIR}/metadata/${APP_ID}.svg DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor/scalable/apps)
endif()
