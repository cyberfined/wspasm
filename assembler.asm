%include "definitions.mac"
%include "htable.mac"
%include "tokens.mac"

extern fwrite
extern htable_insert
extern htable_lookup
extern next_token
extern exit
extern fd_out
extern fflush
extern line
extern column

section .bss

num_buf: resb 70

section .data

lexer_errors:
dq wrong_token_str
db 11
dq token_too_long_str
db 17
dq io_err
db 8
dq number_too_big_str
db 17

wrong_token_str: db "wrong token"
token_too_long_str: db "token is too long"
io_err: db "io error"
number_too_big_str: db "number is too big"

htable_errors:
dq labels_limit_exceeded
db 21
dq duplicated_label_str
db 16

labels_limit_exceeded: db "labels limit exceeded"
duplicated_label_str: db "duplicated label"

%define wrong_argument_str_size 14
wrong_argument_str: db "wrong argument"

%define label_not_found_str_size 15
label_not_found_str: db "label not found"

%define at_str_size 4
at_str: db " at "

; struc command
;     cmd: resb 4
;     len: resb 1
;     arg: resb 1 ; [0 - no arg, 1 - label, 2 - number]
; endstruc

%define no_arg 0
%define arg_l tok_label
%define arg_n tok_number

commands:
db 32, 10, 32, 0, 3, no_arg ; dup [space][lf][space]
db 10, 9, 32, 0, 3, arg_l   ; jz [lf][tab][space]
db 10, 9, 9, 0, 3, arg_l    ; jl [lf][tab][tab]
db 10, 32, 10, 0, 3, arg_l  ; jmp [lf][space][lf]
db 10, 32, 32, 0, 3, no_arg ; define label [lf][space][space]
db 32, 10, 9, 0, 3, no_arg  ; swap [space][lf][tab]
db 32, 10, 10, 0, 3, no_arg ; drop [space][lf][lf]
db 9, 32, 32, 32, 4, no_arg ; add [tab][space][space][space]
db 9, 32, 32, 9, 4, no_arg  ; sub [tab][space][space][tab]
db 9, 32, 32, 10, 4, no_arg ; mul [tab][space][space][lf]
db 9, 32, 9, 32, 4, no_arg  ; div [tab][space][tab][space]
db 9, 32, 9, 9, 4, no_arg   ; mod [tab][space][tab][tab]
db 32, 32, 0, 0, 2, arg_n   ; push [space][space]
db 9, 9, 32, 0, 3, no_arg   ; store [tab][tab][space]
db 9, 9, 9, 0, 3, no_arg    ; load [tab][tab][tab]
db 10, 32, 9, 0, 3, arg_l   ; call [lf][space][tab]
db 10, 9, 10, 0, 3, no_arg  ; ret [lf][tab][lf]
db 10, 10, 10, 0, 3, no_arg ; exit [lf][lf][lf]
db 9, 10, 32, 32, 4, no_arg ; putchar [tab][lf][space][space]
db 9, 10, 9, 32, 4, no_arg  ; getchar [tab][lf][tab][space]
db 9, 10, 32, 9, 4, no_arg  ; putnum [tab][lf][space][tab]
db 9, 10, 9, 9, 4, no_arg   ; getnum [tab][lf][tab][tab]

section .text

; void print_num(uint number)
print_num:
    mov r11, num_buf
    mov rsi, r11
    mov ebx, 10
.loop:
    xor rdx, rdx
    idiv ebx
    add dl, '0'
    mov [r11], dl
    inc r11
    test eax, eax
    jne .loop

    lea rdi, [r11 - 1]
.reverse:
    cmp rsi, rdi
    jge .print
    mov al, [rsi]
    xchg al, [rdi]
    mov [rsi], al
    inc rsi
    dec rdi
    jmp .reverse

.print:
    mov [r11], cl
    mov rdi, num_buf
    lea rsi, [r11 + 1]
    sub rsi, rdi
    call fwrite
    ret

