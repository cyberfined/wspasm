extern next_token
extern token_buf

%include "definitions.mac"
%include "tokens.mac"

section .data

tokens_str:
dq tok_eof_str, 4
dq 0, 0
dq tok_dup_str, 4
dq tok_jz_str, 3
dq tok_jl_str, 3
dq tok_jmp_str, 4
dq 0, 0
dq tok_swap_str, 5
dq tok_drop_str, 5
dq tok_add_str, 4
dq tok_sub_str, 4
dq tok_mul_str, 4
dq tok_div_str, 4
dq tok_mod_str, 4
dq tok_push_str, 5
dq 0, 0
dq tok_store_str, 6
dq tok_load_str, 5
dq tok_call_str, 5
dq tok_ret_str, 4
dq tok_exit_str, 5
dq tok_putchar_str, 8
dq tok_getchar_str, 8
dq tok_putnum_str, 7
dq tok_getnum_str, 7

tok_eof_str: db "eof", 10
tok_dup_str: db "dup", 10
tok_jz_str: db "jz", 10
tok_jl_str: db "jl", 10
tok_jmp_str: db "jmp", 10
tok_swap_str: db "swap", 10
tok_drop_str: db "drop", 10
tok_add_str: db "add", 10
tok_sub_str: db "sub", 10
tok_mul_str: db "mul", 10
tok_div_str: db "div", 10
tok_mod_str: db "mod", 10
tok_push_str: db "push", 10
tok_store_str: db "store", 10
tok_load_str: db "load", 10
tok_call_str: db "call", 10
tok_ret_str: db "ret", 10
tok_exit_str: db "exit", 10
tok_putchar_str: db "putchar", 10
tok_getchar_str: db "getchar", 10
tok_putnum_str: db "putnum", 10
tok_getnum_str: db "getnum", 10
label_str: db "label "
label_def_str: db "label def "
number_str: db "number "

errors_str:
dq err_wrong_token_str, 17
dq err_token_too_long_str, 23
dq err_io_str, 14
dq err_number_too_big_str, 23

err_wrong_token_str: db "err: wrong token", 10
err_token_too_long_str: db "err: token is too long", 10
err_io_str: db "err: io error", 10
err_number_too_big_str: db "err: number is too big", 10 

section .text

; void test_lexer(void)
global test_lexer
test_lexer:
    call next_token
    cmp al, 0
    jl .error

    mov bl, al
    cmp al, tok_label
    jne .check_for_label_def

    mov rsi, label_str
    mov rdx, 6
    jmp .print_token_buf

.check_for_label_def:
    cmp al, tok_label_def
    jne .check_for_number
    mov rsi, label_def_str
    mov rdx, 10
    jmp .print_token_buf

.check_for_number:
    cmp al, tok_number
    jne .print_token_str
    mov rsi, number_str
    mov rdx, 7

.print_token_buf:
    mov r10, rdi

    mov rax, sys_write
    mov rdi, stdout
    syscall

    mov rdx, r10
    mov [token_buf + rdx], byte 10
    inc rdx
    mov rax, sys_write
    mov rdi, stdout
    mov rsi, token_buf
    syscall

    jmp .condition
.print_token_str:
    shl eax, 4
    mov rdi, stdout
    mov rsi, [tokens_str + rax]
    mov rdx, [tokens_str + rax + 8]
    mov rax, sys_write
    syscall

.condition:
    test bl, bl
    jne test_lexer
    ret

.error:
    ; -(al + 1) * 16
    inc al
    neg al
    shl eax, 4

    mov rdi, stderr
    mov rsi, [errors_str + rax]
    mov rdx, [errors_str + rax + 8]
    mov rax, sys_write
    syscall
    mov rax, -1
    ret
