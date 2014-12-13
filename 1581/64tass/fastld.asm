slodown	jmp  endcmd	; not today

fstload .proc
	lda  #bit3
	bit  fsflag	; fast serial enabled ?
	beq  slodown

	jsr  spout	; output
	jsr  set_fil	; setup filename for parser
	bcs  m9

        jsr  autoi	; init mechanism
	lda  nodrv	; chk status
	bne  m9		; no drive status

	lda  #bit7
	sta  tmp+4	; eoi first time thru flag
	jsr  setvectors ; save/set vectors

	lda  cmdbuf
	cmp  #'*'	; load last ?
	bne  m7

	lda  prgtrk	; any file ?
	beq  m7

	pha		; save track
	lda  prgsec
	sta  filsec	; update
	pla
	jmp  m1

m7	lda  #0
	tay
	tax		; clear .a, .x, .y
	sta  filtbl	; set up for file name parser
        jsr  onedrv     ; select drive
	lda  f2cnt
	pha
	lda  #1
	sta  f2cnt
	lda  #$ff
	sta  r0		; set flag
	jsr  lookup	; locate file
	pla
	sta  f2cnt	; restore var
	jsr  resvectors ; restore error vectors

	bit  switch	; seq flag set ?
	bmi  m8

 	lda  pattyp	; is it a program file ?
	and  #typmsk
	cmp  #2
	bne  m6		; not prg

m8      lda  filtrk     ; check if found. err if not
        bne  m1		; br, file found

m6    	ldx  #%00000010	; file not found
	.byte skip2
m9	ldx  #%00001111	; no drive
        jmp  syserr

m1      sta  prgtrk	; save for next
	ldx  #0		; get channel offset
	sta  hdrs,x	; setup track
        lda  filsec     ; & sector
	sta  prgsec	; for next time
        sta  hdrs+1,x

m2	cli		; let controller run
	ldx  #0
	lda  #tread_dv	; get cmd and send it
	jsr  stbctr	; whack the controller in the head
	tax
	cpx  #2		; error ?
	bcc  +

	jmp  ctlerr

+	sei
	ldy  #0
	sty  bufpnt
	lda  cacheoff,y ; controller passed us a pointer to the data
	and  #all-bit7
	clc
	adc  cache+1	; get offset into data
	sta  bufpnt+1
	lda  (bufpnt),y	; check status
	beq  end_of_file

	asl  tmp+4	; clear flag

	jsr  jhandsk	; handshake error to the host

	ldy  #2
-	lda  (bufpnt),y
	tax		; save data in .x
	jsr  jhandsk	; handshake it to the host
	iny
	bne  -

	ldx  #0		; jobnum * 2
	lda  (bufpnt),y ; .y = 0
	sta  hdrs,x	; next track
	iny  		; sector entry
	lda  (bufpnt),y
	sta  hdrs+1,x	; next sector
	jmp  m2
	.pend

end_of_file .proc
	ldx  #$1f	; eof
	jsr  jhandsk	; handshake it to the host

	bit  tmp+4	; first time through ?
	bpl  m1	        ; br, nope

	ldy  #1		; .y = 1
	lda  (bufpnt),y	; number of bytes
	sec
	sbc  #3
	sta  tmp	; save it
	tax		; send it
	jsr  jhandsk	; handshake it to the host

	iny		; next
	lda  (bufpnt),y	; address low
	tax
	jsr  jhandsk	; handshake it to the host

	iny
	lda  (bufpnt),y	; address high
	tax
	jsr  jhandsk	; handshake it to the host
	ldy  #4		; skip addresses
	bne  m3		; bra

m1      ldy  #1
	lda  (bufpnt),y	; number of bytes
	tax
	dex
	stx  tmp	; save here
	jsr  jhandsk	; handshake it to the host

	ldy  #2		; start at data
m3	lda  (bufpnt),y
	tax
	jsr  jhandsk	; handshake it to the host
	iny
	dec  tmp	; use it as a temp
	bne  m3

	jmp  endcmd	; done
	.pend
;
;
; error handler

flderror
	tax
	jsr  resvectors

ctlerr  jsr  finld	; finish up
	ldx  #0
	jmp  error	; error out.....

fldcmderr
	pha		; save error
	php
	sei
	ldx  #2
	jsr  jhandsk	; send status back
	plp
	jsr  resvectors
	pla
syserr  jsr  finld	; finish up
	cmp  #2
	beq  +

	lda  #nodriv	; no active drive
	.byte skip2
+	lda  #flntfd	; file not found
	jmp  cmderr	; never more...

finld	sei
	stx  tmp	; save error
	ldx  #2		; file not found
	jsr  jhandsk	; give it to him
	lda  tmp	; get error back
	rts

;
; burst load filename parser
;
set_fil .proc
	ldy  #3		; default .y
	lda  cmdsiz	; delete burst load command
	sec
	sbc  #3
	sta  cmdsiz	; new command size

	lda  cmdbuf+4   ; drv # given ?
	cmp  #':'
	bne  +

	lda  cmdbuf+3
	tax		; save
	and  #'0'
	cmp  #'0'       ; 0:file ?
	bne  +

	cpx  #'1'	; chk for error
	beq  m4

+	lda  cmdbuf+3   ; drv # given ?
	cmp  #':'
	bne  +

	dec  cmdsiz
	iny

+	ldx  #0		; start at cmdbuf+0
-       lda  cmdbuf,y	; extract file-name
	sta  cmdbuf,x
	iny
	inx
	cpx  cmdsiz	; done ?
	bne  -		; delete cmd from buffer

	clc
	.byte skip1
m4	sec		; error
	rts
	.pend

;
; burst handshake routine
;
handsk			; .x contains data
-	lda  pb		; debounce
        cmp  pb
        bne  -

	and  #$ff	; set/clr neg flag
        bmi  +		; br, attn low

        eor  fsflag	; wait for state chg
        and  #4
        beq  -

        stx  sdr	; send it
        eor  fsflag
        sta  fsflag	; change state of clk

        lda  #8
-	bit  icr	; wait transmission time
        beq  -

        rts

+	jmp  jatnsrv	; bye-bye the host wants us

;
; save/set vector routine
;
setvectors
	jsr  savectors
	lda  #<flderror	; setup new vectors
	sta  verror
	lda  #>flderror
	sta  verror+1
	lda  #<fldcmderr
	sta  vcmder2
	lda  #<fldcmderr
	sta  vcmder2+1
	rts


savectors
	lda  verror	; save error vectors
	sta  savects
	lda  verror+1
	sta  savects+1
	lda  vcmder2
	sta  savects+2
	lda  vcmder2+1
	sta  savects+3
	rts
;
; restore vector routine
;
resvectors
	lda  savects
	sta  verror
	lda  savects+1
	sta  verror+1
	lda  savects+2
	sta  vcmder2
	lda  savects+3
	sta  vcmder2+1
	rts
