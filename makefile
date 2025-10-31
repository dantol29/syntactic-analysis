# Compiler
OCAMLC = ocamlc
SRC    = src
NAME   = ft_ality

SOURCES = \
	$(SRC)/fsm.ml \
	$(SRC)/main.ml

OBJS = $(SOURCES:.ml=.cmo)

# Bytecode-Libs
LIBS = unix.cma

.PHONY: all clean re run status

all: $(NAME)

# .ml -> .cmo
$(SRC)/%.cmo: $(SRC)/%.ml
	@echo "Compiling $<..."
	@$(OCAMLC) -I $(SRC) -c $<

# Linken (Unix vor OBJS!)
$(NAME): $(OBJS)
	@echo "Linking $@..."
	@$(OCAMLC) -I $(SRC) -o $@ $(LIBS) $(OBJS)

status:
	@if [ -z "`find $(SRC) -name '*.ml' -newer $(NAME) 2>/dev/null`" ]; then \
	  echo "✅ Nothing new to compile, everything is up to date."; \
	else \
	  echo "ℹ️  Some sources are newer than $(NAME). Run 'make'."; \
	fi

run: $(NAME)
	./$(NAME) grammar/main.grm

clean:
	rm -f $(SRC)/*.cmo $(SRC)/*.cmi $(SRC)/*.cmx $(SRC)/*.o $(NAME)

re: clean all
