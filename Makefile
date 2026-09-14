DOCKERHUB_IMAGE := zetneteork/tor-obfs4-bridge
GHCR_IMAGE      := ghcr.io/zetneteork/docker-tor-obfs4-bridge

# Read the current version from export.sh (the single source of truth for
# the most recently released version).  Can always be overridden on the CLI:
#   make build VERSION=0.4.9.12-1-d13.trixie-1
VERSION ?= $(shell . ./export.sh 2>/dev/null && echo "$$VERSION")

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	    awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Code quality
# ---------------------------------------------------------------------------

.PHONY: lint
lint: ## Run shellcheck + hadolint
	shellcheck start-tor.sh get-bridge-line docker_start.sh export.sh scripts/*.sh
	@if command -v hadolint >/dev/null 2>&1; then \
	    hadolint Dockerfile; \
	else \
	    echo "hadolint not installed locally – skipped (runs in CI)"; \
	fi

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

.PHONY: test
test: test-unit test-bats ## Run all tests

.PHONY: test-unit
test-unit: ## Run scripts/test-release-plan.sh unit tests
	bash scripts/test-release-plan.sh

.PHONY: test-bats
test-bats: ## Run bats shell tests (requires bats-core)
	@if command -v bats >/dev/null 2>&1; then \
	    bats tests/start-tor.bats tests/get-bridge-line.bats; \
	else \
	    echo "bats not installed locally – skipped (runs in CI)"; \
	fi

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------

.PHONY: build
build: ## Build the Docker image (tagged as IMAGE:latest)
	docker build \
	    --build-arg IMAGE_VERSION="$(VERSION)" \
	    --build-arg IMAGE_REVISION="$$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
	    --build-arg IMAGE_CREATED="$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
	    -t $(DOCKERHUB_IMAGE) \
	    -t $(GHCR_IMAGE) \
	    .

.PHONY: smoke
smoke: ## Build and run a quick smoke test (requires Docker)
	docker build -t $(DOCKERHUB_IMAGE):smoke-test .
	docker run -d --name tor-smoke-test \
	    -e OR_PORT=12345 -e PT_PORT=12346 \
	    -e EMAIL=test@example.com \
	    -e TOR_OR_PORT_IPV4=1 \
	    -e TOR_EXITRELAY=0 -e TOR_BRIDGERELAY=1 \
	    $(DOCKERHUB_IMAGE):smoke-test
	sleep 10
	docker logs tor-smoke-test
	docker inspect -f '{{.State.Running}}' tor-smoke-test | grep -q true
	docker stop tor-smoke-test
	docker rm tor-smoke-test

# ---------------------------------------------------------------------------
# Tag & push
# ---------------------------------------------------------------------------

.PHONY: tag
tag: ## Tag the built image with VERSION (and latest)
	@[ "$(VERSION)" ] || ( echo "VERSION is not set."; exit 1 )
	docker tag $(DOCKERHUB_IMAGE) $(DOCKERHUB_IMAGE):$(VERSION)
	docker tag $(DOCKERHUB_IMAGE) $(DOCKERHUB_IMAGE):latest
	docker tag $(GHCR_IMAGE) $(GHCR_IMAGE):$(VERSION)
	docker tag $(GHCR_IMAGE) $(GHCR_IMAGE):latest

.PHONY: push-dockerhub
push-dockerhub: tag ## Push to Docker Hub
	@[ "$(VERSION)" ] || ( echo "VERSION is not set."; exit 1 )
	docker push $(DOCKERHUB_IMAGE):$(VERSION)
	docker push $(DOCKERHUB_IMAGE):latest

.PHONY: push-ghcr
push-ghcr: tag ## Push to GitHub Container Registry
	@[ "$(VERSION)" ] || ( echo "VERSION is not set."; exit 1 )
	docker push $(GHCR_IMAGE):$(VERSION)
	docker push $(GHCR_IMAGE):latest

.PHONY: release
release: push-dockerhub push-ghcr ## Push to both registries (alias)

# ---------------------------------------------------------------------------
# Local deploy (legacy – still works alongside make release)
# ---------------------------------------------------------------------------

.PHONY: deploy
deploy: ## Run the container locally
	@[ "$(OR_PORT)" ] || ( echo "OR_PORT is not set."; exit 1 )
	@[ "$(PT_PORT)" ] || ( echo "PT_PORT is not set."; exit 1 )
	@[ "$(EMAIL)" ]   || ( echo "EMAIL is not set.";   exit 1 )
	docker run \
	    --detach \
	    -it \
	    --name=tor_bridge \
	    --env "OR_PORT=$(OR_PORT)" \
	    --env "PT_PORT=$(PT_PORT)" \
	    --env "EMAIL=$(EMAIL)" \
	    --env "TOR_OR_PORT_IPV4=$(TOR_OR_PORT_IPV4)" \
	    --env "TOR_EXITRELAY=$(TOR_EXITRELAY)" \
	    --env "TOR_BRIDGERELAY=$(TOR_BRIDGERELAY)" \
	    --publish "$(OR_PORT):$(OR_PORT)" \
	    --publish "$(PT_PORT):$(PT_PORT)" \
	    --restart unless-stopped \
	    --volume tor-datadir-$(OR_PORT)-$(PT_PORT):/var/lib/tor \
	    $(DOCKERHUB_IMAGE):latest
	@echo "Make sure ports $(OR_PORT) and $(PT_PORT) are forwarded in your firewall."

# ---------------------------------------------------------------------------
# Helm chart lint (convenience target for contributors)
# ---------------------------------------------------------------------------

.PHONY: helm-lint
helm-lint: ## Lint the tor-obfs4-bridge Helm chart (requires helm)
	@if command -v helm >/dev/null 2>&1; then \
	    helm lint /home/i314866/git/github/helm/charts/tor-obfs4-bridge 2>/dev/null \
	    || helm lint ../helm/charts/tor-obfs4-bridge 2>/dev/null \
	    || echo "Helm chart not found at expected paths."; \
	else \
	    echo "helm not installed – skipped"; \
	fi
