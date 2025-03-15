%include    'stdlib.asm'
%include    'cardtype.asm'

SECTION     .data
inp_msg     db      'Enter card number: ', 0h
err_dig     db      '[Error] Must enter at least 12 digits. Received: ', 0h  ; Error message for wrong digit count
val_msg     db      'Card Number is valid', 0h                        ; Valid card message
inv_msg     db      'Card number is invalid', 0h                      ; Invalid card message
luhn_db     db      0, 2, 4, 6, 8, 1, 3, 5, 7, 9                      ; Lookup table for doubled digits

SECTION     .bss
inp_buff    resb    20          ; Reserve 20 bytes for input buffer
                                ; Credit card: 19 digits * newline = 20 bytes

SECTION     .text
global      _start

_start:                         ; Program entry point
        push    ebp             ; Save ebp
        mov     ebp,    esp     ; Set up stack frame
        push    ebx             ; Save ebx for safety

        mov     eax,    [ebp + 4] ; Load argc (esp + 4 due to push ebp)
        cmp     eax,    2       ; Check if at least 2 args (program name + card number)
        jb      .stdin_input    ; If less than 2, use STDIN input

        ; Use command-line argument
        mov     eax,    [ebp + 12] ; Load address of argv[1] (esp + 12 due to pushes)
        call    slen            ; Count digits (should return 16)
        mov     edx,    eax     ; Move slen result to edx (digit count)
        push    edx             ; Save length on stack
        jmp     .process_input  ; Skip STDIN block

.stdin_input:
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

.process_input:
        cmp     edx,    12      ; Check for at least 12 digits
        jb      .err_dig        ; Jump to error if < 12
        mov     eax,    [ebp + 12] ; Get the address from the stack (argv[1] or inp_buff)
        call    detect_card_type; Detect and print card type (eax = inp_buff)

        ; Core Luhn's algorithm
        mov     esi,    [ebp + 12] ; Load input buffer address
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
        jz      .add_digit      ; If odd, skip doubling
        movzx   eax,    byte [luhn_db + eax] ; Lookup doubled value
        add     edx,    eax     ; Add the digit and store it in edx register     
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
        div    ebx              ; edx = (sum % 10)
        test    edx,    edx     ; Check if remainder is 0
        jnz     .invalid        ; If not 0, invalid
        jmp     .valid          ; If 0, valid

.valid:
        mov     eax,    val_msg
        call    sprintl         ; Print the valid card message
        xor     ebx,    ebx     ; Return with status code 0
        pop     edx
        pop     ebx
        pop     ebp
        mov     eax, 1
        int     80h

.invalid:
        mov     eax,    inv_msg
        call    sprintl         ; Print the invalid card message
        mov     ebx,    1       ; Return with status code 1 if its invalid
        pop     edx
        pop     ebp
        mov     eax, 1
        int     80h

.err_dig:                       ; Error state for wrong digit count
        pop     edx             ; Restore digit count from stack
        mov     eax,    err_dig ; Load error message address
        call    sprint          ; Print error message
        mov     eax,    edx     ; Load digit count for printing
        call    iprintl         ; Print the digit count
        pop     ebx
        pop     ebp
        mov     eax, 1
        mov     ebx, 1
        int     80h

