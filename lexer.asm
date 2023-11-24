extern getchar

%include "tokens.mac"
%define number_state    1
%define label_def_state 2

section .bss

global column
column: resd 1

%define token_buf_size 256
global token_buf
token_buf: resb token_buf_size

section .data

global line
line: dd 1

p_states:
db 1, 'u', 2         ; 0: ['u' => 1]
db 2, 's', 4, 't', 5 ; 1: ['s' => 2, 't' => 3]
db 1, 'h', 7         ; 2: ['h' => 4]
db 2, 'c', 7, 'n', 8 ; 3: ['c' => 5, 'n' => 6]
db 1, 0, tok_push    ; 4: emit push
db 1, 'h', 5         ; 5: ['h' => 7]
db 1, 'u', 5         ; 6: ['u' => 8]
db 1, 'a', 5         ; 7: ['a' => 9]
db 1, 'm', 5         ; 8: ['m' => 10]
db 1, 'r', 5         ; 9: ['r' => 11]
db 1, 0, tok_putnum  ; 10: emit putnum
db 1, 0, tok_putchar ; 11: emit putchar

section .text

; int is_space(char)
is_space:
    mov bl, 1
    cmp al, 9  ; \t
    je .true
    cmp al, 10 ; \n
    je .true
    cmp al, ' '
    je .true
    test di, di
    je .true
.false:
    xor bl, bl
.true:
    ret

; int is_alpha(char)
is_alpha:
    mov bl, 1
    cmp al, 'A'
    jl .false
    je .true
    cmp al, 'Z'
    jle .true
    cmp al, 'a'
    jl .false
    je .true
    cmp al, 'z'
    jle .true
    cmp al, '_'
    je .true
.false:
    xor bl, bl
.true:
    ret

; int is_alphanum(char)
is_alphanum:
    call is_alpha
    test bl, bl
    jne .true
    cmp al, '0'
    jl .false
    je .true
    cmp al, '9'
    jg .false
.true:
    mov bl, 1
.false:
    ret

; (int token, int value) next_token(void)
; regs: rdi, rsi, rdx, rbx, r8, r9, r10, r12
global next_token
next_token:
    ; is comment
    xor bh, bh
    ; line
    mov r8d, [line]
    ; column
    mov r9d, [column]
    ; states array
    xor r10, r10
    ; token length
    xor r12, r12

.loop:
    call getchar
    cmp rdi, 0
    jl .ret_io_error

    ; append char to token if it's not a space
    call is_space
    test bl, bl ; if space
    jne .not_append_char
    test bh, bh ; if comment
    jne .not_append_char
    cmp r12, token_buf_size
    jge .ret_err_token_too_long
    mov [token_buf + r12], al
    inc r12

.not_append_char:
    ; if char == '\n'
    cmp al, 10
    jne .increment_column
    inc r8d
    xor r9d, r9d

.increment_column:
    inc r9d
    cmp r10, number_state
    ; je .number
    jl .get_state

    ; if label
    cmp r10, label_def_state
    je .label_def

    ; if cmd
    jmp .cmd_read

.get_state:
    ; if space or comment goto next
    cmp al, 10     ; \n
    je .end_comment
    test bh, bh    ; if comment
    jne .loop
    test di, di    ; if eof
    je .emit_token ; emit eof
    test bl, bl    ; if space
    jne .loop
    cmp al, ';'
    je .start_comment

    cmp al, 'p'
    je .begin_p_state

    jmp .begin_label_def
.begin_p_state:
    mov r10, p_states
    jmp .loop

.start_comment:
    inc bh
    jmp .loop

.end_comment:
    xor bh, bh
    jmp .loop

.cmd_read:
    mov r11, rbx ; save is_space
    xor rcx, rcx
    ; num edges
    mov cl, [r10]
    inc r10
.next_edge:
    mov bl, [r10]

    ; if bl is zero, than we can emit token
    ; if current character is space or we rich eof
    test bl, bl
    je .try_emit_cmd_token

    ; else we should find next state
    cmp al, bl
    je .next_cmd_state

    add r10, 2
    loop .next_edge
    jmp .label_def

.next_cmd_state:
    mov bl, [r10 + 1] ; next state diff
    add r10, rbx
    jmp .loop

.try_emit_cmd_token:
    test r11, r11
    je .label_def
    mov bl, [r10 + 1]
    jmp .emit_token ; if is_space

.begin_label_def:
    call is_alpha
    test bl, bl
    jne .ret_err_wrong_token
    mov r10, label_def_state
    jmp .loop

.label_def:
    ; check if space
    test bl, bl
    je .check_if_alphanum
    mov bl, tok_label
    jmp .emit_token

.check_if_alphanum:
    call is_alphanum
    test bl, bl
    je .loop

    cmp al, ':'
    jne .ret_err_wrong_token
    mov bl, tok_label_def
    jmp .emit_token

.emit_token:
    mov al, bl    ; return token
    mov rdi, r12  ; return it's length
    jmp .exit

.ret_io_error:
    mov al, err_io
    jmp .exit
.ret_err_token_too_long:
    mov al, err_token_too_long
    jmp .exit
.ret_err_wrong_token:
    mov al, err_wrong_token
.exit:
    mov [line], r8d
    mov [column], r9d
    ret
