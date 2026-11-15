set architecture i386
target remote :1234
break *0x7c00
continue
delete
awatch *(unsigned int*)0x40
continue
continue
continue
continue
info registers eip eax ecx edi esi cs
x/6i $eip-16
continue
info registers eip eax ecx edi esi cs
quit
