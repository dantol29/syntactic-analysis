# ---------- Build / Dev stage ----------
FROM ocaml/opam:debian-11-ocaml-4.14 AS build

USER opam
WORKDIR /home/opam/app

RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    m4 pkg-config make menhir bash \
 && sudo rm -rf /var/lib/apt/lists/*

RUN opam update && opam install -y dune.3.20.2

COPY --chown=opam:opam dune-project ./
COPY --chown=opam:opam *.opam ./
RUN opam install -y . --deps-only

COPY --chown=opam:opam . .
RUN sudo chown -R opam:opam /home/opam/app && chmod -R u+rwX /home/opam/app

RUN eval $(opam env) && dune build --release

WORKDIR /workspace
CMD ["/bin/bash"]


# ---------- Runtime stage ----------
FROM debian:11-slim
RUN useradd -m appuser
USER appuser
WORKDIR /app

# Binary only (grammar is mounted later)
COPY --from=build /home/opam/app/_build/default/bin/main.exe /usr/local/bin/syntactic-analysis

ENTRYPOINT ["/usr/local/bin/syntactic-analysis"]
CMD ["/app/grammar/first.grm"]
