section .text
; void memcpy(void *dest, void *src, size_t n)
global memcpy
memcpy:
    cmp rdx, 8
    jge .ge_8
    jmp .lt_8
.ge_8:
    mov rcx, rdx
    shr rcx, 3
    rep movsq
.lt_8:
    mov rcx, rdx
    and rcx, 7
    rep movsb
    ret

; size_t strlen(const char *str)
global strlen
strlen:
    mov rcx, rdi
.loop:
    test byte [rdi], 0xff
    je .exit
    inc rdi
    jmp .loop
.exit:
    sub rdi, rcx
    mov rax, rdi
    ret
