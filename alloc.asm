%include "definitions.mac"
%define increment_size 512

section .bss
heap_start: resq 1
heap_end:   resq 1

section .text

; int init_allocator(void)
; regs: rdi, rsi, rdx
global init_allocator
init_allocator:
    ; get program break
    mov rax, sys_brk
    xor rdi, rdi
    syscall

    ; if rax <= 0 return error
    cmp rax, 0
    jg .allocate_initial
    ret

.allocate_initial:
    mov [heap_start], rax
    lea rdi, [rax + increment_size]
    mov [heap_end], rdi
    mov rax, sys_brk
    syscall
    ret

; void* allocate(size_t size)
; regs: rsi, rdi
global allocate
allocate:
    ; align size by 8
    mov rsi, rdi
    add rsi, 7
    and rsi, ~7

    ; if heap_start + rsi > heap_end
    mov rax, [heap_start]
    mov rdi, [heap_end]
    add rax, rsi
    mov [heap_start], rax
    cmp rax, rdi
    jg .allocate
    ret

.allocate:
    mov rsi, rax
    mov rax, sys_brk
    add rdi, increment_size
    syscall

    cmp rax, 0
    jle .error

    mov [heap_end], rax
    mov rax, rsi
.error:
    ret
