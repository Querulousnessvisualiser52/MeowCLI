APP_NAME    := meowcli
MODULE      := MeowCLI
WEB_DIR     := web
BUILD_DIR   := build

VERSION     ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT      := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME  := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')

LDFLAGS     := -s -w \
               -X '$(MODULE)/internal/app.Version=$(VERSION)' \
               -X '$(MODULE)/internal/app.Commit=$(COMMIT)' \
               -X '$(MODULE)/internal/app.BuildTime=$(BUILD_TIME)'

GO          := go
GOFLAGS     ?=

# ── Phony targets ───────────────────────────────────────────
.PHONY: all build build-all frontend-install frontend-build \
        dev dev-admin serve clean lint test sqlc \
        cross docker

# ── Default ─────────────────────────────────────────────────
all: build-all

# ── Frontend ────────────────────────────────────────────────
frontend-install:
	npm --prefix $(WEB_DIR) install

frontend-build: frontend-install
	npm --prefix $(WEB_DIR) run build:ssg

# ── Go build ────────────────────────────────────────────────
build:
	$(GO) build $(GOFLAGS) -ldflags "$(LDFLAGS)" -o $(BUILD_DIR)/$(APP_NAME) .

build-all: frontend-build build

# ── Dev ─────────────────────────────────────────────────────
serve:
	$(GO) run $(GOFLAGS) -ldflags "$(LDFLAGS)" .

dev-admin:
	npm --prefix $(WEB_DIR) run dev

# ── Quality ─────────────────────────────────────────────────
lint:
	golangci-lint run ./...

test:
	$(GO) test ./... -v -count=1

# ── Codegen ─────────────────────────────────────────────────
sqlc:
	sqlc generate

# ── Cross-compilation ──────────────────────────────────────
PLATFORMS := linux/amd64 linux/arm64 darwin/amd64 darwin/arm64 windows/amd64

cross: frontend-build
	@for platform in $(PLATFORMS); do \
		os=$${platform%/*}; arch=$${platform#*/}; \
		ext=""; [ "$$os" = "windows" ] && ext=".exe"; \
		echo ">> Building $$os/$$arch"; \
		GOOS=$$os GOARCH=$$arch CGO_ENABLED=0 \
			$(GO) build $(GOFLAGS) -ldflags "$(LDFLAGS)" \
			-o $(BUILD_DIR)/$(APP_NAME)-$$os-$$arch$$ext . ; \
	done

# ── Docker ──────────────────────────────────────────────────
DOCKER_IMAGE ?= meowcli
DOCKER_TAG   ?= $(VERSION)

docker:
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) .

# ── Cleanup ─────────────────────────────────────────────────
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(WEB_DIR)/.nuxt $(WEB_DIR)/.output $(WEB_DIR)/dist
