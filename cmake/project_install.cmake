if(WIN32)
	get_target_property(_qmake_executable Qt${QT_VERSION_MAJOR}::qmake IMPORTED_LOCATION)
	get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
	find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${_qt_bin_dir}")
	add_custom_command(TARGET texstudio POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E
			env PATH="${_qt_bin_dir}" "${WINDEPLOYQT_EXECUTABLE}"
			--dir \"$<TARGET_FILE_DIR:texstudio>\"
			--plugindir \"$<TARGET_FILE_DIR:texstudio>/plugins\"
			--pdb
			--no-compiler-runtime
			\"$<TARGET_FILE:texstudio>\"
		COMMENT "Deploying Qt..."
	)
	foreach(_tf ${TRANSLATION_FILES})
		string(REPLACE ".ts" ".qm" _tfqb ${_tf})
		set(TRANSLATION_RESULTS ${TRANSLATION_RESULTS} ${_tfqb})
	endforeach()
	add_custom_command(TARGET texstudio POST_BUILD
		COMMAND cd ARGS /d "${CMAKE_SOURCE_DIR}"
		COMMAND "${CMAKE_COMMAND}" ARGS -E copy_if_different ${TRANSLATION_RESULTS} "$<TARGET_FILE_DIR:texstudio>/translations"
		WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
	)
	if(${CMAKE_SIZEOF_VOID_P} EQUAL 8)
		get_filename_component(_qt_openssl_bundle "${_qt_bin_dir}/../../../Tools/OpenSSL/Win_x64/bin" ABSOLUTE)
	else()
		get_filename_component(_qt_openssl_bundle "${_qt_bin_dir}/../../../Tools/OpenSSL/Win_x86/bin" ABSOLUTE)
	endif()
	if(EXISTS ${_qt_openssl_bundle})
		file(GLOB OPENSSL_DLL "${_qt_openssl_bundle}/*.dll")
		foreach(_openssl_dll IN LISTS OPENSSL_DLL)
			add_custom_command(TARGET texstudio POST_BUILD
				COMMAND ${CMAKE_COMMAND} ARGS -E copy_if_different "${_openssl_dll}" "$<TARGET_FILE_DIR:texstudio>"
			)
		endforeach()
	endif()
	function(texstudio_copy_all_files source_dir target_dir)
		file(GLOB TEMP_FILES ${source_dir}/*.*)
		add_custom_command(TARGET texstudio POST_BUILD
			COMMAND "${CMAKE_COMMAND}" ARGS -E make_directory "${target_dir}"
			COMMAND "${CMAKE_COMMAND}" ARGS -E copy_if_different ${TEMP_FILES} "${target_dir}"
		)
	endfunction()
	texstudio_copy_all_files("${CMAKE_SOURCE_DIR}/utilities/TexTablet" "$<TARGET_FILE_DIR:texstudio>/TexTablet")
	texstudio_copy_all_files("${CMAKE_SOURCE_DIR}/utilities/dictionaries" "$<TARGET_FILE_DIR:texstudio>/dictionaries")
	texstudio_copy_all_files("${CMAKE_SOURCE_DIR}/utilities/manual" "$<TARGET_FILE_DIR:texstudio>/help")
	texstudio_copy_all_files("${CMAKE_SOURCE_DIR}/templates" "$<TARGET_FILE_DIR:texstudio>/templates")
	if(Poppler_qt${QT_VERSION_MAJOR}_FOUND)
		get_target_property(PopplerQtDllDebug Poppler::poppler-qt${QT_VERSION_MAJOR} IMPORTED_LOCATION_DEBUG)
		get_target_property(PopplerQtDllRelease Poppler::poppler-qt${QT_VERSION_MAJOR} IMPORTED_LOCATION_RELEASE)
		add_custom_command(TARGET texstudio POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E copy_if_different $<$<CONFIG:Debug>:${PopplerQtDllDebug}> $<$<NOT:$<CONFIG:Debug>>:${PopplerQtDllRelease}> $<TARGET_FILE_DIR:texstudio>
		)
	endif()
	install(TARGETS texstudio RUNTIME DESTINATION .)
	install(DIRECTORY "$<TARGET_FILE_DIR:texstudio>/" DESTINATION .)
endif(WIN32)


macro(qt5_copy_dll APP DLL)
    # find the release *.dll file
    get_target_property(Qt5_${DLL}Location Qt5::${DLL} LOCATION)
    # find the debug *d.dll file
    get_target_property(Qt5_${DLL}LocationDebug Qt5::${DLL} IMPORTED_LOCATION_DEBUG)

    add_custom_command(TARGET ${APP} POST_BUILD
       COMMAND ${CMAKE_COMMAND} -E copy_if_different $<$<CONFIG:Debug>:${Qt5_${DLL}LocationDebug}> $<$<NOT:$<CONFIG:Debug>>:${Qt5_${DLL}Location}> $<TARGET_FILE_DIR:${APP}>)
endmacro()