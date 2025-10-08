EXEC = main.exe
GRAMMAR_FILE = grammar/first.grm
DUNE = dune
DOCKER = docker
IMAGE_NAME = syntactic-analysis
CONTAINER_NAME = syntactic-analysis-container

# Default target: build the Docker image
all: docker-build

# Build the project locally (for debugging without Docker)
build:
	$(DUNE) build

# Run the program in the container with the grammar file
run: docker-run

# Run tests locally (for debugging)
test:
	$(DUNE) runtest

# Clean local build directory
clean:
	$(DUNE) clean
	rm -rf _build

# Install local dependencies
install:
	opam install . --deps-only

# Build the Docker image
docker-build:
	$(DOCKER) build -t $(IMAGE_NAME) .

# Start the container and run the program
docker-run: docker-build
	$(DOCKER) run --rm -it --name $(CONTAINER_NAME) $(IMAGE_NAME)

# Stop and remove the project-specific container and image
docker-clean:
	-$(DOCKER) rm -f $(CONTAINER_NAME)
	-$(DOCKER) image rm $(IMAGE_NAME)

# Remove ALL Docker containers, images, volumes, and networks
docker-clean-all:
	-$(DOCKER) container prune -f
	-$(DOCKER) image prune -a -f
	-$(DOCKER) volume prune -f
	-$(DOCKER) network prune -f

# Phony targets
.PHONY: all build run test clean install docker-build docker-run docker-clean docker-clean-all