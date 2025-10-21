# ---------- Build / Dev stage ----------
FROM ocaml/opam:debian-11-ocaml-4.14 AS build

USER opam
WORKDIR /home/opam/app

# System deps inkl. SDL1.2 dev headers
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    m4 pkg-config make menhir bash libsdl1.2-dev \
 && sudo rm -rf /var/lib/apt/lists/*

# OCaml deps: dune + ocamlsdl (stellt Findlib-Paket "sdl" bereit)
RUN opam update && opam install -y dune.3.20.2 ocamlsdl

# Sichtprüfung: Paket "sdl" muss vorhanden sein
RUN eval $(opam env) && ocamlfind list | grep -E '^sdl($|\.| )' || true

# Projekt-Metadaten und -Abhängigkeiten
COPY --chown=opam:opam dune-project ./
COPY --chown=opam:opam *.opam ./
RUN opam install -y . --deps-only

# Quellcode und Build
COPY --chown=opam:opam . .
RUN sudo chown -R opam:opam /home/opam/app && chmod -R u+rwX /home/opam/app

# Finaler Check + Build
RUN eval $(opam env) && ocamlfind list | grep -E '^sdl($|\.| )'
RUN eval $(opam env) && dune build --release

WORKDIR /workspace
CMD ["/bin/bash"]


# ---------- Runtime stage ----------
FROM debian:11-slim

# SDL1.2 Runtime installieren (als root)
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends libsdl1.2debian; \
    rm -rf /var/lib/apt/lists/*

# Unprivilegierten User anlegen und verwenden
RUN useradd -m -u 1000 appuser
USER appuser
WORKDIR /app

# Binary aus dem Build-Stage kopieren
# Hinweis: Der Pfad zeigt auf das von dune gebaute Executable (main.exe).
# Wir nennen es im Image "fatality" für einen stabilen Namen.
COPY --from=build /home/opam/app/_build/default/bin/main.exe /usr/local/bin/fatality

# Standard-Aufruf: Grammar-Datei kann per Volume gemountet werden
ENTRYPOINT ["/usr/local/bin/fatality"]
CMD ["/app/grammar/main.grm"]
