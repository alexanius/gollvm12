
# Copyright 2018 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# Rules for building LLVMCppGoPasses library, which includes
# gollvm specific backend passes.

add_llvm_library(LLVMCppGoPasses
  GC.cpp
  GoAnnotation.cpp
  GoNilChecks.cpp
  GoSafeGetg.cpp
  GoStatepoints.cpp
  GoWrappers.cpp
  RemoveAddrSpace.cpp
  Util.cpp

  DEPENDS intrinsics_gen
)

include_directories(${DRIVER_UTILS_SOURCE_DIR})
