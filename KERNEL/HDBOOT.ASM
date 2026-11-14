; HDBOOT.ASM - OS/2-0 : code du secteur d'amorce principal (MBR) d'un
; disque dur installe par INSTALL.EXE.
;
; Assemble une fois (nasm -f bin HDBOOT.ASM -o HDBOOT.BIN) : les 446
; premiers octets sont recopies dans le tableau MbrCode de INSTALL.PAS,
; qui ecrit le secteur 0 du disque avec sa table des partitions.
;
; Le BIOS charge ce secteur en 0000:7C00 (DL = unite). Le code :
;   1. cherche la partition active (80h) de la table des partitions ;
;   2. lit le repertoire de la zone d'amorcage (secteur 1 du disque :
;      'OS20BOOT', nombre d'entrees en +8, entrees de 32 octets en +16 :
;      nom ASCIIZ sur 16 octets, LBA en +16, taille en +20), dont la
;      premiere entree est OS2LDR ;
;   3. charge OS2LDR en 2000:0000 (INT 13h etendue, 64 Ko au plus) ;
;   4. remplit le bloc d'information d'amorcage en 0000:0500 :
;        +00 'OB'  +02 unite  +04 LBA du repertoire (1)  +08 512
;        +0C LBA d'OS2LDR  +10 taille d'OS2LDR
;        +34 'HD' (demarrage d'un disque dur)
;        +38 debut de la partition active  +3C sa taille
;   5. saute en 2000:0000 avec DL = unite (comme OS2BOOT depuis le CD).

        org 0x7C00
        bits 16

start:
        cli
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, 0x7C00
        sti
        cld
        mov [drive], dl
        mov si, msg_boot
        call puts

        ; partition active
        mov si, 0x7C00 + 446
        mov cx, 4
.find:  test byte [si], 0x80
        jnz .got
        add si, 16
        loop .find
        mov si, msg_nopart
        jmp fatal
.got:   mov eax, [si + 8]
        mov [0x538], eax
        mov eax, [si + 12]
        mov [0x53C], eax

        ; INT 13h etendue presente ?
        mov ah, 0x41
        mov bx, 0x55AA
        mov dl, [drive]
        int 0x13
        jc .noext
        cmp bx, 0xAA55
        je .ext
.noext: mov si, msg_noext
        jmp fatal

.ext:   ; repertoire de la zone d'amorcage -> 1000:0000
        mov word [dap_cnt], 1
        mov word [dap_off], 0
        mov word [dap_seg], 0x1000
        mov dword [dap_lba], 1
        call read
        push ds
        mov ax, 0x1000
        mov ds, ax
        cmp dword [0], 0x3032534F     ; 'OS20'
        jne .bad
        cmp dword [4], 0x544F4F42     ; 'BOOT'
        jne .bad
        mov eax, [16 + 16]            ; LBA d'OS2LDR
        mov ebx, [16 + 20]            ; taille
        pop ds
        mov [0x50C], eax
        mov [0x510], ebx
        mov [dap_lba], eax
        add ebx, 511
        shr ebx, 9
        cmp ebx, 127
        jbe .nok
        mov bx, 127
.nok:   mov [dap_cnt], bx
        mov word [dap_off], 0
        mov word [dap_seg], 0x2000
        call read

        ; bloc d'information d'amorcage
        mov word [0x500], 0x424F      ; 'OB'
        mov al, [drive]
        mov [0x502], al
        mov byte [0x503], 0
        mov dword [0x504], 1
        mov dword [0x508], 512
        mov word [0x534], 0x4448      ; 'HD'
        mov dl, [drive]
        xor dh, dh
        jmp 0x2000:0x0000

.bad:   pop ds
        mov si, msg_noarea
        jmp fatal

; lecture INT 13h AH=42h (paquet dap)
read:
        mov si, dap
        mov dl, [drive]
        mov ah, 0x42
        int 0x13
        jc .err
        ret
.err:   mov si, msg_read
        jmp fatal

puts:   lodsb
        or al, al
        jz .done
        mov ah, 0x0E
        mov bx, 7
        int 0x10
        jmp puts
.done:  ret

fatal:  call puts
.halt:  hlt
        jmp .halt

msg_boot   db 'OS/2-0 ', 0
msg_nopart db 'Pas de partition active', 0
msg_noext  db 'INT 13h etendue absente', 0
msg_noarea db "Zone d'amorcage absente", 0
msg_read   db 'Erreur de lecture', 0

drive   db 0
dap     db 16, 0
dap_cnt dw 0
dap_off dw 0
dap_seg dw 0
dap_lba dd 0, 0

        times 446 - ($ - $$) db 0
