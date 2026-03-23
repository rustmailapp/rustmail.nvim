TESTS_DIR := tests
MINIMAL_INIT := $(TESTS_DIR)/minimal_init.lua

.PHONY: test lint fmt

test:
	nvim --headless -u $(MINIMAL_INIT) -c "PlenaryBustedDirectory $(TESTS_DIR)/rustmail/ { minimal_init = '$(MINIMAL_INIT)' }"

lint:
	stylua --check lua/ plugin/ tests/

fmt:
	stylua lua/ plugin/ tests/
