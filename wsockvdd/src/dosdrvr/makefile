
!if $d(DEBUG)
TASMDEBUG=/zi
LINKDEBUG=/v
!else
TASMDEBUG=
LINKDEBUG=
!endif

wsockvdd.com:
      tasm  /m3 $(TASMDEBUG) wsockvdd.asm
      tlink /t $(LINKDEBUG) wsockvdd.obj
