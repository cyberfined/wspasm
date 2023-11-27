NASM=nasm
LD=ld
NASMFLAGS=-felf64
LDFLAGS=-z noseparate-code

.PHONY: all clean

all: wspasm
wspasm: wspasm.o mem.o bufio.o alloc.o lexer.o test_lexer.o htable.o assembler.o
	$(LD) $(LDFLAGS) wspasm.o mem.o bufio.o alloc.o lexer.o htable.o \
		test_lexer.o assembler.o -o wspasm
wspasm.o: wspasm.asm
	$(NASM) $(NASMFLAGS) wspasm.asm -o wspasm.o
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
htable.o: htable.asm
	$(NASM) $(NASMFLAGS) htable.asm -o htable.o
assembler.o: assembler.asm
	$(NASM) $(NASMFLAGS) assembler.asm -o assembler.o
clean:
	rm -f wspasm.o mem.o bufio.o alloc.o lexer.o test_lexer.o htable.o \
		assembler.o wspasm
