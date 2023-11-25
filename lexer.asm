extern getchar

%include "tokens.mac"
%define number_state    1
%define label_def_state 2
%define char_state      3

section .bss

global column
column: resd 1

%define token_buf_size 256
global token_buf
token_buf: resb token_buf_size

section .data

global line
line: dd 1

%define num_cmd_states 11
cmd_states:
db 'p'
dq p_states
db 'd'
dq d_states
db 'j'
dq j_states
db 's'
dq s_states
db 'm'
dq m_states
db 'g'
dq g_states
db 'a'
dq a_states
db 'l'
dq l_states
db 'c'
dq c_states
db 'r'
dq r_states
db 'e'
dq e_states

; push, putchar, putnum
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

; dup, drop, div
d_states:
db 3, 'u', 6, 'r', 7, 'i', 8 ; 0: ['u' => 1, 'r' => 2, 'i' => 3]
db 1, 'p', 8                 ; 1: ['p' => 4]
db 1, 'o', 8                 ; 2: ['o' => 5]
db 1, 'v', 8                 ; 3: ['i' => 6]
db 1, 0, tok_dup             ; 4: emit dup
db 1, 'p', 5                 ; 5: ['p' => 7]
db 1, 0, tok_div             ; 6: emit div
db 1, 0, tok_drop            ; 7: emit drop

; jz, jl, jmp
j_states:
db 3, 'z', 6, 'l', 7, 'm', 8 ; 0: ['z' => 1, 'l' => 2, 'm' => 3]
db 1, 0, tok_jz              ; 1: emit jz
db 1, 0, tok_jl              ; 2: emit jl
db 1, 'p', 2                 ; 3: ['p' => 4]
db 1, 0, tok_jmp             ; 4: emit jmp

; swap, sub, store
s_states:
db 3, 'w', 6, 'u', 7, 't', 8 ; 0: ['w' => 1, 'u' => 2, 't' => 3]
db 1, 'a', 8                 ; 1: ['a' => 4]
db 1, 'b', 8                 ; 2: ['b' => 5]
db 1, 'o', 8                 ; 3: ['o' => 6]
db 1, 'p', 8                 ; 4: ['p' => 7]
db 1, 0, tok_sub             ; 5: emit sub
db 1, 'r', 5                 ; 6: ['r' => 8]
db 1, 0, tok_swap            ; 7: emit swap
db 1, 'e', 2                 ; 8: ['e' => 9]
db 1, 0, tok_store           ; 9: emit store

; mul, mod
m_states:
db 2, 'u', 4, 'o', 5 ; 0: ['u' => 1, 'o' => 2]
db 1, 'l', 5         ; 1: ['l' => 3]
db 1, 'd', 5         ; 2: ['d' => 4]
db 1, 0, tok_mul     ; 3: emit mul
db 1, 0, tok_mod     ; 4: emit mod

; getchar, getnum
g_states:
db 1, 'e', 2         ; 0: ['e' => 1]
db 1, 't', 2         ; 1: ['t' => 2]
db 2, 'c', 4, 'n', 5 ; 2: ['c' => 3, 'n' => 4]
db 1, 'h', 5         ; 3: ['h' => 5]
db 1, 'u', 5         ; 4: ['u' => 6]
db 1, 'a', 5         ; 5: ['a' => 7]
db 1, 'm', 5         ; 6: ['m' => 8]
db 1, 'r', 5         ; 7: ['r' => 9]
db 1, 0, tok_getnum  ; 8: emit getnum
db 1, 0, tok_getchar ; 9: emit getchar

; add
a_states:
db 1, 'd', 2     ; 0: ['d' => 1]
db 1, 'd', 2     ; 1: ['d' => 2]
db 1, 0, tok_add ; 2: emit add

; load
l_states:
db 1, 'o', 2      ; 0: ['o' => 1]
db 1, 'a', 2      ; 1: ['a' => 2]
db 1, 'd', 2      ; 2: ['d' => 3]
db 1, 0, tok_load ; 3: emit load

