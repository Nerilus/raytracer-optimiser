find_package(Python3 COMPONENTS Interpreter)

add_executable(compare_images compare_images.cpp)
target_include_directories(compare_images PRIVATE ${PROJECT_SOURCE_DIR}/src/lodepng)
target_link_libraries(compare_images PRIVATE lodepng)

# Script générique pour exécuter le test
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/run_test.cmake 
"
    # 1. Run Raytracer
    execute_process(
        COMMAND \${RAYTRACER_EXE} \${SCENE_FILE} \${OUTPUT_FILE}
        RESULT_VARIABLE RET1
        OUTPUT_VARIABLE OUT1
        ERROR_VARIABLE ERR1
    )
    if(NOT RET1 EQUAL 0)
        message(FATAL_ERROR \"Raytracer failed: \${OUT1} \${ERR1}\")
    endif()

    # Parse output for time (very simple regex/string find)
    # Total time: 0.123 seconds.
    string(REGEX MATCH \"Total time: ([0-9.]+) seconds\" TIME_MATCH \"\${OUT1}\")
    if(TIME_MATCH)
        string(REGEX REPLACE \"Total time: ([0-9.]+) seconds\" \"\\\\1\" TIME_VAL \"\${TIME_MATCH}\")
        message(\"Parsed Time: \${TIME_VAL} s\")
        
        # Append to metrics file
        file(APPEND \"\${METRICS_FILE}\" \"\${TEST_NAME},\${TIME_VAL}\\n\")
    else()
        message(WARNING \"Could not parse time from output\")
    endif()

    # 2. Run Comparator if REF_FILE provided
    if(NOT \"\${REF_FILE}\" STREQUAL \"\")
        # Utiliser la tolérance fournie ou 0 par défaut
        if(NOT DEFINED TOLERANCE)
            set(TOLERANCE \"0\")
        endif()
        execute_process(
            COMMAND \${COMPARATOR_EXE} \${OUTPUT_FILE} \${REF_FILE} \${TOLERANCE}
            RESULT_VARIABLE RET2
            OUTPUT_VARIABLE OUT2
            ERROR_VARIABLE ERR2
        )
        if(NOT RET2 EQUAL 0)
            message(FATAL_ERROR \"Image comparison failed: \${OUT2} \${ERR2}\")
        endif()
    else()
        message(\"No reference file provided, skipping comparison.\")
    endif()

    message(\"Test passed!\")
"
)

# Macro pour ajouter un test
# TOLERANCE optionnel : tolérance pour la comparaison d'images (défaut: 0 pour comparaison exacte)
macro(add_raytracer_test TEST_NAME SCENE_FILE REF_FILE)
    # Vérifier si un 4ème paramètre (tolérance) est fourni
    if(${ARGC} GREATER 3)
        set(TOLERANCE_VAL ${ARGV3})
    else()
        set(TOLERANCE_VAL "0")
    endif()
    add_test(NAME ${TEST_NAME}
        COMMAND ${CMAKE_COMMAND} 
        -DRAYTRACER_EXE=$<TARGET_FILE:raytracer>
        -DSCENE_FILE=${SCENE_FILE}
        -DOUTPUT_FILE=${TEST_NAME}.png
        -DREF_FILE=${REF_FILE}
        -DCOMPARATOR_EXE=$<TARGET_FILE:compare_images>
        -DTEST_NAME=${TEST_NAME}
        -DMETRICS_FILE=${PROJECT_BINARY_DIR}/metrics.csv
        -DTOLERANCE=${TOLERANCE_VAL}
        -P ${CMAKE_CURRENT_BINARY_DIR}/run_test.cmake
    )
endmacro()

# 1. Regular tests
add_raytracer_test(EndToEnd_TwoSpheres 
    ${PROJECT_SOURCE_DIR}/scenes/two-spheres-on-plane.json 
    ${PROJECT_SOURCE_DIR}/readme/two-spheres-on-plane.png
)

add_raytracer_test(EndToEnd_Monkey
    ${PROJECT_SOURCE_DIR}/scenes/monkey-on-plane.json
    ${PROJECT_SOURCE_DIR}/readme/monkey-on-plane.png
)
# Le test Monkey prend beaucoup de temps (>1000s), définir un timeout très long
set_tests_properties(EndToEnd_Monkey PROPERTIES TIMEOUT 3600)

add_raytracer_test(EndToEnd_TwoTriangles
    ${PROJECT_SOURCE_DIR}/scenes/two-triangles-on-plane.json
    ${PROJECT_SOURCE_DIR}/readme/two-triangles-on-plane.png
    "2"
)

# 2. Edge case test (Small empty image)
add_raytracer_test(EdgeCase_Empty
    ${PROJECT_SOURCE_DIR}/scenes/edge-case-empty.json
    ""
)

# 3. Demonstration of Failure (Regression Test)
# Ce test doit échouer car on compare Spheres avec la référence Monkey
# On utilise set_tests_properties pour dire à CTest qu'on S'ATTEND à ce qu'il échoue (WILL_FAIL TRUE)
# Mais pour votre démo "Démonstration d'un scénario d'échec", il vaut peut-être mieux le laisser échouer "pour de vrai".
# Je vais le laisser échouer normalement pour que vous voyiez l'erreur.
add_raytracer_test(EndToEnd_FailureDemo
    ${PROJECT_SOURCE_DIR}/scenes/two-spheres-on-plane.json
    ${PROJECT_SOURCE_DIR}/readme/monkey-on-plane.png
)

# Créer le fichier de métriques vide au début si n'existe pas
if(NOT EXISTS ${PROJECT_BINARY_DIR}/metrics.csv)
    file(WRITE ${PROJECT_BINARY_DIR}/metrics.csv "TestName,DurationSeconds\n")
endif()
