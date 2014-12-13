; scratch file(s)

scrtch  jsr  fs1set     ; set up for 1 stream
	jsr  alldrs
	jsr  optsch
	lda  #0
	sta  r0         ; used as file count
	jsr  ffst
	bmi  sc30

sc15    jsr  tstchn     ; is it active ?
	bcc  sc25       ; yes - don't scratch

	ldy  #0
	lda  (dirbuf),y
	sta  lo         ; save type
	and  #$40       ; lock bit
	bne  sc25       ; it's locked

	jsr  deldir     ; delete directory

	lda  lo         ; recall type
	and  #typmsk
	cmp  #partyp    ; par file?
	bne  sc16

	iny
	lda  (dirbuf),y
	sta  track
	iny
	lda  (dirbuf),y
	sta  sector
	ldy  #$1c
	lda  (dirbuf),y
	sta  lo
	iny
	lda  (dirbuf),y
	sta  hi

-       jsr  tschk      ; check track
	jsr  frets      ; free it
	jsr  calcpar
	bne  -
	jmp  scrtch_patch       ; update BAM and move on to next file


sc16    ldy  #19        ; is this a relative ?
	lda  (dirbuf),y ; has a ss ?
	beq  sc17       ; no

	sta  track      ; yes - save track
	iny
	lda  (dirbuf),y ; get sector
	sta  sector
	jsr  delfil     ; delete by links
sc17    ldx  entfnd
	lda  #$20
	and  pattyp,x
	bne  sc20       ; created, not closed

	lda  filtrk,x   ; delete by links
	sta  track
	lda  filsec,x
	sta  sector
	jsr  delfil
sc20    inc  r0
sc25    jsr  ffre
	bpl  sc15

sc30    lda  r0         ; finished, set
	sta  track      ; file count
	ldy  #0
	lda  #1
	jmp  scrend     ; end of scratch

delfil  jsr  frets      ; delete file by links
	jsr  opnird     ; update bam
del1    lda  #0
	jsr  setpnt
	jsr  rdbyt
	sta  track
	jsr  rdbyt
	sta  sector
	lda  track
	bne  del2

	jsr  mapout
	jmp  frechn

del2    jsr  frets
	jsr  nxtbuf
	jmp  del1

deldir  ldy  #0         ; delete dir entry
	tya
	sta  (dirbuf),y
	jsr  wrtout
	jmp  watjob
