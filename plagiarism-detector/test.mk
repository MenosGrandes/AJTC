TEST_DIR := /tmp/plagiarism_make_test
TEST_NORM := /tmp/plagiarism_make_test_normalized

test: build
	@rm -rf $(TEST_DIR) $(TEST_NORM)
	@mkdir -p $(TEST_DIR)
	@printf 'class fn_abc {\n  #val;\n  constructor(x) {\n    this.#val = x;\n  }\n  get() {\n    return this.#val;\n  }\n}\nmodule.exports = { fn_abc };\n' > $(TEST_DIR)/student_a.js
	@printf 'class fn_abc{#val;constructor(x){this.#val=x;}get(){return this.#val;}}\nmodule.exports={fn_abc};\n' > $(TEST_DIR)/student_b.js
	@printf 'class fn_abc {\n  #data;\n  constructor(input) {\n    this.#data = input * 2;\n  }\n  get() {\n    return this.#data / 2;\n  }\n}\nmodule.exports = { fn_abc };\n' > $(TEST_DIR)/student_c.js
	@echo "=== Normalizing ==="
	@mkdir -p $(TEST_NORM)
	@for f in $(TEST_DIR)/*.js; do \
		$(TERSER) "$$f" --no-compress --no-mangle | $(OXFMT) --stdin-filepath "$$f" > $(TEST_NORM)/$$(basename "$$f"); \
	done
	@echo "=== Comparing ==="
	@$(BINARY) --dir $(TEST_NORM) --threshold 50 && echo "FAIL: expected suspicious pairs" && exit 1 || true
	@echo "=== PASS ==="
	@rm -rf $(TEST_DIR) $(TEST_NORM)

TEST_SPACES_DIR := /tmp/plagiarism_spaces_test
TEST_SPACES_NORM := /tmp/plagiarism_spaces_normalized

test-spaces: build
	@rm -rf "$(TEST_SPACES_DIR)" "$(TEST_SPACES_NORM)"
	@mkdir -p "$(TEST_SPACES_DIR)/John Smith" "$(TEST_SPACES_DIR)/Jane Doe"
	@printf 'class fn_x {\n  #val;\n  constructor(x) { this.#val = x; }\n  get() { return this.#val; }\n}\nmodule.exports = { fn_x };\n' > "$(TEST_SPACES_DIR)/John Smith/functions.js"
	@printf 'class fn_x {\n  #val;\n  constructor(x) { this.#val = x; }\n  get() { return this.#val; }\n}\nmodule.exports = { fn_x };\n' > "$(TEST_SPACES_DIR)/Jane Doe/functions.js"
	@echo "=== Normalizing (spaces test) ==="
	@mkdir -p "$(TEST_SPACES_NORM)"
	@find "$(TEST_SPACES_DIR)" -name '*.js' -type f | while read -r f; do \
		rel=$$(realpath --relative-to="$(TEST_SPACES_DIR)" "$$f"); \
		mkdir -p "$(TEST_SPACES_NORM)/$$(dirname "$$rel")"; \
		$(TERSER) "$$f" --no-compress --no-mangle | $(OXFMT) --stdin-filepath "$$f" > "$(TEST_SPACES_NORM)/$$rel"; \
	done
	@echo "=== Comparing (spaces test) ==="
	@$(BINARY) --dir "$(TEST_SPACES_NORM)" --threshold 50 && echo "FAIL: expected suspicious pairs" && exit 1 || true
	@echo "=== PASS (spaces) ==="
	@rm -rf "$(TEST_SPACES_DIR)" "$(TEST_SPACES_NORM)"

test-all: test test-spaces