; signed number to whitespace
snum_to_ws:
    cmp rsi, 0
    jl .negative
    je unum_to_ws

    mov cl, 32 ; [space]
    jmp .write_sign
.negative:
    mov cl, 9 ; [tab]
    neg rsi

.write_sign:
    mov [rdi], cl
    inc rdi

; unsigned number to whitespace
unum_to_ws:
    xor cl, cl
    test rsi, rsi
    je .zero ; bsr on zero is undefined
    bsr rcx, rsi ; cl = log2 (rsi)

.loop:
    mov rbx, 1
    shl rbx, cl
    and rbx, rsi
    test rbx, rbx
    jne .one

    ; zero
.zero:
    mov bl, 32 ; [space]
    jmp .condition
.one:
    mov bl, 9 ; [tab]

.condition:
    mov [rdi], bl
    inc rdi
    dec cl
    jge .loop

    ; write number to file
    mov [rdi], byte 10 ; [lf] must be at the end of label and number
    inc rdi
    mov rsi, rdi
    mov rdi, num_buf
    sub rsi, rdi
    call fwrite
    ret

global collect_labels
collect_labels:
    ; labels counter
    xor r15, r15
    mov r8d, 1 ; first line
    xor r9d, r9d ; first column
.loop:
    call next_token
    cmp al, 0
    jl .print_lexer_err
    je .exit ; eof

    ; goto next token if it's not a label definition
    cmp al, tok_label_def
    jne .loop

    ; insert label with counter to labels_table
    mov rsi, r15
    call htable_insert
    inc r15
    cmp al, 0
    jl .print_htable_err

    jmp .loop
.exit:
    ret

.print_htable_err:
    mov rdi, htable_errors
    jmp .get_and_print_err

.print_lexer_err:
    mov rdi, lexer_errors

.get_and_print_err:
    inc al
    neg al
    movzx rax, al
    mov rdx, 9
    mul rdx

    ; get error and its length
    lea rdi, [rdi + rax]
    movzx rsi, byte [rdi + 8]
    mov rdi, [rdi]

print_err:
    ; switch bufio to stderr
    mov [fd_out + f_fd], dword stderr
    call fwrite

    ; print at
    mov rdi, at_str
    mov rsi, at_str_size
    call fwrite

    ; print line
    mov eax, [line]
    mov cl, ':'
    call print_num

    ; print column
    mov eax, [column]
    dec eax
    mov cl, 10
    call print_num
    call fflush

    mov rdi, 1
    jmp exit

global assemble
assemble:
    mov r15d, 6
    xor bpl, bpl ; argument
    mov r8d, 1 ; first line
    xor r9d, r9d ; first column
.loop:
    call next_token
    test al, al
    je .exit ; eof

    test bpl, bpl
    je .write_command

    cmp bpl, al
    jne .print_argument_err

    xor bpl, bpl
    cmp al, tok_number
    je .write_number
    inc r12
    jmp .write_label
.write_command:
    mov r13b, al ; save token
    dec al
    mul r15d
    lea rdi, [commands + eax]
    movzx rsi, byte [rdi + 4]
    mov bpl, [rdi + 5]
    call fwrite

    cmp r13b, tok_label_def
    je .write_label
    jmp .loop

.write_number:
    ; rsi is already contain number
    mov rdi, num_buf
    call snum_to_ws
    jmp .loop

.write_label:
    call htable_lookup
    test r13, r13
    je .print_not_found_err

    ; get label number
    movzx rsi, word [r13 + 8]
    mov rdi, num_buf
    call unum_to_ws
    jmp .loop

.exit:
    ret

.print_argument_err:
    mov rdi, wrong_argument_str
    mov rsi, wrong_argument_str_size
    jmp print_err

.print_not_found_err:
    mov [fd_out + f_offset], dword 0
    mov rdi, label_not_found_str
    mov rsi, label_not_found_str_size
    jmp print_err
