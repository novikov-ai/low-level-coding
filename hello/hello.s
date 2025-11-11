.section __TEXT,__text
.globl _main
.align 2

_main:
    // Prologue
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
    // write() system call
    mov    x16, #4                     // system call number for write
    mov    x0, #1                      // file descriptor: stdout
    adrp   x1, L_str@PAGE              // pointer to string (high bits)
    add    x1, x1, L_str@PAGEOFF       // pointer to string (low bits)
    mov    x2, #14                     // string length
    svc    #0x80                       // invoke system call
    
    // exit() system call
    mov    x16, #1                     // system call number for exit
    mov    x0, #0                      // exit status: 0
    svc    #0x80                       // invoke system call
    
    // Epilogue
    ldp    x29, x30, [sp], #16
    ret

.section __TEXT,__cstring
L_str:
    .asciz  "Hello, World!\n"