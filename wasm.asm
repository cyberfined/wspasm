%include "definitions.mac"

extern memcpy
extern strlen
extern fwrite
extern fflush
extern init_allocator
extern next_token

section .bss

global fd_out
fd_out:
resd 1
resd 1
buf: resb io_buf_size

global fd_in
fd_in:
resd 1
resd 1
resb io_buf_size
resd 1

section .data
%define help_size 47
help: db " <input.wasm> <output.ws>", 10, "whitespace assembler", 10

%define prog_name_size 4
prog_name: db "wasm"

%define usage_size 7
usage: db "Usage: "

%define allocate_error_size 26
allocate_error: db "Failed to allocate memory", 10

%define open_file_error_size 15
open_file_error: db "Failed to open "

%define open_src_file_error_size 27
open_src_file_error: db "Failed to open source file", 10

%define open_dst_file_error_size 32
open_dst_file_error: db "Failed to open destination file", 10

section .text
global _start
_start:
    mov rax, [rsp]
    cmp rax, 3
    jne print_help

    ; init allocator
    call init_allocator
    cmp rax, 0
    jl print_allocate_error

    ; open src file
    mov rax, sys_open
    lea r10, [rsp + 16]
    mov rdi, [r10]
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    cmp rax, 0
    jl print_open_src_file_error
    mov [fd_in], rax

    ; open dst file
    add r10, 8
    mov rax, sys_open
    mov rdi, [r10]
    mov rsi, O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0o644
    syscall
    cmp rax, 0
    jl print_open_dst_file_error
    mov [fd_out], rax

    ; main logic
    call next_token

    ; close dst file

    xor rdi, rdi
    jmp exit
print_help:
    lea rsi, [rsp + 8]
    mov r10, [rsi]

    ; copy usage to buf
    mov rdi, buf
    mov rsi, usage
    mov rdx, usage_size
    call memcpy

    ; copy argv[0] or prog_name to buf
    mov r11, rdi
    mov rdi, r10
    call strlen
    cmp rax, io_buf_size - help_size - usage_size
    mov rdi, r11
    jle use_full_prog_name
    mov rsi, prog_name
    mov rdx, prog_name_size
    jmp copy_prog_name

use_full_prog_name:
    mov rsi, r10
    mov rdx, rax
copy_prog_name:
    call memcpy

    ; copy help
    mov rsi, help
    mov rdx, help_size
    call memcpy

    ; print help
    sub rdi, buf
    mov rdx, rdi
    mov rax, sys_write
    mov rdi, stderr
    mov rsi, buf
    syscall

    mov rdi, 1
    jmp exit

global print_allocate_error
print_allocate_error:
    mov rax, sys_write
    mov rdi, stderr
    mov rsi, allocate_error
    mov rdx, allocate_error_size
    syscall
    mov rdi, 1
    jmp exit

print_open_dst_file_error:
    mov r11, open_dst_file_error
    mov r12, open_dst_file_error_size
    jmp print_open_file_error

print_open_src_file_error:
    mov r11, open_src_file_error
    mov r12, open_src_file_error_size

print_open_file_error:
    mov rdi, [r10]
    call strlen
    cmp rax, io_buf_size - open_file_error_size - 1
    mov rdi, buf
    jle use_full_file_name
    
    ; copy static file error to buf
    mov rsi, r11
    mov rdx, r12
    call memcpy
    mov rax, r12
    jmp print_file_error

use_full_file_name:
    ; copy full file error to buf
    mov rsi, open_file_error
    mov rdx, open_file_error_size
    call memcpy

    mov rdx, rax
    mov rsi, [r10]
    call memcpy
    mov byte [rdi], 10
    add rax, open_file_error_size + 1

print_file_error:
    mov rdx, rax
    mov rax, sys_write
    mov rdi, stderr
    mov rsi, buf
    syscall
    mov rdi, 1

exit:
    mov rax, 60
    syscall
