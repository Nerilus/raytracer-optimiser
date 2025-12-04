
    # 1. Run Raytracer
    execute_process(
        COMMAND ${RAYTRACER_EXE} ${SCENE_FILE} ${OUTPUT_FILE}
        RESULT_VARIABLE RET1
        OUTPUT_VARIABLE OUT1
        ERROR_VARIABLE ERR1
    )
    if(NOT RET1 EQUAL 0)
        message(FATAL_ERROR "Raytracer failed: ${OUT1} ${ERR1}")
    endif()

    # Parse output for time (very simple regex/string find)
    # Total time: 0.123 seconds.
    string(REGEX MATCH "Total time: ([0-9.]+) seconds" TIME_MATCH "${OUT1}")
    if(TIME_MATCH)
        string(REGEX REPLACE "Total time: ([0-9.]+) seconds" "\\1" TIME_VAL "${TIME_MATCH}")
        message("Parsed Time: ${TIME_VAL} s")
        
        # Append to metrics file
        file(APPEND "${METRICS_FILE}" "${TEST_NAME},${TIME_VAL}\n")
    else()
        message(WARNING "Could not parse time from output")
    endif()

    # 2. Run Comparator if REF_FILE provided
    if(NOT "${REF_FILE}" STREQUAL "")
        execute_process(
            COMMAND ${COMPARATOR_EXE} ${OUTPUT_FILE} ${REF_FILE}
            RESULT_VARIABLE RET2
            OUTPUT_VARIABLE OUT2
            ERROR_VARIABLE ERR2
        )
        if(NOT RET2 EQUAL 0)
            message(FATAL_ERROR "Image comparison failed: ${OUT2} ${ERR2}")
        endif()
    else()
        message("No reference file provided, skipping comparison.")
    endif()

    message("Test passed!")
