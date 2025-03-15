%include    'stdlib.asm'
%include    'cardtype.asm'

SECTION     .data
inp_msg     db      'Enter card number: ', 0h
err_dig     db      '[Error] Must enter at least 12 digits. Received: ', 0h  ; Error message for wrong digit count
val_msg     db      'Card Number is valid', 0Ah, 0h                         ; Valid card message
inv_msg     db      'Card number is invalid', 0Ah, 0h                       ; Invalid card message

SECTION     .bss
inp_buff    resb    76          ; Reserve 76 bytes for input buffer
                                ; Credit card: 19 digits * 4 bytes = 76 bytes

SECTION     .text
global      _start

_start:                         ; Program entry point
        mov     eax,    inp_msg ; Load address of input message
        call    sprint          ; Print prompt to user
        mov     edx,    76      ; Set buffer size for SYS_READ (match bss)
        mov     ecx,    inp_buff; Load input buffer address
        mov     ebx,    0       ; File descriptor 0 (STDIN)
        mov     eax,    3       ; System call number for SYS_READ
        int     80h             ; Kernel interrupt
        mov     ebx,    eax     ; Save bytes read (17 for 16 digits + newline)
        dec     ebx             ; Adjust for newline (ebx = 16)
        mov     byte [inp_buff + ebx], 0  ; Null-terminate the string
        mov     eax,    inp_buff; Load buffer address for slen
        call    slen            ; Count digits (should return 16)
        mov     edx,    eax     ; Move slen result to edx (digit count)
        push    edx             ; Save length on stack
        cmp     edx,    12      ; Check for at least 12 digits
        jb      .err_dig        ; Jump to error if < 12
        mov     eax,    inp_buff; Get the address from the stack
        call    detect_card_type; Detect and print card type (eax = inp_buff)

        ; Core Luhn's algorithm
        mov     esi,    inp_buff; Load input buffer address
        add     esi,    edx     ; Move to end of digits (edx = length)
        dec     esi             ; Point to last digit
        xor     ecx,    ecx     ; Counter for digit position
        xor     edx,    edx     ; Sum for Luhn calculation

.luhn_loop:
        cmp     ecx,    [esp]   ; Compare counter with length (on stack)
        je      .check_sum      ; If all digits processed, check sum
        movzx   eax,    byte [esi]  ; Load current digit (ASCII)
        sub     eax,    '0'     ; Convert ASCII to integer
        test    ecx,    1       ; Check if position is odd from right (1, 3, 5...)
        jz     .add_digit      ; If odd, skip doubling
        shl     eax,    1       ; Double the digit (even pos from right)
        cmp     eax,    9       ; Check if doubled > 9
        jle     .add_doubled    ; If <= 9, add as is
        sub     eax,    9       ; If > 9, subtract 9

.add_doubled:
        add     edx,    eax     ; Add doubled (or adjusted) digit to sum
        jmp     .next_digit

.add_digit:
        add     edx,    eax     ; Add original digit to sum

.next_digit:
        dec     esi             ; Move to previous digit
        inc     ecx             ; Increment position counter
        jmp     .luhn_loop

.check_sum:
        mov     eax,    edx     ; Move sum to eax
        mov     ebx,    10      ; Divisor
        xor     edx,    edx     ; Clear edx for idiv
        idiv    ebx             ; edx = (sum % 10)
        test    edx,    edx     ; Check if remainder is 0
        jnz     .invalid        ; If not 0, invalid
        jmp     .valid          ; If 0, valid

.valid:
        mov     eax,    val_msg
        call    sprintl         ; Print the valid card message
        jmp     .exit

.invalid:
        mov     eax,    inv_msg
        call    sprintl         ; Print the invalid card message
        jmp     .exit

.err_dig:                       ; Error state for wrong digit count
        pop     edx             ; Restore digit count from stack
        mov     eax,    err_dig ; Load error message address
        call    sprint          ; Print error message
        mov     eax,    edx     ; Load digit count for printing
        call    iprintl         ; Print the digit count
        jmp     .exit           ; Exit after error

.exit:                          ; Clean exit
        pop     edx             ; Clean up stack (length)
        mov     ebx,    0       ; Set return code
        call    exit            ; Terminate program
