IMAGES := sec-forge mesh-router data-streams-producer data-streams-consumer

.PHONY: static build test clean metadata metadata-apply \
	$(addprefix build-,$(IMAGES)) \
	$(addprefix test-,$(IMAGES))

static:
	bash scripts/static-checks.sh

build: $(addprefix build-,$(IMAGES))

$(addprefix build-,$(IMAGES)): build-%:
	docker buildx bake -f docker-bake.hcl $* --load

test: $(addprefix test-,$(IMAGES))

$(addprefix test-,$(IMAGES)): test-%: build-%
	bash scripts/smoke-test.sh $*

metadata:
	pwsh -File ./scripts/update-dockerhub-metadata.ps1

metadata-apply:
	pwsh -File ./scripts/update-dockerhub-metadata.ps1 -Apply

clean:
	docker compose -f images/mesh-router/examples/compose.yml \
		down --remove-orphans || true
	docker compose -f examples/data-streams/compose.yml \
		down --remove-orphans || true
