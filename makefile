# ===================================================================
# 🧠 syntactic-analysis — OCaml Project Toolkit
#    → Dev-Container (build stage) + Runtime Docker workflow
# ===================================================================

# --- Variables -----------------------------------------------------
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

# --- Default -------------------------------------------------------
## 🧰 Open the Dev-Container (build-stage shell) with your repo mounted.
shell: dev-image
	$(DOCKER) run $(DOCKER_RUN_OPTS) $(MOUNT_WORKSPACE) $(DEV_IMAGE_NAME) /bin/bash

all: shell


# --- HELP ----------------------------------------------------------
## 💡 Show this interactive help and explain Dev vs Runtime usage.
help:
	@printf "\033[1;96m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"
	@printf " 🧠  \033[1mSYNTAXIC-ANALYSIS BUILD SYSTEM\033[0m  —  Dockerized OCaml toolchain\n"
	@printf "\033[1;96m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n\n"

	@printf "\033[1;94m📦  CONCEPT OVERVIEW\033[0m\n"
	@printf "  • \033[1mDev-Container\033[0m → the \033[36mbuild stage\033[0m of your Dockerfile.\n"
	@printf "    It includes OCaml, opam, dune 3.20.2, menhir, etc. — your full toolchain.\n"
	@printf "    Your local repo is \033[92mmounted into /workspace\033[0m.\n"
	@printf "    Think of it as a lightweight, reproducible development VM.\n\n"
	@printf "  • \033[1mRuntime-Image\033[0m → a minimal container with only your compiled binary.\n"
	@printf "    Ideal for quick testing, CI, or sharing your final executable.\n\n"

	@printf "\033[1;94m🧰  INSIDE THE DEV-CONTAINER\033[0m\n"
	@printf "  (Run \033[1mmake\033[0m to open it, then type these commands inside)\n\n"
	@printf "    \033[36mmake build\033[0m   → dune build\n"
	@printf "    \033[36mmake run\033[0m     → dune exec ./bin/%s %s\n" "$(EXEC)" "$(GRAMMAR_FILE)"
	@printf "    \033[36mmake test\033[0m    → dune runtest\n"
	@printf "    \033[36mmake clean\033[0m   → dune clean\n\n"

	@printf "\033[1;94m🚀  OUTSIDE (HOST-SIDE COMMANDS)\033[0m\n"
	@printf "  • \033[1mmake\033[0m             → open the dev-container shell (toolchain)\n"
	@printf "  • \033[1mmake docker-build\033[0m → build slim runtime image (binary only)\n"
	@printf "  • \033[1mmake docker-run\033[0m   → run slim container with grammar mounted\n"
	@printf "  • \033[1mmake docker-clean\033[0m → remove containers/images\n\n"

	@printf "\033[1;94m📜  GRAMMAR USAGE\033[0m\n"
	@printf "  Host grammars live in \033[92m./grammar\033[0m → mounted into \033[93m/app/grammar (read-only)\033[0m.\n"
	@printf "  The binary expects a path under /app/grammar/... e.g.:\n"
	@printf "    \033[36mmake docker-run GRAMMAR_FILE=grammar/mk1_snes.grm\033[0m\n\n"

	@printf "\033[1;94m🧩  VARIABLE SUMMARY\033[0m\n"
	@printf "  EXEC=%s\n  GRAMMAR_FILE=%s\n  IMAGE_NAME=%s\n  DEV_IMAGE_NAME=%s\n  CONTAINER_NAME=%s\n\n" \
	"$(EXEC)" "$(GRAMMAR_FILE)" "$(IMAGE_NAME)" "$(DEV_IMAGE_NAME)" "$(CONTAINER_NAME)"

	@printf "\033[1;96m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m\n"


# --- LOCAL BUILD TARGETS (run inside Dev-Container) ----------------
## 🧱 Build with Dune.
build:
	$(DUNE) build

## ▶️ Run with Dune and grammar file.
run:
	$(DUNE) exec -- ./bin/$(EXEC) $(GRAMMAR_FILE)

## 🧪 Run test suite.
test:
	$(DUNE) runtest

## 🧹 Clean build artifacts.
clean:
	$(DUNE) clean
	rm -rf _build

## 📦 Install OPAM dependencies.
install:
	opam install . --deps-only -y


# --- DOCKER IMAGE TARGETS (run on host) ----------------------------
## 🧰 Build Dev-Image (Dockerfile build-stage).
dev-image:
	$(DOCKER) build --target build -t $(DEV_IMAGE_NAME) .

## 🏗️ Build slim runtime image.
docker-build:
	$(DOCKER) build -t $(IMAGE_NAME) .

## 🚀 Run runtime image with mounted grammar folder.
docker-run: docker-build
	@test -f "$(GRAMMAR_FILE)" || { echo "Error: '$(GRAMMAR_FILE)' not found on host."; exit 1; }
	$(DOCKER) run $(DOCKER_RUN_OPTS) $(MOUNT_GRAMMAR) $(IMAGE_NAME) /app/$(GRAMMAR_FILE)

## 🐚 Open interactive shell in slim image (debugging).
docker-shell: docker-build
	$(DOCKER) run $(DOCKER_RUN_OPTS) --entrypoint /bin/bash $(IMAGE_NAME)

## 🧼 Clean project-specific containers/images.
docker-clean:
	-$(DOCKER) rm -f $(CONTAINER_NAME)
	-$(DOCKER) image rm $(IMAGE_NAME)
	-$(DOCKER) image rm $(DEV_IMAGE_NAME)

## 💀 Aggressive Docker cleanup (dangling everything).
docker-clean-all:
	-$(DOCKER) container prune -f
	-$(DOCKER) image prune -a -f
	-$(DOCKER) volume prune -f
	-$(DOCKER) network prune -f

.PHONY: all help shell build run test clean install \
        dev-image docker-build docker-run docker-shell \
        docker-clean docker-clean-all
