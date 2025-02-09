LOCAL_PATH := $(call my-dir)

platform      := android

CORE_DIR      := $(LOCAL_PATH)/..
ROOT_DIR      := $(LOCAL_PATH)/..
LIBRETRO_DIR  := $(ROOT_DIR)/libretro

SOURCES_C     :=
SOURCES_CXX   :=
SOURCES_ASM   :=
INCFLAGS      :=
CFLAGS        :=
CXXFLAGS      :=
DYNAFLAGS     :=
NO_THREADS    := 0
HAVE_NEON     := 0
WITH_DYNAREC  :=
HAVE_CHD      := 1

HAVE_GL       := 1
HAVE_OPENGL   := 1
GLES          := 1

HOST_CPU_X86=0x20000001
HOST_CPU_ARM=0x20000002
HOST_CPU_MIPS=0x20000003
HOST_CPU_X64=0x20000004
HOST_CPU_GENERIC=0x20000005
HOST_CPU_ARM64=0x20000006

ifeq ($(TARGET_ARCH_ABI),arm64-v8a)
  WITH_DYNAREC := arm64
else ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
  WITH_DYNAREC := arm
  HAVE_NEON := 1
else ifeq ($(TARGET_ARCH_ABI),x86)
  WITH_DYNAREC := x86
else ifeq ($(TARGET_ARCH_ABI),x86_64)
  WITH_DYNAREC := x86_64
endif

include $(ROOT_DIR)/Makefile.common

COREFLAGS := -ffast-math -D__LIBRETRO__ -DINLINE="inline" -DANDROID -D_ANDROID -DHAVE_OPENGLES -DHAVE_OPENGLES2 $(GLFLAGS) $(INCFLAGS) $(DYNAFLAGS)
COREFLAGS += -DRELEASE -DNDEBUG -DNO_VERIFY

ifeq ($(NO_THREADS),1)
COREFLAGS += -DTARGET_NO_THREADS
endif

ifeq ($(HAVE_GENERIC_JIT),1)
COREFLAGS += -DTARGET_NO_JIT -DFEAT_SHREC=0x40000003
endif

ifeq ($(TARGET_ARCH_ABI),x86_64)
	COREFLAGS += -fno-operator-names
	COREFLAGS += -DHOST_CPU=$(HOST_CPU_X64)
endif

ifeq ($(TARGET_ARCH_ABI), x86)
	COREFLAGS += -DHOST_CPU=$(HOST_CPU_X86)
endif
ifeq ($(WITH_DYNAREC), x86)
	# X86 dynarec isn't position independent, so it fails to build on newer ndks.
	# No warn shared textrel allows it to build, but still won't allow it to run on api 23+.
	CORELDLIBS := -Wl,-no-warn-shared-textrel
endif

ifeq ($(TARGET_ARCH_ABI), armeabi-v7a)
	COREFLAGS += -DHOST_CPU=$(HOST_CPU_ARM)
endif

ifeq ($(TARGET_ARCH_ABI), arm64-v8a)
	COREFLAGS += -DHOST_CPU=$(HOST_CPU_ARM64)
endif

ifeq ($(TARGET_ARCH_ABI), mips)
	COREFLAGS += -DHOST_CPU=$(HOST_CPU_MIPS)
endif

GIT_VERSION := " $(shell git rev-parse --short HEAD || echo unknown)"
ifneq ($(GIT_VERSION)," unknown")
  COREFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"
endif

ifeq ($(HAVE_CHD),1)
COREFLAGS += -DFLAC__HAS_OGG=0 -FLAC__NO_DLL -DHAVE_LROUND -DHAVE_STDINT_H -DHAVE_STDLIB_H -DHAVE_SYS_PARAM_H -D_7ZIP_ST -DUSE_FLAC -DUSE_LZMA
endif

include $(CLEAR_VARS)
LOCAL_MODULE       := retro
LOCAL_SRC_FILES    := $(SOURCES_CXX) $(SOURCES_C) $(SOURCES_ASM)
LOCAL_CFLAGS       := $(COREFLAGS) $(CFLAGS)
LOCAL_CXXFLAGS     := -std=c++11 $(COREFLAGS) $(CXXFLAGS)
LOCAL_LDFLAGS      := -Wl,-version-script=$(CORE_DIR)/link.T
LOCAL_LDLIBS       := -lGLESv2 -llog $(CORELDLIBS)
LOCAL_CPP_FEATURES := exceptions
LOCAL_ARM_NEON     := true
LOCAL_ARM_MODE     := arm

ifeq ($(NO_THREADS),1)
else
#LOCAL_LDLIBS       += -lpthread
endif
include $(BUILD_SHARED_LIBRARY)
