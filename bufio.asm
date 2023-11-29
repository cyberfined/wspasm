%include "definitions.mac"

extern memcpy
extern fd_out
extern fd_in

section .text

; int fwrite(const char *buf, int size)
; regs: rdi, rsi, rdx, rbx, r10
global fwrite
fwrite:
    ; if offset + size > io_buf_size
    mov ebx, [fd_out + f_offset]
    mov r10d, ebx
    add ebx, esi
.loop:
    cmp ebx, io_buf_size
    jg .size_too_big

    ; size fits
    mov [fd_out + f_offset], ebx
    mov edx, esi
    mov rsi, rdi
    lea rdi, [fd_out + f_buf + r10d]
    call memcpy
    ret

.size_too_big:
    ; copy all that we can
    mov edx, io_buf_size
    sub edx, [fd_out + f_offset]
    mov rsi, rdi
    lea rdi, [fd_out + f_buf + r10d]
    call memcpy
    mov r10, rsi
    
    ; write it to the file
    mov rax, sys_write
    mov edi, [fd_out + f_fd]
    mov rsi, fd_out + f_buf
    mov rdx, io_buf_size
    syscall

    ; repeat again
    mov rdi, r10
    sub ebx, io_buf_size
    mov esi, ebx
    xor r10, r10
    mov [fd_out + f_offset], dword 0
    jmp .loop

; void fflush(void)
; regs: rdi, rsi, rdx
global fflush
fflush:
    ; if offset == 0
    mov edx, [fd_out + f_offset]
    test edx, edx
    je .exit

    ; write buffer to file
    mov rax, sys_write
    mov edi, [fd_out + f_fd]
    mov rsi, fd_out + f_buf
    syscall

    mov [fd_out + f_offset], dword 0
.exit:
    ret

; (char chr, int error) getchar(void)
; regs: rdi, rsi, rdx
global getchar
getchar:
    ; if f_size > f_offset
    mov eax, [fd_in + f_size]
    mov edi, [fd_in + f_offset]
    cmp eax, edi
    jg .next_char

    ; read file
    xor rax, rax ; sys_read
    mov edi, [fd_in + f_fd]
    mov rsi, fd_in + f_buf
    mov rdx, io_buf_size
    syscall
    cmp rax, 0
    jl .error
    je .eof

    mov [fd_in + f_size], eax
    xor rdi, rdi

.next_char:
    movzx rax, byte [fd_in + f_buf + rdi]
    inc edi
    mov [fd_in + f_offset], edi
    ret
.error:
    mov rdi, rax
    ret
.eof:
    xor rdi, rdi
    ret

; reset file read position
; void freset(void)
; regs: rsi, rdi, rdx
global freset
freset:
    xor rsi, rsi
    mov [fd_in + f_offset], esi
    mov [fd_in + f_size], esi
    mov rax, sys_lseek
    mov edi, [fd_in + f_fd]
    xor rdx, rdx
    syscall
    ret
