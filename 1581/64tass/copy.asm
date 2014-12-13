; dskcpy check for type
; and parses special case

dskcpy  lda  #00        ; kill bam
        sta  bam1
        lda  #lxint
        sta  linuse     ; free all lindxs
        jsr  prscln     ; find ":"
        bne  dsk10

        jmp  cmer       ; bad cmnd error, cx=x not allowed

dsk10   jsr  tc30       ; normal parse
        jsr  alldrs     ; put drv's in filtbl
        lda  image      ; get parse image
        and  #%01010101 ; val for patt copy
        bne  dsk30      ; must be concat or normal

        ldx  filtbl     ; chk for *
        lda  cmdbuf,x
        cmp  #'*'
        bne  dsk30

dsk20   lda  #badsyn    ; syntax error
        jmp  cmderr

dsk30   lda  image      ; chk for normal
        and  #%11011001
        bne  dsk20
; copy file(s) to one file

copy    jsr  lookup     ; look ip all files
        lda  f2cnt
        cmp  #3
        bcc  cop10

        lda  fildrv
        cmp  fildrv+1
        bne  cop10

        lda  entind
        cmp  entind+1
        bne  cop10

        lda  entsec
        cmp  entsec+1
        bne  cop10

        jsr  chkin      ; concat
        lda  #1
        sta  f2ptr
        jsr  opirfl
        jsr  typfil
        bcs  cop01    	; greater than or equal to relative...

        cmp  #prgtyp
        bne  cop05

cop01   lda  #mistyp
        jsr  cmderr

cop05   lda  #iwsa
        sta  sa
        lda  lintab+irsa
        sta  lintab+iwsa
        lda  #$ff
        sta  lintab+irsa
        jsr  append
        ldx  #2
        jsr  cy10
        jmp  endcmd

cop10   jsr  cy
        jmp  endcmd

cy      jsr  chkio      ; ck fil for existence
        jsr  opniwr     ; open internal write chnl
        jsr  addfil     ; add to directory
        ldx  f1cnt
cy10    stx  f2ptr      ; set up read file
        jsr  opirfl
        lda  #irsa      ; add for rel copy
        sta  sa
        jsr  fndrch
        jsr  typfil
        bne  cy10a      ; not rel

        jsr  cyext
cy10a   lda  #eoisnd
        sta  eoiflg
        jmp  cy20

cy15    jsr  pibyte
cy20    jsr  gibyte
        lda  #lrf
        jsr  tstflg
        beq  cy15

        jsr  typfil
        beq  cy30

        jsr  pibyte
cy30    ldx  f2ptr
        inx
        cpx  f2cnt
        bcc  cy10       ; more files to copy

        lda  #iwsa
        sta  sa
        jmp  clschn     ; close copy chnl, file

opirfl  ldx  f2ptr
        lda  dirtrk
        sta  track
        lda  entsec,x
        sta  sector
        jsr  opnird
        ldx  f2ptr
        lda  entind,x
        jsr  setpnt
        ldx  f2ptr
        lda  pattyp,x
        and  #typmsk
        sta  type
        lda  #0
        sta  rec
        jsr  opread
        ldy  #1
        jsr  typfil
        beq  opir10

        iny
opir10  tya
        jmp  setpnt
gibyte  lda  #irsa
        sta  sa
gcbyte  jsr  gbyte
        sta  data
        ldx  lindx
        lda  chnrdy,x
        and  #eoisnd
        sta  eoiflg
        bne  gib20

        jsr  typfil
        beq  gib20

        lda  #lrf
        jsr  setflg
gib20   rts

cyext   jsr  ssend      ; copy rel rec's
	jsr  hugerel	; humugo?
	bne  cyext1	; br, nope

	lda  grpnum	; save grpnum
	pha
cyext1
        lda  ssind
        pha
        lda  ssnum
        pha
        lda  #iwsa
        sta  sa
        jsr  fndwch
	jsr  adrels
	sta  relptr
	pla
        sta  ssnum
	pla
	sta  ssind
	jsr  hugerel
	bne  cyext2

	pla
	sta  grpnum	; restore group number
cyext2
	jmp  addr1
