# Use an official OCaml image with opam
FROM ocaml/opam:ubuntu-24.04-ocaml-5.2

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Fix permissions for the opam user
RUN sudo chown -R opam:opam /app

# Install system dependencies
RUN sudo apt-get update && sudo apt-get install -y \
    make \
    m4 \
    menhir \
    && sudo rm -rf /var/lib/apt/lists/*

# Initialize opam and update environment
RUN opam init --disable-sandboxing --auto-setup \
    && eval $(opam env) \
    && opam update

# Install Dune 3.20.2
RUN opam install dune=3.20.2 --yes

# Install project dependencies from fatality.opam
RUN opam install . --deps-only --yes

# Build the project with Dune
RUN eval $(opam env) && dune build

# Default command: run the program with grammar/first.grm
CMD ["dune", "exec", "./bin/main.exe", "./grammar/first.grm"]