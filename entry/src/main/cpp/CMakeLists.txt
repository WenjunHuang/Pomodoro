cmake_minimum_required(VERSION 3.16)
project(timer_native)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)


add_library(timer_native SHARED
    timer_native.cpp
)


#find_library(NAPI_LIB napi)
#target_link_libraries(timer_native PRIVATE ${NAPI_LIB})
target_link_libraries(timer_native PUBLIC libace_napi.z.so)
target_link_libraries(timer_native PUBLIC libhilog_ndk.z.so)

