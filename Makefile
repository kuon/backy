.PHONY: test build clean deps help format

deps:
	mix deps.get

test: build
	mix test

build: deps
	mix compile

compile: deps
	mix compile

clean:
	rm -fr _build deps

format:
	mix format

help:
	@echo "Available targets:"
	@echo "  deps    - Install dependencies"
	@echo "  test    - Run tests"
	@echo "  build   - Compile the project"
	@echo "  clean   - Clean build artifacts"
	@echo "  help    - Show this help message"
