; slen - Used to calculate strlen
; int slen(char msg)

slen:
        push    ebx             ;
        mov     ebx, eax

next:
        cmp     byte [eax], 0
        jz      finish
        inc     eax
        jmp     next

finish:
        sub     eax, ebx
        pop     ebx
        ret

; sprint - Used to write some text to STDOUT
; int sprint(char msg)

sprint:
        ; Preserving registers value in a stack so they don't get overwritten.
        push    edx
        push    ecx
        push    ebx
        push    eax

        ; Initially, eax contains the memory address of the data needs to ouputed to the STDOUT and we also have to store the
        ; returned value from the slen function. So, we save the value in the stack and then save the slen data and mov it to
        ; appropriate register.
        ; Call the slen function and then the returned value is stored in eax register, we will then mov it to the
        ; edx register and then pop eax from stack giving us the original memory address of the string and then
        ; everything works as normal, regular priniting stuff.
        call    slen
        mov     edx, eax        ; moving it from eax to edx as a paramter for the syscall
        pop     eax             ; Now, the original value of the register is brought back from the stack

        mov     ecx, eax        ; Move the data address to ecx as a paramter for syscall
        mov     ebx, 1          ; File Descriptor (1 - STDOUT)
        mov     eax, 4          ; Syscall number for SYS_WRITE
        int     80h             ; Create an interrupt and handing process to kernel for execution

        pop     ebx             ; Restoring all values of the registers
        pop     ecx
        pop     edx
        ret

; sprintl - Used to write some text to STDOUT with line feed character and null?
; void sprintl(char msg)

sprintl:
        call    sprint          ; Print the string normally

        push    eax             ; Preserving the eax register data in stack
        mov     eax, 0Ah        ; Move 0Ah to eax (Line Feed Character)
        push    eax             ; Store it in stack
        mov     eax, esp        ; Get the address from esp (stack pointer)
        call    sprint          ; print the line feed character
        pop     eax             ; remove line feed character from the stack
        pop     eax             ; restore original value of eax register
        ret                     ; return to the parent program

; iprint - Used to print integers (itoa)
; void iprint(int num)

iprint:
        ; Preserving register values in a stack so they don't get overwritten
        push    eax
        push    ecx
        push    edx
        push    esi
        mov     ecx, 0          ; Initializing the ecx (count) reg to 0

divide_loop:
        inc     ecx             ; Increment ecx
        mov     edx, 0          ; Initializing the edx (data) reg to 0
        mov     esi, 10         ; Move 10 to esi
        idiv    esi             ; Divide eax by esi
        add     edx, 48         ; edx contains the remainder, converting int to ascii by adding 48
        push    edx             ; push the ascii character to stack
        cmp     eax, 0          ; compare eax (quotient) to 0, can we divide anymore?
        jnz     divide_loop     ; jump if not zero to the label divide_loop

print_loop:
        dec     ecx             ; counting down the number of bytes
        mov     eax, esp        ; loading the address of the element from the stack (esp - stack pointer) for printing
        call    sprint          ; call the sprint and print the data stored in eax to STDOUT
        pop     eax             ; remove the top element, so esp moves forward
        cmp     ecx, 0          ; are there any bytes that exist on the stack?
        jnz     print_loop      ; if yes, jump to print_loop label

        ; Restoring all the preserved data from the stack
        pop     esi
        pop     edx
        pop     ecx
        pop     eax
        ret

; iprintl - Used to print integers with LF (atoi)
; void iprintl (int num)

iprintl:
        call    iprint         ; Call the iprint function
        push    eax            ; store the resultant data in the stack
        mov     eax, 0Ah       ; move the line feed character to eax
        push    eax            ; push eax to stack
        mov     eax, esp       ; get the address of the top element to eax
        call    sprint         ; print the data to STDOUT
        pop     eax            ; restore the register values
        pop     eax
        ret

; atoi - Used to convert ASCII to integer
; int atoi(char msg)

atoi:
        ; Preserving register values in the stack so they don't get overwritten
        push    ebx
        push    ecx
        push    edx
        push    esi
        mov     esi, eax        ; eax contains the our number to convert
        mov     eax, 0
        mov     ecx, 0

multiply:
        xor     ebx, ebx        ; Clear ebx register
        mov     bl, [esi+ecx]   ; move the first byte in to the lower section of ebx register
        cmp     bl, 48          ; Compare the contents of the bl register with 48
        jl      _finish         ; If the number is lesser than 48, then jump to _finish
        cmp     bl, 57          ; Compare the contents of bl register with 57
        jg      _finish         ; If the number id greater than 57, then also jump to _finish
        ; The main goal for these comparisons is to check if we have any charecter which cannot be converted into an integer
        ; So we just jump straight to _finish label

        sub     bl, 48          ; Converting the contents of bl to integer by subracting 48
        add     eax, ebx        ; add the contents of ebx to eax
        mov     ebx, 10         ; Moving 10 to ebx used to get the place value of the integer
        mul     ebx             ; Getting the place value by multiplying eax by ebx
        inc     ecx             ; Increment our count register
        jmp     multiply

_finish:
        cmp     ecx, 0          ; Compare if the contents of ecx are equal to 0
        je      restore         ; if yes, jump to label restore, marking the end of digits
        mov     ebx, 10         ; Move 10 to ebx, this is used for dividing to go to the next integer of higher place value
        div     ebx             ; Divide the number and store the quotient in eax register (27/10 = 2.7 ~ 2 ,decimals are ignored)

restore:
        ; Restoring all the register values from the stack
        pop     esi
        pop     edx
        pop     ecx
        pop     ebx
        ret

; exit - Used to exit and restore resources
; void exit(int ret)

exit:
        ; It takes the return code from ebx register
        mov     eax, 1          ; Syscall number for SYS_EXIT
        int     80h             ; Interrupt for kernel

