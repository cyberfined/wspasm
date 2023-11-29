# wspasm

two pass whitespace assembler.

## Usage

```bash
wspasm <input.wspasm> <output.ws>
```

## Build dependencies

1. nasm
2. make

## Build

```bash
make
```

## Examples

Let's write classic Hello world example.

hello.wspasm:
```
; Push "Hello world\n" to the stack

push '\n'
push 'd'
push 'l'
push 'r'
push 'o'
push 'w'
push ' '
push 'o'
push 'l'
push 'l'
push 'e'
push 'H'

push 12 ; string length

loop:
    swap ; swap length with char
    putchar

    ; length -= 1
    push 1
    sub

    ; if (length == 0) exit
    dup
    jz end
    jmp loop

end:
    exit
```

Then translate it to whitespace with

```bash
wspasm hello.wspasm hello.ws
```

resulted file is

```whitespace
[space][space][space][tab][space][tab][space]
[space][space][space][tab][tab][space][space][tab][space][space]
[space][space][space][tab][tab][space][tab][tab][space][space]
[space][space][space][tab][tab][tab][space][space][tab][space]
[space][space][space][tab][tab][space][tab][tab][tab][tab]
[space][space][space][tab][tab][tab][space][tab][tab][tab]
[space][space][space][tab][space][space][space][space][space]
[space][space][space][tab][tab][space][tab][tab][tab][tab]
[space][space][space][tab][tab][space][tab][tab][space][space]
[space][space][space][tab][tab][space][tab][tab][space][space]
[space][space][space][tab][tab][space][space][tab][space][tab]
[space][space][space][tab][space][space][tab][space][space][space]
[space][space][space][tab][tab][space][space]

[space][space][space]
[space]
[tab][tab]
[space][space][space][space][space][tab]
[tab][space][space][tab][space]
[space]
[tab][space][tab]

[space]
[space]

[space][space][tab]


```

Another examples you can see in the examples directory

## Instructions

| Instruction | argument         | description                                                                                                                                                 |
|-------------|------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
| dup         | -                | duplicates top of the stack                                                                                                                                 |
| jz          | label            | jumps to label if top of the stack is 0                                                                                                                     |
| jl          | label            | jumps to label if top of the stack is negative                                                                                                              |
| jmp         | label            | unconditionally jumps to label                                                                                                                              |
| label:      | -                | defines a label. Label name defined with following regexp [A-Za-z_]+[A-Za-z_0-9]*                                                                           |
| swap        | -                | swaps two top elements of the stack                                                                                                                         |
| drop        | -                | drops top of the stack                                                                                                                                      |
| add         | -                | adds two top elements of the stack and puts result to the top of the stack                                                                                  |
| sub         | -                | subtracts two top elements of the stack and puts result to the top of the stack                                                                             |
| div         | -                | divides two top elements of the stack and puts quotient to the top of the stack                                                                             |
| mod         | -                | divides two top elements of the stack and puts remainder to the top of the stack                                                                            |
| push        | number/character | pushes number or character code to the top of the stack. number defines with following regexp -?[0-9]+. character defines with following regexp '\[ntr]\|.' |
| store       | -                | puts number from the top of the stack to the heap by address defined with the second element of the stack                                                   |
| load        | -                | loads number from heap by address defined with the top of the stack and pushes it to the top of the stack                                                   |
| call        | label            | calls a function                                                                                                                                            |
| ret         | -                | returns from a function                                                                                                                                     |
| exit        | -                | terminates execution of the program                                                                                                                         |
| putchar     | -                | removes character from the top of the stack and prints it                                                                                                   |
| getchar     | -                | reads character from stdin and puts it to the heap by address defined with the top of the stack                                                             |
| putnum      | -                | removes number from the top of the stack and prints it                                                                                                      |
| getnum      | -                | reads number from stdin and puts it to the heap by address defined with the top of the stack                                                                |
