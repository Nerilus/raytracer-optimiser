cmake_minimum_required(VERSION 3.5.0)
project(raytracer VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Option pour activer/désactiver le threading
option(ENABLE_THREADING "Enable multithreading for rendering" OFF)

# Si le threading est activé, ajouter la définition du compilateur
if(ENABLE_THREADING)
  add_compile_definitions(ENABLE_THREADING)
  message(STATUS "Multithreading activé")
else()
  message(STATUS "Multithreading désactivé")
endif()

add_executable(raytracer main.cpp)

target_include_directories(raytracer PUBLIC
                           "${PROJECT_BINARY_DIR}"
                           "${PROJECT_SOURCE_DIR}/src/raymath"
                           "${PROJECT_SOURCE_DIR}/src/rayimage"
                           "${PROJECT_SOURCE_DIR}/src/rayscene"
                           )

add_subdirectory(./src/raymath)
add_subdirectory(./src/rayimage)
add_subdirectory(./src/rayscene)
add_subdirectory(./src/lodepng)

target_link_libraries(raytracer 
                      PUBLIC 
                      rayscene
                      raymath
                      rayimage
                      lodepng
                      )

enable_testing()
add_subdirectory(tests)

