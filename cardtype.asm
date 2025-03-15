SECTION     .data
visa_msg    db      'Card type: Visa', 0Ah, 0h           ; Visa message
mc_msg      db      'Card type: MasterCard', 0Ah, 0h     ; MasterCard message
amex_msg    db      'Card type: American Express', 0Ah, 0h  ; Amex message
disc_msg    db      'Card type: Discover', 0Ah, 0h       ; Discover message
unk_msg     db      'Card type: Unknown', 0Ah, 0h        ; Unknown type message

SECTION     .text

detect_card_type:                   ; Card type detection module (non-global)
        push    eax                 ; Preserve registers
        push    ebx                 ; Save buffer pointer

        mov     ebx,    eax         ; ebx = inp_buff address (from caller)
        movzx   eax,    byte [ebx]  ; Load first digit (ASCII)
        sub     eax,    '0'         ; Convert to integer
        cmp     eax,    4           ; Check for Visa (4)
        je      .visa
        cmp     eax,    6           ; Check for Discover (6)
        je      .check_discover
        cmp     eax,    5           ; Check for MasterCard (5)
        je      .check_mastercard
        cmp     eax,    3           ; Check for Amex (3)
        je      .check_amex
        jmp     .unknown            ; None matched

.check_mastercard:                  ; Check second digit for MasterCard (51-55)
        movzx   eax,    byte [ebx + 1]  ; Load second digit
        sub     eax,    '0'         ; Convert to integer
        cmp     eax,    1           ; Check if 51-55
        jl      .unknown
        cmp     eax,    5
        jg      .unknown
        jmp     .mastercard

.check_amex:                        ; Check second digit for Amex (34 or 37)
        movzx   eax,    byte [ebx + 1]  ; Load second digit
        sub     eax,    '0'         ; Convert to integer
        cmp     eax,    4           ; Check for 34
        je      .amex
        cmp     eax,    7           ; Check for 37
        je      .amex
        jmp     .unknown

.check_discover:                    ; Check second digit for Discover (60, 64, 65)
        movzx   eax,    byte [ebx + 1]  ; Load second digit
        sub     eax,    '0'         ; Convert to integer
        cmp     eax,    0           ; Check for 6011
        je      .check_discover_6011
        cmp     eax,    4           ; Check for 644-649
        je      .check_discover_64
        cmp     eax,    5           ; Check for 65
        je      .discover
        jmp     .unknown

.check_discover_6011:               ; Check 6011
        movzx   eax,    byte [ebx + 2]  ; Load third digit
        sub     eax,    '0'
        cmp     eax,    1
        jne     .unknown
        movzx   eax,    byte [ebx + 3]  ; Load fourth digit
        sub     eax,    '0'
        cmp     eax,    1
        je      .discover
        jmp     .unknown

.check_discover_64:                 ; Check 644-649
        movzx   eax,    byte [ebx + 2]  ; Load third digit
        sub     eax,    '0'
        cmp     eax,    4           ; Must be 4
        jl      .unknown
        cmp     eax,    9           ; Up to 649
        jle     .discover
        jmp     .unknown

.visa:                              ; Visa card type
        mov     eax,    visa_msg    ; Load message address
        call    sprintl             ; Print with newline
        jmp     .done

.mastercard:                        ; MasterCard type
        mov     eax,    mc_msg
        call    sprintl
        jmp     .done

.amex:                              ; American Express type
        mov     eax,    amex_msg
        call    sprintl
        jmp     .done

.discover:                          ; Discover type
        mov     eax,    disc_msg
        call    sprintl
        jmp     .done

.unknown:                           ; Unknown card type
        mov     eax,    unk_msg
        call    sprintl
        jmp     .done

.done:                              ; Cleanup and return
        pop     ebx                 ; Restore registers
        pop     eax
        ret                         ; Return to caller
