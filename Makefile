NASM=nasm
LD=ld
NASMFLAGS=-felf64 -g
LDFLAGS=-z noseparate-code

.PHONY: all clean

all: wasm
wasm: wasm.o mem.o bufio.o alloc.o lexer.o test_lexer.o
	$(LD) $(LDFLAGS) wasm.o mem.o bufio.o alloc.o lexer.o test_lexer.o -o wasm
wasm.o: wasm.asm
	$(NASM) $(NASMFLAGS) wasm.asm -o wasm.o
mem.o: mem.asm
	$(NASM) $(NASMFLAGS) mem.asm -o mem.o
bufio.o: bufio.asm
	$(NASM) $(NASMFLAGS) bufio.asm -o bufio.o
alloc.o: alloc.asm
	$(NASM) $(NASMFLAGS) alloc.asm -o alloc.o
lexer.o: lexer.asm
	$(NASM) $(NASMFLAGS) lexer.asm -o lexer.o
test_lexer.o: test_lexer.asm
	$(NASM) $(NASMFLAGS) test_lexer.asm -o test_lexer.o
clean:
	rm -f wasm.o mem.o bufio.o alloc.o lexer.o test_lexer.o wasm
