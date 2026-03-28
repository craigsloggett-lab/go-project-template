APP_NAME              := app # Update this to match the directory name under cmd/.
BUILD_DIR             := .local/builds
PLATFORMS             := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64
GOLANGCI_LINT_VERSION := v2.11.4
GOVULNCHECK_VERSION   := v1.1.4

.PHONY: all build clean format lint test update

all: lint test build

build:
	@mkdir -p $(BUILD_DIR)
	@for platform in $(PLATFORMS); do \
		os=$${platform%/*}; \
		arch=$${platform#*/}; \
		echo "Building $(APP_NAME)-$${os}-$${arch}"; \
		CGO_ENABLED=0 GOOS=$${os} GOARCH=$${arch} \
			go build -o $(BUILD_DIR)/$(APP_NAME)-$${os}-$${arch} ./cmd/$(APP_NAME); \
	done

clean:
	rm -rf .local/

format:
	go fmt ./...

lint:
	yamllint .
	go run github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION) run ./...
	actionlint
	find . -type f -name '*.sh' \
		-not -path './.git/*' \
		-not -path './.local/*' \
	| while IFS= read -r file; do shellcheck "$${file}"; done
	go mod tidy
	# Replace with "git diff --exit-code go.mod go.sum" after adding dependencies.
	git diff --exit-code go.mod
	if [ -f go.sum ]; then git diff --exit-code go.sum; fi
	go run golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION) ./...

update:
	go get -u
	go mod tidy

test:
	go test -race -count=1 ./...
