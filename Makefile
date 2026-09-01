VERSION       ?= $(shell cat libmagic.version)

PROJECT       := file-$(VERSION)
ARCHIVE       := $(PROJECT).tar.gz
URL           := https://astron.com/pub/file/$(ARCHIVE)

ROOT          := $(CURDIR)
BUILD         := $(ROOT)/.build/libmagic
SOURCE        := $(BUILD)/$(PROJECT)
ARCHIVE_FILE  := $(BUILD)/$(ARCHIVE)

DIST          := $(ROOT)/Frameworks
XCFRAMEWORK   := $(DIST)/libmagic.xcframework
RESOURCES_DIR := $(ROOT)/Sources/Magic/Resources

JOBS          ?= $(shell sysctl -n hw.ncpu)

IOS_MIN       ?= 13.0
MACOS_MIN     ?= 11.0

IOS_SDK       := $(shell xcrun --sdk iphoneos --show-sdk-path)
IOS_SIM_SDK   := $(shell xcrun --sdk iphonesimulator --show-sdk-path)
MACOS_SDK     := $(shell xcrun --sdk macosx --show-sdk-path)

CURL          := curl
TAR           := tar
MAKE          := make
LIPO          := xcrun lipo
XCODEBUILD    := xcodebuild

IOS_ARCHS     := arm64
SIM_ARCHS     := arm64
MACOS_ARCHS   := arm64

HOST_BUILD    := $(BUILD)/host
HOST_FILE     := $(HOST_BUILD)/src/file
HOST_STAMP    := $(HOST_BUILD)/.build-stamp
MAGIC_MGC     := $(BUILD)/magic.mgc

.PHONY: all download source ios ios-simulator macos \
        libmagic magic xcframework clean distclean

all: xcframework

download: $(ARCHIVE_FILE)

$(ARCHIVE_FILE):
	@mkdir -p "$(BUILD)"
	@echo "Downloading $(PROJECT)..."
	$(CURL) -L --fail --retry 3 -o "$@" "$(URL)"

source: $(SOURCE)

$(SOURCE): $(ARCHIVE_FILE)
	@rm -rf "$(SOURCE)"
	@echo "Extracting $(PROJECT)..."
	$(TAR) -xzf "$(ARCHIVE_FILE)" -C "$(BUILD)"
	@test -d "$(SOURCE)"
	@touch "$(SOURCE)"

define build_arch
	@echo "Building $(1) $(2)..."
	@rm -rf "$(BUILD)/$(1)/$(2)"
	@mkdir -p "$(BUILD)/$(1)/$(2)"

	cd "$(BUILD)/$(1)/$(2)" && \
		"$(SOURCE)/configure" \
			--disable-shared \
			--enable-static \
			--disable-silent-rules \
			--host="$(3)" \
			--prefix="$(BUILD)/install/$(1)/$(2)" \
			CC="clang" \
			CFLAGS="$(4)" \
			LDFLAGS="$(5)"

	@sed -i '' '/^[[:space:]]*#define HAVE_PIPE2[[:space:]]/d' \
		"$(BUILD)/$(1)/$(2)/config.h"

	$(MAKE) -C "$(BUILD)/$(1)/$(2)" \
		-j$(JOBS) \
		FILE_COMPILE="$(HOST_FILE)"

	@mkdir -p "$(BUILD)/install/$(1)/$(2)/lib"
	@mkdir -p "$(BUILD)/install/$(1)/$(2)/include"

	@cp "$(BUILD)/$(1)/$(2)/src/.libs/libmagic.a" \
		"$(BUILD)/install/$(1)/$(2)/lib/libmagic.a"

	@cp "$(BUILD)/$(1)/$(2)/src/magic.h" \
		"$(BUILD)/install/$(1)/$(2)/include/magic.h"

	@printf 'module libmagic {\n    umbrella header "magic.h"\n    export *\n    module * { export * }\n    link "z"\n    link "bz2"\n}\n' \
		> "$(BUILD)/install/$(1)/$(2)/include/module.modulemap"
endef

ios: host source
	$(foreach ARCH,$(IOS_ARCHS),\
		$(call build_arch,ios,$(ARCH),$(ARCH)-apple-darwin,\
			-isysroot $(IOS_SDK) -arch $(ARCH) -miphoneos-version-min=$(IOS_MIN),\
			-isysroot $(IOS_SDK) -arch $(ARCH) -miphoneos-version-min=$(IOS_MIN)\
		)\
	)

