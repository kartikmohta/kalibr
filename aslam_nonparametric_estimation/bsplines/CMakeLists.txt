cmake_minimum_required(VERSION 2.8.3)
project(bsplines)

find_package(catkin_simple REQUIRED)

catkin_simple()

cs_add_library(${PROJECT_NAME}
  src/BSpline.cpp
  src/BSplinePose.cpp
)
target_link_libraries(${PROJECT_NAME} cholmod)


cs_install()
cs_export()
