IMAGE=zetneteork/docker-obfs4-bridge
AIMAGE=phwinter/obfs4-bridge

.PHONY: tag
tag:
	@[ "${VERSION}" ] || ( echo "Env var VERSION is not set."; exit 1 )
	docker tag $(IMAGE) $(IMAGE):$(VERSION)
	docker tag $(IMAGE) $(IMAGE):latest

.PHONY: release
release:
	@[ "${VERSION}" ] || ( echo "Env var VERSION is not set."; exit 1 )
	docker push $(IMAGE):$(VERSION)
	docker push $(IMAGE):latest

.PHONY: build
build:
	docker build -t $(IMAGE) .

.PHONY: deploy
deploy:
	@[ "${OR_PORT}" ] || ( echo "Env var OR_PORT is not set."; exit 1 )
	@[ "${PT_PORT}" ] || ( echo "Env var PT_PORT is not set."; exit 1 )
	@[ "${EMAIL}" ] || ( echo "Env var EMAIL is not set."; exit 1 )
	@docker run \
		--detach \
		-it \
		--name=tor_bridge \
		--env "OR_PORT=$(OR_PORT)" \
		--env "PT_PORT=$(PT_PORT)" \
		--env "EMAIL=$(EMAIL)" \
		--publish "$(OR_PORT)":"$(OR_PORT)" \
		--publish "$(PT_PORT)":"$(PT_PORT)" \
		--restart unless-stopped \
		--volume tor-datadir-$(OR_PORT)-$(PT_PORT):/var/lib/tor \
		$(IMAGE):latest
	@echo "Make sure that port $(OR_PORT) and $(PT_PORT) are forwarded in your firewall."
