%include "htable.mac"

extern token_buf
extern memcpy
extern strcmp
extern allocate
extern print_allocate_error

section .bss

labels_table:
resb 10 * htable_size
resw 1

section .text

; uint32_t jenkins_hash(size_t length)
jenkins_hash:
    xor eax, eax
    xor ebx, ebx
    xor rcx, rcx
.loop:
    cmp rcx, r12
    je .exit_loop

    movzx ebx, byte [token_buf + rcx]
    add eax, ebx
    mov ebx, eax
    shl ebx, 10
    add eax, ebx
    mov ebx, eax
    shr ebx, 6
    xor eax, ebx
    inc rcx
    jmp .loop

.exit_loop:
    mov ebx, eax
    shl ebx, 3
    add eax, ebx
    mov ebx, eax
    shr ebx, 11
    xor eax, ebx
    mov ebx, eax
    shl ebx, 15
    add eax, ebx
    ret

; void* htable_insert(size_t key_length, short value)
; r12 (key_length), rsi (value)
global htable_insert
htable_insert:
    ; check length
    mov bx, [labels_table + ht_size]
    cmp bx, htable_size
    jge .ret_err_limit
    inc bx
    mov [labels_table + ht_size], bx

    ; last character of label def is semicolon,
    ; we insert 0 for correct work of strcmp
    mov byte [token_buf + r12 - 1], 0
    call jenkins_hash

    ; step (ebx) = hash (edx) >> (32 - htable_pow) | 1
    mov ebx, eax
    shr ebx, (32 - htable_pow)
    or bl, 1
    ; idx (ecx) = hash
    mov ecx, eax
    mov r10, 10
    mov r11d, esi
.loop:
    ; idx = (idx + step) & (htable_size - 1)
    add ecx, ebx
    and ecx, htable_size - 1

    mov eax, ecx
    mul r10
    lea r13, [labels_table + ht_buf + eax]
    mov r14, [r13]
    test r14, r14
    je .insert_new
    
    mov rdi, r14
    mov rsi, token_buf
    call strcmp
    test al, al
    je .ret_err_exists
    jmp .loop

.insert_new:
    mov rdi, r12
    call allocate
    cmp rax, 0
    jl print_allocate_error

    mov rdi, rax
    mov [r13], rdi
    mov eax, r11d
    mov [r13 + 8], ax

    mov rsi, token_buf
    mov rdx, r12
    call memcpy

    ret
.ret_err_limit:
    mov al, err_htable_limit_exceed
    ret
.ret_err_exists:
    mov al, err_htable_duplicate
    ret

; void* htable_lookup(size_t key_length)
global htable_lookup
htable_lookup:
    ; last character of label def is semicolon,
    ; we insert 0 for correct work of strcmp
    mov byte [token_buf + r12 - 1], 0
    call jenkins_hash

    ; step (ebx) = hash (edx) >> (32 - htable_pow) | 1
    mov ebx, eax
    shr ebx, (32 - htable_pow)
    or bl, 1
    ; idx (ecx) = hash
    mov ecx, eax
    mov r10, 10
.loop:
    ; idx = (idx + step) & (htable_size - 1)
    add ecx, ebx
    and ecx, htable_size - 1

    mov eax, ecx
    mul r10
    lea r13, [labels_table + ht_buf + eax]
    mov r14, [r13]
    test r14, r14
    je .not_found

    mov rdi, token_buf
    mov rsi, r14
    call strcmp
    test al, al
    je .found
    jmp .loop
.not_found:
    xor r13, r13
.found:
    ret
