SECTION     .data
visa_msg    db      'Card type: Visa', 0Ah, 0h           ; Visa message
mc_msg      db      'Card type: MasterCard', 0Ah, 0h     ; MasterCard message
amex_msg    db      'Card type: American Express', 0Ah, 0h  ; Amex message
disc_msg    db      'Card type: Discover', 0Ah, 0h       ; Discover message
unk_msg     db      'Card type: Unknown', 0Ah, 0h        ; Unknown type message

jmp_tbl:                                                 ; Jump table for first digit
        dd      detect_card_type.unknown                                 ; 0
        dd      detect_card_type.unknown                                 ; 1
        dd      detect_card_type.unknown                                 ; 2
        dd      detect_card_type.check_amex                              ; 3
        dd      detect_card_type.visa                                    ; 4
        dd      detect_card_type.check_mastercard                        ; 5
        dd      detect_card_type.check_discover                          ; 6

SECTION     .text

detect_card_type:                   ; Card type detection module
        push    eax                 ; Preserve registers
        push    ebx                 ; Save buffer pointer

        mov     ebx,    eax         ; ebx = inp_buff address (from caller)
        movzx   eax,    byte [ebx]  ; Load first digit (ASCII)
        sub     eax,    '0'         ; Convert to integer
        cmp     eax,    6           ; Check upper bound
        ja      .unknown            ; None matched
        jmp     [jmp_tbl + eax * 4] ; Jump via table

.check_mastercard:                  ; Check second digit for MasterCard (51-55)
        movzx   eax,    byte [ebx + 1]  ; Load second digit
        sub     eax,    '0'         ; Convert to integer
        sub     eax,    1           ; Adjust to 0-4 range (for 51-55)
        cmp     eax,    4           ; Check if ≤ 4 (original 51-55)
        jbe     .mastercard         ; Below or equal to 55
        jmp     .unknown            ; None matched

.check_amex:                        ; Check second digit for Amex (34 or 37)
        movzx   eax,    byte [ebx + 1]  ; Load second digit
        sub     eax,    '0'         ; Convert to integer
        cmp     eax,    4           ; Check for 34
        je      .amex
        cmp     eax,    7           ; Check for 37
        je      .amex
        jmp     .unknown            ; None matched

.check_discover:                    ; Check second digit for Discover (60, 64, 65)
        movzx   edx,    byte [ebx + 1]  ; Load second digit
        sub     edx,    '0'         ; Convert to integer
        cmp     edx,    0           ; Check for 6011
        je      .check_discover_6011
        cmp     edx,    4           ; Check for 644-649
        je      .check_discover_64
        cmp     edx,    5           ; Check for 65
        je      .discover
        jmp     .unknown            ; None matched

.check_discover_6011:               ; Check 6011
        movzx   eax,    byte [ebx + 2]  ; Load third digit
        sub     eax,    '0'         ; Convert to integer
        cmp     eax,    1           ; Check for 1
        jne     .unknown            ; None matched
        cmp     byte [ebx + 3], '1' ; Load fourth digit and check
        je      .discover           ; Matches 6011
        jmp     .unknown            ; None matched

.check_discover_64:                 ; Check 644-649
        movzx   eax,    byte [ebx + 2]  ; Load third digit
        sub     eax,    '0'         ; Convert to integer
        sub     eax,    4           ; Adjust to 0-5 range
        cmp     eax,    5           ; Check 644-649
        jbe     .discover           ; Within range
        jmp     .unknown            ; None matched

.visa:                              ; Visa card type
        mov     eax,    visa_msg    ; Load message address
        jmp     .print              ; Print and exit

.mastercard:                        ; MasterCard type
        mov     eax,    mc_msg      ; Load message address
        jmp     .print              ; Print and exit

.amex:                              ; American Express type
        mov     eax,    amex_msg    ; Load message address
        jmp     .print              ; Print and exit

.discover:                          ; Discover type
        mov     eax,    disc_msg    ; Load message address
        jmp     .print              ; Print and exit

.unknown:                           ; Unknown card type
        mov     eax,    unk_msg     ; Load message address
        
.print:                             ; Consolidated print routine
        call    sprint              ; Print with newline
        pop     ebx                 ; Restore registers
        pop     eax
        ret                         ; Return to caller
