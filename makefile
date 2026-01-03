# Compiler
OCAMLC = ocamlc
SRC    = src
NAME   = ft_ality

SOURCES = $(SRC)/main.ml

OBJS = $(SOURCES:.ml=.cmo)

# Bytecode-Libs
LIBS = unix.cma

.PHONY: all clean re run status

all: $(NAME)

# .ml -> .cmo
$(SRC)/%.cmo: $(SRC)/%.ml
	@echo "Compiling $<..."
	@$(OCAMLC) -I $(SRC) -c $<

$(NAME): $(OBJS)
	@echo "Linking $@..."
	@$(OCAMLC) -I $(SRC) -o $@ $(LIBS) $(OBJS)

clean:
	rm -f $(SRC)/*.cmo $(SRC)/*.cmi $(SRC)/*.cmx $(SRC)/*.o $(NAME)

re: clean all
