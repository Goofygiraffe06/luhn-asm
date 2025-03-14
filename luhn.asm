%include    'stdlib.asm'

SECTION     .data
inp_msg     db      'Enter card number: ', 0h

SECTION     .bss
inp_buff    resb    64          ; Reserve 64 bytes for input buffer
                                ; Credit card: 16 digits * 4 bytes = 64 bytes

SECTION     .text
global      _start

_start:                         ; Program entry point
        mov     eax,    inp_msg ; Load address of input message
        call    sprint          ; Print prompt to user

        mov     edx,    64      ; Set buffer size for SYS_READ
        mov     ecx,    inp_buff; Load input buffer address
        mov     ebx,    0       ; File descriptor 0 (STDIN)
        mov     eax,    3       ; System call number for SYS_READ
        int     80h             ; Kernel interrupt

        call    exit            ; Clean program termination
