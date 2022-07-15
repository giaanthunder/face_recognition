cmake_minimum_required(VERSION 3.4.1)

include_directories(../headers)
add_library(lib_tflite SHARED IMPORTED)
set_target_properties(lib_tflite PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/app/src/main/jniLibs/${ANDROID_ABI}/libtensorflowlite_c_delegate.so)

include_directories(../include)
add_library(lib_opencv SHARED IMPORTED)
set_target_properties(lib_opencv PROPERTIES IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/app/src/main/jniLibs/${ANDROID_ABI}/libopencv_java4.so)

add_library(common_lib SHARED ../ios/Classes/common_lib.cpp)
target_link_libraries(common_lib lib_tflite lib_opencv)