ios-simulator: host source
	$(foreach ARCH,$(SIM_ARCHS),\
		$(call build_arch,ios-simulator,$(ARCH),$(ARCH)-apple-darwin,\
			-isysroot $(IOS_SIM_SDK) -arch $(ARCH) -mios-simulator-version-min=$(IOS_MIN),\
			-isysroot $(IOS_SIM_SDK) -arch $(ARCH) -mios-simulator-version-min=$(IOS_MIN)\
		)\
	)

macos: host source
	$(foreach ARCH,$(MACOS_ARCHS),\
		$(call build_arch,macos,$(ARCH),$(ARCH)-apple-darwin,\
			-isysroot $(MACOS_SDK) -arch $(ARCH) -mmacosx-version-min=$(MACOS_MIN),\
			-isysroot $(MACOS_SDK) -arch $(ARCH) -mmacosx-version-min=$(MACOS_MIN)\
		)\
	)

define make_universal
	@mkdir -p "$(BUILD)/universal/$(1)/lib"
	$(LIPO) -create \
		$(foreach ARCH,$(2),\
			"$(BUILD)/install/$(1)/$(ARCH)/lib/libmagic.a" \
		) \
		-output "$(BUILD)/universal/$(1)/lib/libmagic.a"

	@mkdir -p "$(BUILD)/universal/$(1)/include"
	@cp "$(BUILD)/install/$(1)/$(firstword $(2))/include/magic.h" \
		"$(BUILD)/universal/$(1)/include/magic.h"
	@cp "$(BUILD)/install/$(1)/$(firstword $(2))/include/module.modulemap" \
		"$(BUILD)/universal/$(1)/include/module.modulemap"
endef

$(HOST_STAMP): $(SOURCE) $(MAKEFILE_LIST)
	@rm -rf "$(HOST_BUILD)"
	@mkdir -p "$(HOST_BUILD)"
	@echo "Configuring $(PROJECT) for host..."
	cd "$(HOST_BUILD)" && \
		"$(SOURCE)/configure" \
			--disable-shared \
			--enable-static \
			--prefix="$(HOST_BUILD)/install"

	$(MAKE) -C "$(HOST_BUILD)" -j$(JOBS)

	@test -x "$(HOST_FILE)"
	@test -f "$(HOST_BUILD)/magic/magic.mgc"
	@touch "$@"

host: $(HOST_STAMP)


libmagic: ios ios-simulator macos
	$(call make_universal,ios,$(IOS_ARCHS))
	$(call make_universal,ios-simulator,$(SIM_ARCHS))
	$(call make_universal,macos,$(MACOS_ARCHS))

magic: host
	@mkdir -p "$(BUILD)"
	@cp "$(HOST_BUILD)/magic/magic.mgc" "$(MAGIC_MGC)"

xcframework: libmagic magic
	@rm -rf "$(XCFRAMEWORK)"
	@mkdir -p "$(DIST)"

	$(XCODEBUILD) -create-xcframework \
		-library "$(BUILD)/universal/ios/lib/libmagic.a" \
		-headers "$(BUILD)/universal/ios/include" \
		-library "$(BUILD)/universal/ios-simulator/lib/libmagic.a" \
		-headers "$(BUILD)/universal/ios-simulator/include" \
		-library "$(BUILD)/universal/macos/lib/libmagic.a" \
		-headers "$(BUILD)/universal/macos/include" \
		-output "$(XCFRAMEWORK)"

	@mkdir -p "$(dir $(RESOURCES_DIR))"
	@cp "$(MAGIC_MGC)" "$(RESOURCES_DIR)/magic.mgc"
	@echo $(VERSION) > "$(RESOURCES_DIR)/version"

	@echo "Version: $(VERSION)"
	@echo "Created:"
	@echo "  $(XCFRAMEWORK)"
	@echo "  $(RESOURCES_DIR)/magic.mgc"
	@echo "  $(RESOURCES_DIR)/version"

clean:
	rm -rf "$(BUILD)"

distclean: clean
	rm -rf "$(DIST)"
