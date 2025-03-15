%include    'stdlib.asm'
%include    'cardtype.asm'

SECTION     .data
inp_msg     db      'Enter card number: ', 0h
err_dig     db      '[Error] Must enter atleast 12 digits. Received: ', 0h  ; Error message for wrong digit count

SECTION     .bss
inp_buff    resb    76          ; Reserve 76 bytes for input buffer
                                ; Credit card: 19 digits * 4 bytes = 76 bytes

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
        mov     ebx,    eax     ; Save bytes read
        dec     ebx             ; Adjust for newline
        mov     byte [inp_buff + ebx], 0  ; Null-terminate the string
        mov     eax,    inp_buff; Load buffer address for slen
        push    eax             ; Preserve the original value into the stack
                                ; because the eax register is going to be used by slen
        call    slen            ; Count digits, should be 16
        mov     edx,    eax     ; Move slen result to edx
        pop     eax             ; Restore buffer address
        cmp     edx,    12      ; Check for atleast 12 digits
        jb      .err_dig        ; Jump to error if not the digits are not 12 atleast
        call    detect_card_type; Detect and print card type
        jmp     .exit           ; Exit on success

.err_dig:                       ; Error state for wrong digit count
        mov     eax,    err_dig ; Load error message address
        call    sprint          ; Print error message
        mov     eax,    edx     ; Load digit count for printing
        call    iprintl         ; Print the digit count
        jmp     .exit           ; Exit after error

.exit:                          ; Clean exit
        mov     ebx,    0       ; Set return code
        call    exit            ; Terminate program
