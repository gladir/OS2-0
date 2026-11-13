; BIOSCALL.ASM - OS/2-0 : appel d'une interruption du BIOS en mode reel
; depuis le noyau 32 bits (mode protege, pagination active).
;
; Ce code est recopie par OS2KRNL en 0000:7000 (tableau BiosCode de
; OS2KRNL.PAS, produit par : nasm -f bin BIOSCALL.ASM -o BIOSCALL.BIN) et
; appele par CALL 7000h, interruptions masquees.
;
; Bloc de parametres en 0000:7E00 (entree et sortie) :
;   +00 EAX  +04 EBX  +08 ECX  +0C EDX  +10 ESI  +14 EDI
;   +18 ES (mot)      +1A DS (mot)      +1C FLAGS (sortie)
;   +20 numero de l'interruption (octet)
;
; Etapes : sauvegarde de CR0/CR3/CR4, de la GDT, de l'IDT et de ESP ; GDT
; temporaire (code et donnees 16 bits) ; retour en mode reel (PE et PG a
; zero) ; IVT du BIOS (IDT 0, 3FFh) ; PIC replace en 08h/70h, toutes les
; IRQ masquees ; INT n ; puis le chemin inverse : PIC en 20h/28h et
; masques d'origine, mode protege, CR3/CR4/CR0 (pagination), GDT et IDT
; du noyau, ESP.

        org 0x7000

PARM    equ 0x7E00

[bits 32]
entry32:
        pushad
        pushfd
        cli
        mov [save_esp], esp
        sgdt [save_gdtr]
        sidt [save_idtr]
        mov eax, cr0
        mov [save_cr0], eax
        mov eax, cr3
        mov [save_cr3], eax
        mov eax, cr4
        mov [save_cr4], eax
        mov al, [PARM + 0x20]
        mov [intno], al
        lgdt [tgdtr]
        jmp 0x18:pm16

[bits 16]
pm16:
        mov ax, 0x20
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov eax, cr0
        and eax, 0x7FFFFFFE
        mov cr0, eax
        jmp 0x0000:rm

rm:
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov sp, 0x6FF0
        lidt [rmidt]
        ; PIC : masques sauves, bases 08h et 70h, tout masque
        in al, 0x21
        mov [mask1], al
        in al, 0xA1
        mov [mask2], al
        mov al, 0x11
        out 0x20, al
        out 0xA0, al
        mov al, 0x08
        out 0x21, al
        mov al, 0x70
        out 0xA1, al
        mov al, 0x04
        out 0x21, al
        mov al, 0x02
        out 0xA1, al
        mov al, 0x01
        out 0x21, al
        out 0xA1, al
        mov al, 0xFF
        out 0x21, al
        out 0xA1, al
        ; registres
        mov eax, [PARM + 0x00]
        mov ebx, [PARM + 0x04]
        mov ecx, [PARM + 0x08]
        mov edx, [PARM + 0x0C]
        mov esi, [PARM + 0x10]
        mov edi, [PARM + 0x14]
        push word [PARM + 0x1A]
        push word [PARM + 0x18]
        pop es
        pop ds
        db 0xCD                 ; INT n
intno:  db 0x10
        ; resultats (DS peut avoir change)
        push ds
        push ax
        xor ax, ax
        mov ds, ax
        pop ax
        mov [PARM + 0x00], eax
        mov [PARM + 0x04], ebx
        mov [PARM + 0x08], ecx
        mov [PARM + 0x0C], edx
        mov [PARM + 0x10], esi
        mov [PARM + 0x14], edi
        mov [PARM + 0x18], es
        pop word [PARM + 0x1A]
        pushfd
        pop dword [PARM + 0x1C]
        cli
        ; PIC : bases 20h et 28h du noyau, masques d'origine
        mov al, 0x11
        out 0x20, al
        out 0xA0, al
        mov al, 0x20
        out 0x21, al
        mov al, 0x28
        out 0xA1, al
        mov al, 0x04
        out 0x21, al
        mov al, 0x02
        out 0xA1, al
        mov al, 0x01
        out 0x21, al
        out 0xA1, al
        mov al, [mask1]
        out 0x21, al
        mov al, [mask2]
        out 0xA1, al
        ; retour au mode protege
        lgdt [tgdtr]
        mov eax, cr0
        or eax, 1
        mov cr0, eax
        jmp dword 0x08:pm32

[bits 32]
pm32:
        mov ax, 0x10
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov eax, [save_cr3]
        mov cr3, eax
        mov eax, [save_cr4]
        mov cr4, eax
        mov eax, [save_cr0]
        mov cr0, eax
        jmp short flush
flush:
        lgdt [save_gdtr]
        lidt [save_idtr]
        jmp 0x08:back
back:
        mov ax, 0x10
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov esp, [save_esp]
        popfd
        popad
        ret

        align 8
tgdt:   dq 0
        dq 0x00CF9A000000FFFF   ; 08h code 32 bits
        dq 0x00CF92000000FFFF   ; 10h donnees 32 bits
        dq 0x00009A000000FFFF   ; 18h code 16 bits (base 0, 64 Ko)
        dq 0x000092000000FFFF   ; 20h donnees 16 bits
tgdtr:  dw 5 * 8 - 1
        dd tgdt
rmidt:  dw 0x3FF
        dd 0
save_gdtr: dw 0
        dd 0
save_idtr: dw 0
        dd 0
save_esp: dd 0
save_cr0: dd 0
save_cr3: dd 0
save_cr4: dd 0
mask1:  db 0
mask2:  db 0
