.PHONY: lint format build test test-integration test-all coverage install setup-hooks clean

lint:
	swiftlint lint --strict

format:
	swiftformat Sources/ Tests/

format-check:
	swiftformat --lint Sources/ Tests/

build:
	swift build

build-release:
	swift build -c release

test:
	swift test --filter DaemonOSTests

test-integration:
	swift test --filter Integration

test-all:
	swift test

coverage:
	swift test --enable-code-coverage
	@echo "Coverage report:"
	@xcrun llvm-cov report \
		.build/debug/DaemonOSPackageTests.xctest/Contents/MacOS/DaemonOSPackageTests \
		-instr-profile .build/debug/codecov/default.profdata \
		-ignore-filename-regex='.build|Tests'

install: build-release
	cp .build/release/daemon /usr/local/bin/daemon

setup-hooks:
	chmod +x .githooks/pre-commit
	git config core.hooksPath .githooks
	@echo "Git hooks configured."

clean:
	swift package clean
