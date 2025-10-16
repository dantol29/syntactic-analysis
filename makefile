EXEC               := main.exe
EXEC_PATH          := _build/default/bin/$(EXEC)
GRAMMAR_FILE       := grammar/first.grm

DUNE               := dune
DOCKER             := docker
IMAGE_NAME         := syntactic-analysis
DEV_IMAGE_NAME     := syntactic-analysis-dev
CONTAINER_NAME     := syntactic-analysis-container

DOCKER_RUN_OPTS    := --rm -it --name $(CONTAINER_NAME)
MOUNT_WORKSPACE    := -v $(PWD):/workspace -w /workspace
MOUNT_GRAMMAR      := -v $(PWD)/grammar:/app/grammar:ro

shell: dev-image
	$(DOCKER) run $(DOCKER_RUN_OPTS) $(MOUNT_WORKSPACE) $(DEV_IMAGE_NAME) /bin/bash

all: shell

build:
	$(DUNE) build

run:
	$(DUNE) exec -- ./bin/$(EXEC) $(GRAMMAR_FILE)

test:
	$(DUNE) runtest

clean:
	$(DUNE) clean
	rm -rf _build

install:
	opam install . --deps-only -y

dev-image:
	$(DOCKER) build --target build -t $(DEV_IMAGE_NAME) .

docker-build:
	$(DOCKER) build -t $(IMAGE_NAME) .

docker-run: docker-build
	@test -f "$(GRAMMAR_FILE)" || { echo "Error: '$(GRAMMAR_FILE)' not found on host."; exit 1; }
	$(DOCKER) run $(DOCKER_RUN_OPTS) $(MOUNT_GRAMMAR) $(IMAGE_NAME) /app/$(GRAMMAR_FILE)

docker-shell: docker-build
	$(DOCKER) run $(DOCKER_RUN_OPTS) --entrypoint /bin/bash $(IMAGE_NAME)

docker-clean:
	-$(DOCKER) rm -f $(CONTAINER_NAME)
	-$(DOCKER) image rm $(IMAGE_NAME)
	-$(DOCKER) image rm $(DEV_IMAGE_NAME)

docker-clean-all:
	-$(DOCKER) container prune -f
	-$(DOCKER) image prune -a -f
	-$(DOCKER) volume prune -f
	-$(DOCKER) network prune -f

.PHONY: all help shell build run test clean install \
        dev-image docker-build docker-run docker-shell \
        docker-clean docker-clean-all
