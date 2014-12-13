
	.text '(C)1987 COMMODORE ELECTRONICS LTD., ALL RIGHTS RESERVED'

*=$ff00
jidle
        jmp  (vidle)    ; IDLE ROUTINE
jirq
	jmp  (virq)	; IRQ VECTOR
jnmi
	jmp  (vnmi)	; NMI VECTOR
jverdir
	jmp  (vverdir)	; Validate
jintdrv
	jmp  (vintdrv)	; Initial Drive
jpart
	jmp  (vpart)	; Partitioning
jmem
	jmp  (vmem)	; MEMORY READ/WRITE/EXECUTE
jblock
	jmp  (vblock)	; BLOCK ALLOCATE/FREE/EXECUTE
juser
	jmp  (vuser)	; USER COMMANDS
jrecord
	jmp  (vrecord)	; RELATIVE FILE RECORD COMMAND
jutlodr
	jmp  (vutlodr)	; UTILITY LOADER
jdskcpy
	jmp  (vdskcpy)	; COPY
jrename
	jmp  (vrename)	; RENAME
jscrtch
	jmp  (vscrtch)  ; SCRATCH
jnew
	jmp  (vnew)	; NEW
error
        jmp  (verror)	; ERROR HANDLER
jatnsrv
        jmp  (vatnsrv)	; ATTENTION SERVER
jtalk
	jmp  (vtalk)	; SERIAL BUS TALK
jlisten
	jmp  (vlisten)	; SERIAL BUS LISTEN
jlcc
	jmp  (vlcc)	; LCC VECTOR
jtrans_ts
	jmp  (vtrans_ts) ; TRACK & SECTOR TRANSLATION
cmder2
	jmp  (vcmder2)  ; CMD ERROR

*=*+18

jstrobe_controller
	jmp  strobe_controller
jcbmboot
	jmp  cbmboot
jcbmbootrtn
	jmp  cbmbootrtn
jsignature
	jmp  signature
jdejavu
	jmp  vujade

newvect				; label

jspinout
	jmp  spinout
jallocbuf
	jmp  allocbuf
jintdsk
	jmp  intdsk
jdumptrk
	jmp  dumptrk

newvecoff=*-newvect

*=*+18-newvecoff

vects	.word	idle
	.word	irq
	.word	diagok
	.word	verdir
	.word	intdrv
	.word	part
	.word   mem
	.word   block
 	.word   user
	.word 	record
	.word   utlodr
	.word   dskcpy
	.word   rename
	.word 	scrtch
 	.word 	new
	.word   jerror
	.word   atnsrv
	.word   talk
	.word   listen
	.word   lcc
	.word   trans_ts
	.word   jcmder2
lenv=*-vects

*=*+12

vectors
	ldy  #lenv-1
-	lda  vects,y
	sta  svects,y
	dey
	bpl  -

	lda  #$4c
	sta  jhandsk
	lda  #<handsk
	sta  jhandsk+1
	lda  #>handsk
	sta  jhandsk+2	 ; just in case they want to xmt a different way
	rts



	*=$ffea
ublock  .word    ublkrd
	.word    ublkwt
	.word    $0500   ; links to buffer #2
	.word    $0503
	.word    $0506
	.word    $0509
	.word    $050c
	.word    $050f

	*=$fffa
	.word    nnmi
	.word    dskint
	.word    jirq
