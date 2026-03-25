APP_NAME  := app # Update this to match the directory name under cmd/.
BUILD_DIR := .local/builds
PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64

.PHONY: build clean lint test

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

lint:
	yamllint .
	golangci-lint run
	go mod tidy
	# Replace with "git diff --exit-code go.mod go.sum" after adding dependencies.
	git diff --exit-code go.mod
	if [ -f go.sum ]; then git diff --exit-code go.sum; fi
	govulncheck ./...

test:
	go test -race -count=1 ./...
