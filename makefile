# ---------- Konfiguration ----------
EXEC               := main.exe
GRAMMAR_FILE       := grammar/main.grm
IMAGE_NAME         := syntactic-analysis
DEV_IMAGE_NAME     := syntactic-analysis-dev
CONTAINER_NAME     := syntactic-analysis-container

DOCKER             := docker
DOCKER_RUN_OPTS    := --rm -it --name $(CONTAINER_NAME)
XSOCK              := /tmp/.X11-unix
XAUTH              := $(HOME)/.Xauthority

# ---------- Targets ----------

# Default: baue & starte X11-Version direkt
all: docker-run-x11

# ---------- Local build ----------
build:
	dune build

run:
	dune exec -- ./bin/$(EXEC) $(GRAMMAR_FILE)

test:
	dune runtest

clean:
	dune clean
	rm -rf _build

install:
	opam install . --deps-only -y

# ---------- Docker build stages ----------
dev-image:
	$(DOCKER) build --target build -t $(DEV_IMAGE_NAME) .

docker-build:
	$(DOCKER) build -t $(IMAGE_NAME) .

# ---------- Docker run ----------
docker-run-x11: docker-build
	@test -f "$(GRAMMAR_FILE)" || { echo "Error: '$(GRAMMAR_FILE)' not found."; exit 1; }
	@echo "🚀 Starting SDL/X11 container..."
	$(DOCKER) run $(DOCKER_RUN_OPTS) \
		--network host \
		-e SDL_VIDEODRIVER=x11 \
		-e DISPLAY=$(DISPLAY) \
		-e XAUTHORITY=/home/appuser/.Xauthority \
		-v $(HOME)/.Xauthority:/home/appuser/.Xauthority:ro \
		-v $(PWD)/grammar:/app/grammar:ro \
		$(IMAGE_NAME) /app/$(GRAMMAR_FILE)

# ---------- Utilities ----------
shell: dev-image
	$(DOCKER) run $(DOCKER_RUN_OPTS) -v $(PWD):/workspace -w /workspace $(DEV_IMAGE_NAME) /bin/bash

docker-clean:
	-$(DOCKER) rm -f $(CONTAINER_NAME)
	-$(DOCKER) image rm $(IMAGE_NAME)
	-$(DOCKER) image rm $(DEV_IMAGE_NAME)

docker-clean-all:
	-$(DOCKER) container prune -f
	-$(DOCKER) image prune -a -f
	-$(DOCKER) volume prune -f
	-$(DOCKER) network prune -f

.PHONY: all build run test clean install \
        dev-image docker-build docker-run-x11 shell \
        docker-clean docker-clean-all
