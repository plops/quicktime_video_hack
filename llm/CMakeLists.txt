
cmake_minimum_required(VERSION 3.0)

project(libusb_iphone_handshake)

# Find libusb
#find_package(libusb-1.0 REQUIRED)

# Create the executable
add_executable(${PROJECT_NAME} 03_handshake.cpp)

# Link with libusb
#target_link_libraries(${PROJECT_NAME} PRIVATE libusb-1.0::usb-1.0)


# Find libusb-1.0 using pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBUSB REQUIRED libusb-1.0)


# Link with libusb
target_link_libraries(${PROJECT_NAME} PRIVATE ${LIBUSB_LIBRARIES})
