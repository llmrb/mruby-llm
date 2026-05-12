# Makefile for mruby-llm
#
# Prerequisites:
#   ../mruby    # mruby checkout (sibling directory)
#
# Quick start:
#   make        # build toolchain and run tests
#   make test   # run tests
#   make clean  # clean local build artifacts

MRUBY_DIR    ?= ../mruby
RUBY         ?= ruby
BUILD_CONFIG  = build.rb
BUILD_NAME    = mruby-llm
BUILD_DIR     = $(MRUBY_DIR)/build/$(BUILD_NAME)
BUILD_PROFILE ?= test

TOOLCHAIN_BIN   = bin/mruby bin/mrbc bin/mruby-config
TOOLCHAIN_STAMP = tmp/toolchain.$(BUILD_PROFILE).stamp
SPEC_FILES     != find spec -type f -name '*_spec.rb' 2>/dev/null | sort
RUBY_SOURCES   != find mrblib spec -type f -name '*.rb' 2>/dev/null | sort
RAKE           = $(RUBY) -rrubygems -e 'load Gem.bin_path("rake", "rake")' --

.PHONY: all test toolchain clean distclean

all: toolchain test

test: toolchain
	@set -e; \
	for spec in $(SPEC_FILES); do \
		ENV=TEST bin/mruby $$spec; \
	done

toolchain: $(TOOLCHAIN_STAMP)

$(TOOLCHAIN_STAMP): $(BUILD_CONFIG) mrbgem.rake $(RUBY_SOURCES)
	mkdir -p tmp bin
	$(RAKE) -C $(MRUBY_DIR) -f Rakefile clean 2>/dev/null || true
	BUILD_PROFILE=$(BUILD_PROFILE) $(RAKE) -C $(MRUBY_DIR) -f Rakefile MRUBY_CONFIG=$$(pwd)/$(BUILD_CONFIG)
	cp -r $(BUILD_DIR)/bin/* bin/
	touch $(TOOLCHAIN_STAMP)

clean:
	rm -f $(TOOLCHAIN_BIN)
	rm -f tmp/toolchain.*.stamp

distclean: clean
	rm -rf $(BUILD_DIR)