; call
c_states:
db 1, 'a', 2      ; 0: ['a' => 1]
db 1, 'l', 2      ; 1: ['l' => 2]
db 1, 'l', 2      ; 2: ['l' => 3]
db 1, 0, tok_call ; 3: emit call

; ret
r_states:
db 1, 'e', 2     ; 0: ['e' => 1]
db 1, 't', 2     ; 1: ['t' => 2]
db 1, 0, tok_ret ; 2: emit ret

; exit
e_states:
db 1, 'x', 2      ; 0: ['x' => 1]
db 1, 'i', 2      ; 1: ['i' => 2]
db 1, 't', 2      ; 2: ['t' => 3]
db 1, 0, tok_exit ; emit exit

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
    cmp al, '_'
    je .true
    cmp al, 'a'
    jl .false
    je .true
    cmp al, 'z'
    jle .true
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

    ; if number
    cmp r10, number_state
    je .number
    jl .get_state

    ; if label
    cmp r10, label_def_state
    je .label_def

    ; if char
    cmp r10, char_state
    je .char

    ; if cmd
    jmp .cmd_read

.get_state:
    ; if space or comment goto next
    cmp al, 10     ; \n
    je .end_comment
    test bh, bh    ; if comment
    jne .loop
    test di, di    ; if eof
    je .emit_eof
    test bl, bl    ; if space
    jne .loop
    cmp al, ';'
    je .start_comment
    cmp al, '1'
    jl .not_number
    je .begin_number_state
    cmp al, '9'
    jle .begin_number_state
.not_number:
    cmp al, "'"
    je .begin_char_state

    mov rdi, cmd_states
    lea rcx, [rdi + num_cmd_states * 9]
.try_get_cmd_state:
    cmp al, [rdi]
    je .begin_cmd_state
    add rdi, 9
    cmp rdi, rcx
    jl .try_get_cmd_state
    jmp .begin_label_def

.begin_cmd_state:
    mov r10, [rdi + 1]
    jmp .loop

.start_comment:
    xor r12, r12 ; token length = 0
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

    ; we can't go to any edge,
    ; so current token is either label or label definition
    xor ebx, ebx ; is_from_cmd = 0, is_space = 0
    inc bh       ; is_from_cmd = 1
    or rbx, r11  ; restore is_space
    mov r10, label_def_state
    jmp .label_def

.next_cmd_state:
    mov bl, [r10 + 1] ; next state diff
    add r10, rbx
    jmp .loop

.try_emit_cmd_token:
    test r11, r11
    jne .emit_cmd_token
    mov r10, label_def_state
    inc bh ; is_from_cmd = 1
    jmp .label_def
.emit_cmd_token:
    mov bl, [r10 + 1]
    jmp .emit_token ; if is_space

.begin_number_state:
    mov r10, number_state
    jmp .loop

.number:
    test bl, bl
    je .check_if_num
    mov bl, tok_number
    jmp .emit_token ; TODO: atoi
.check_if_num:
    cmp al, '0'
    jl .ret_err_wrong_token
    je .loop
    cmp al, '9'
    jg .ret_err_wrong_token
    jmp .loop

.begin_label_def:
    call is_alpha
    test bl, bl
    je .ret_err_wrong_token
    mov r10, label_def_state
    jmp .loop

.begin_char_state:
    mov r10, char_state
    jmp .loop

.char:
    cmp r12, 3
    jg .ret_err_wrong_token
    je .try_emit_char
    jmp .loop
    
.try_emit_char:
    cmp al, "'"
    jne .ret_err_wrong_token
    mov bl, tok_number ; TODO: return ascii code
    jmp .emit_token

.label_def:
    ; check if space
    test bl, bl
    je .check_if_alphanum
    mov bl, tok_label
    jmp .emit_token

.check_if_alphanum:
    mov r11, rbx ; save is_from_cmd
    xor bh, bh ; is_from_cmd = 0
    call is_alphanum
    test bl, bl
    jne .loop

    ; if is_from_cmd
    test r11, r11
    jne .ret_err_wrong_token

    cmp al, ':'
    jne .ret_err_wrong_token
    mov bl, tok_label_def
    jmp .emit_token

.emit_eof:
    xor bl, bl
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
