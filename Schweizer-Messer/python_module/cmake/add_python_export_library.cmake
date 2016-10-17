# Helpful function for adding python export libraries in ROS.
# Usage:
#
# rosbuild_find_ros_package(numpy_eigen)
# include(${numpy_eigen_PACKAGE_PATH}/cmake/add_python_export_library.cmake)
# add_python_export_library(${PROJECT_NAME}_python ${PROJECT_SOURCE_DIR}/src/${PROJECT_NAME}
#                           src/file1.cpp
#                           src/file2.cpp
#                          )
#
#
# Set the path for the output python files. This should be the path
# with the __init__.py file. The standard for ROS (where python message
# definitions live) is ${PROJECT_SOURCE_DIR}/src/${PROJECT_NAME}


FUNCTION(add_python_export_library TARGET_NAME PYTHON_MODULE_DIRECTORY )

  # Cmake is a very bad scripting language. Very bad indeed.
  # Get the leaf of the python module directory. This is the python package name
  # This first command makes sure to strip off the trailing /
  get_filename_component(TMP "${PYTHON_MODULE_DIRECTORY}/garbage.txt" PATH)
  # This grabs the leaf of the path
  get_filename_component(PYTHON_PACKAGE_NAME "${TMP}.txt" NAME_WE)
  # This grabs the parent of the leaf
  get_filename_component(PYTHON_MODULE_DIRECTORY_PREFIX "${TMP}.txt" PATH)


  set(SETUP_PY "${CMAKE_CURRENT_SOURCE_DIR}/setup.py")
  if(EXISTS ${SETUP_PY})
  else()
    set(SETUP_PY_TEXT "
## ! DO NOT MANUALLY INVOKE THIS setup.py, USE CATKIN INSTEAD

from distutils.core import setup
from catkin_pkg.python_setup import generate_distutils_setup

# fetch values from package.xml
setup_args = generate_distutils_setup(
    packages=['${PYTHON_PACKAGE_NAME}'],
    package_dir={'':'${PYTHON_MODULE_DIRECTORY_PREFIX}'})

setup(**setup_args)
")

    file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/setup.py" ${SETUP_PY_TEXT})
    message( SEND_ERROR "Error! ${SETUP_PY} does not exist
This is a problem. Let me tell you about it.

In the rosbuild days, we used the manifest.xml file to export python libs and __init__.py files. With catkin, this is no longer possible. Now we have to include a setup.py file that tells catkin what directories we need installed. The setup.py file should be in the root of your package source directory.

From how you called this function, I expect that your package looks like this:

${CMAKE_CURRENT_SOURCE_DIR}/${PYTHON_MODULE_DIRECTORY_PREFIX}/${PYTHON_PACKAGE_NAME}/__init__.py

Then your setup.py file should look like this. I have done the variable substitution for you. I'm now writing this text into ${SETUP_PY}. Please commit this to your source repository.

${SETUP_PY_TEXT}

")
  endif()
  # Force the user to have a setup.py file
  catkin_python_setup()

  # Find Python
  FIND_PACKAGE(PythonLibs 2.7 REQUIRED)
  INCLUDE_DIRECTORIES(${PYTHON_INCLUDE_DIRS})

  if(APPLE)
    SET(BOOST_COMPONENTS python system)
  else()
    SET(BOOST_COMPONENTS python)
  endif()
  find_package(Boost REQUIRED COMPONENTS ${BOOST_COMPONENTS})

  IF(APPLE)
    # The apple framework headers don't include the numpy headers for some reason.
    GET_FILENAME_COMPONENT(REAL_PYTHON_INCLUDE ${PYTHON_INCLUDE_DIRS} REALPATH)
    IF( ${REAL_PYTHON_INCLUDE} MATCHES Python.framework)
      message("Trying to find extra headers for numpy from ${REAL_PYTHON_INCLUDE}.")
      message("Looking in ${REAL_PYTHON_INCLUDE}/../../Extras/lib/python/numpy/core/include/numpy")
      FIND_PATH(NUMPY_INCLUDE_DIR arrayobject.h
	${REAL_PYTHON_INCLUDE}/../../Extras/lib/python/numpy/core/include/numpy
	${REAL_PYTHON_INCLUDE}/numpy
	)
      IF(${NUMPY_INCLUDE_DIR} MATCHES NOTFOUND)
	message("Unable to find numpy include directories: ${NUMPY_INCLUDE_DIR}")
      ELSE()
	message("Found headers at ${NUMPY_INCLUDE_DIR}")
	INCLUDE_DIRECTORIES(${NUMPY_INCLUDE_DIR})
	INCLUDE_DIRECTORIES(${NUMPY_INCLUDE_DIR}/..)
      ENDIF()
    ENDIF()
  ENDIF(APPLE)


  # message("Target files: ${ARGN}")
  # Create the target and assign source files
  add_library( ${TARGET_NAME}
      ${ARGN}
    )

  # Link your python project to the main library and to Python
  target_link_libraries( ${TARGET_NAME}
    ${PYTHON_LIBRARY}
    ${catkin_LIBRARIES}
    )

  # Link against boost::python
  target_link_libraries(${TARGET_NAME} ${Boost_LIBRARIES})

  install(TARGETS ${TARGET_NAME}
    ARCHIVE DESTINATION ${CATKIN_GLOBAL_PYTHON_DESTINATION}/${PYTHON_PACKAGE_NAME}
    LIBRARY DESTINATION ${CATKIN_GLOBAL_PYTHON_DESTINATION}/${PYTHON_PACKAGE_NAME}
  )

  # Cause the library to be output in the correct directory.
  set_target_properties(${TARGET_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CATKIN_DEVEL_PREFIX}/${CATKIN_GLOBAL_PYTHON_DESTINATION}/${PYTHON_PACKAGE_NAME}
    )

ENDFUNCTION()

