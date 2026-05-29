THRESHOLD ?= 50
NORMALIZED_DIR ?= /tmp/plagiarism_normalized
STRIP_PREFIX ?=
BINARY := ./target/release/plagiarism-detector
NORMALIZE := node $(CURDIR)/core/normalize.mjs
.PHONY: run build normalize compare clean test test-spaces test-all

run: build normalize compare

build:
	cargo build --release

FILE_PATTERN := $(or $(FILE_NAME),*.js)

normalize:
ifndef DIR
	$(error DIR is required)
endif
	rm -rf $(NORMALIZED_DIR)
	@find "$(DIR)" -name '$(FILE_PATTERN)' -type f -print0 | xargs -0 -P0 -I{} sh -c '\
	rel=$$(realpath --relative-to="$(DIR)" "{}"); \
	mkdir -p "$(NORMALIZED_DIR)/$$(dirname "$$rel")"; \
	$(NORMALIZE) "{}" > "$(NORMALIZED_DIR)/$$rel"'


compare:
ifdef STRIP_PREFIX
	$(BINARY) --dir "$(NORMALIZED_DIR)" --threshold $(THRESHOLD) --strip-prefix "$(STRIP_PREFIX)"
else
	$(BINARY) --dir "$(NORMALIZED_DIR)" --threshold $(THRESHOLD)
endif

clean:
	rm -rf $(NORMALIZED_DIR) target/

include test.mk
