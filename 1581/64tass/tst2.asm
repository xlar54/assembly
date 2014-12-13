lruint  ldx  #0         ; init lru table
lruilp  txa
        sta  lrutbl,x
        inx
        cpx  #cmdchn
        bne  lruilp

	lda  #cmdchn
        sta  lrutbl,x
        rts

; least recently used table update
; input parms: lindx-current chnl
; output parms: lrutbl-update

lruupd  ldy  #cmdchn
        ldx  lindx
lrulp1  lda  lrutbl,y
        stx  lrutbl,y
        cmp  lindx
        beq  lruext

        dey
        bmi  lruint

        tax
        jmp  lrulp1

lruext  rts

; double buffer
; rtn to switch the active and
; inactive buffers
dblbuf
        jsr  lruupd     ; update table
        ldx  lindx
        lda  buf0,x
        bmi  dblget

        lda  buf1,x
dblget  cmp  #$ff
        beq  dbl00

        lda  buf0,x     ; toggle the buffer
        eor  #$80
        sta  buf0,x
        pha
        lda  buf1,x
        eor  #$80
        sta  buf1,x
        tay
        pla     	; get active buffer
        bpl  dbljmp

        tya
dbljmp  and  #$bf
        tax
        jmp  watjob
dbl00
        lda  buf0,x
        bpl  dbldrv

        lda  buf1,x
dbldrv  and  #$bf
        tay
        jsr  getbuf
        bpl  dbl01

        lda  #nochnl    ; no buffers to steal
        jmp  cmderr

dbl01   ldx  lindx      ; getbuf corrupts x
        ora  #$80
        ldy  buf0,x
        bpl  dblput

        sta  buf0,x
        bmi  dblpt1     ; bra

dblput  sta  buf1,x
dblpt1  lda  track
        pha
        lda  sector
        pha
        lda  #1
        sta  temp+2
        lda  buf0,x
        bpl  dbldrd

        lda  buf1,x
dbldrd  and  #$bf
        tay
        lda  bufind,y
        sta  temp+3
        ldy  #0
        lda  (temp+2),y
        sta  sector
        lda  #0
        sta  temp+2
        lda  buf0,x
        bpl  dbldr1

        lda  buf1,x
dbldr1  and  #$bf
        tay
        lda  bufind,y
        sta  temp+3
        ldy  #0
        lda  (temp+2),y
        sta  track
        beq  dbl10

        jsr  typfil
        beq  dbl05      ; it's rel

        jsr  tstwrt
        bne  dbl05      ; read ahead

        jsr  tglbuf     ; just switch on write
        jmp  dbl08

dbl05
        ldx  lindx      ; toggle active buffers
        lda  buf0,x
        eor  #$80
        sta  buf0,x
        lda  buf1,x
        eor  #$80
        sta  buf1,x
        jsr  rdab
dbl08
        pla
        sta  sector
        pla
        sta  track
        jmp  dbl20
dbl10
        pla
        sta  sector
        pla
        sta  track
dbl15   jsr  tglbuf
dbl20   jsr  getact
        tax
        jmp  watjob
;
; there are no buffers to steal
;
dbl30
        lda  #nochnl
        jmp  cmderr
;
;********************************
;
dbset
        jsr  lruupd
        jsr  getina
        bne  dbs10

        jsr  getbuf
        bmi  dbl30      ; no buffers

        jmp  putina     ; store inactive buff #
dbs10
        rts
; toggle the inactive and active
; buffers. input parms: lindx-chnl#
;
tglbuf  ldx  lindx
        lda  buf0,x
        eor  #$80
        sta  buf0,x
        lda  buf1,x
        eor  #$80
        sta  buf1,x
        rts

pibyte  ldx  #iwsa
        stx  sa
        jsr  fndwch
        jsr  setlds
        jsr  typfil
        bcc  pbyte

        lda  #ovrflo
        jsr  clrflg
pbyte   lda  sa
        cmp  #15
        beq  l42

        bne  l40

; main routine to write to chanl
;
put     lda  orgsa      ; is chanl cmd or dat
        and  #$8f
        cmp  #15        ; <15
        bcs  l42

l40     jsr  typfil     ; data byte to store
        bcs  l41        ; branch if rnd

        lda  data       ; seq file
        jmp  wrtbyt     ; write byte to chanl

l41     bne  l46

        jmp  wrtrel

l46     lda  data       ; rnd file write
        jsr  putbyt     ; write to chanl
        ldy  lindx      ; prepare nxt byte
        jmp  rnget2

l42     lda  #cmdchn    ; write to cmd chanl
        sta  lindx
        jsr  getpnt     ; test if comm and buffer full
        cmp  #<cmdbuf+cmdlen+1
        beq  l50        ; it is full (>cmdlen)

        lda  data       ; not full yet
        jsr  putbyt     ; store the byte
l50     lda  eoiflg     ; tst if lst byte of msg
        beq  l45        ; it is
        rts     	; not yet , return

l45     inc  cmdwat     ; set cmd waiting flag
        rts
; put .a into active buffer of lindx
;
putbyt  pha     	;  save .a
        jsr  getact     ; get active buf#
        bpl  putb1      ; brach if there is one

        pla     	; no buffer error
        lda  #filnop
        jmp  cmderr     ;  jmp to error routine

putb1   asl  a          ; save the byte in buffer
        tax
        pla
        sta  (buftab,x)
        inc  buftab,x   ; inc the buffer pointer
        rts     	; last slot in buf, acm=1
;
; find the active buffer # (lindx)
intdrv  jsr  simprs     ; init drvs (command)
	jsr  psetdef	; set def parms
	jsr  setdef	; *
        jsr  initdr
	bit  dejavu
	bvc  +

	jmp  cbmboot	; auto boot

+       jmp  endcmd

itrial  jsr  getbuf
        sta  jobnum
	tax
	jsr  fb2	; release buffer
        ldx  #0
        stx  sector
        ldx  dirtrk
        stx  track
        jsr  seth       ; set the bam header
        lda  #seekhd_dv
        jsr  dojob      ; do a seek
	ldx  jobnum
	pha
	lda  #detwp_dv
	jsr  strobe_controller
	sta  wpstat	; save write protect status
	pla		; restore status from seek
	rts
initdr  lda  dejavu
	and  #all-bit6
	sta  dejavu
	lda  dkoramask
	ora  #bit7
	sta  dkoramask	; set alien
	jsr  cldchn
        jsr  itrial
	cmp  #2
	bcs  +		; problems don't bother

	lda  psectorsiz
	cmp  #sysiz
	beq  ++

+	jmp  nmf21

+	jsr  doread     ; rd in dir header
	lda  jobnum
        asl  a
        tax
        lda  #1         ; skip track link
        sta  buftab,x
        lda  (buftab,x)
        sta  dirst      ; set up directory sector start
        lda  #2         ; skip link bytes
        sta  buftab,x
        lda  (buftab,x)
        sta  dskver     ; set up disk version #
	lda  #0
	sta  bam1
        jsr  setbpt	; read in both bams
        lda  #0
        sta  wpsw       ; clear wp switch
        sta  nodrv      ; clr not active flag
	ldy  #2
	lda  (bmpnt),y	; vernum here?
	cmp  vernum
	bne  nmf21

	iny
	lda  (bmpnt),y
	eor  #$ff
	cmp  vernum	; eor of vernum?
	bne  nmf21

	lda  dkoramask
	and  #all-bit7
	sta  dkoramask	; set resident

	ldy  #4
	lda  (bmpnt),y
	sta  dskid	; save id's
	iny
	lda  (bmpnt),y
	sta  dskid+1
	iny
	lda  (bmpnt),y
	sta  iobyte	; get i/o byte
	and  #bit5
	sta  relsw
	iny
	lda  (bmpnt),y	; check auto boot flag
	bpl  nfcalc

	lda  dejavu	; boot on initdrv command
	ora  #bit6
	sta  dejavu

nfcalc  lda  track      ; get current trk
        pha     	; save it
        ldx  #0         ;
        stx  ndbl       ; lsb
        stx  ndbh       ; msb
	ldx  startrk
	.byte  skip1
nmf10   inx     	; next trk
        stx  track
        cpx  dirtrk
        beq  nmf10      ; skip the dir trk

        cpx  maxtrk     ; done ?
        bcs  nmf20      ; yes

        jsr  bamtrk     ; set up next bam trk
        lda  (bmpnt),y  ; get blks free (y=0)
        clc
        adc  ndbl       ; up date count
        sta  ndbl       ;
        bcc  nmf10      ; no carry

        inc  ndbh       ; msb
        bne  nmf10      ; always branch

nmf20   pla     	; restore track
        sta  track
	ldx  #0         ; restore it
	rts

nmf21   ldx  #sysdirsec
	stx  dirst	; starting directory sector

	ldx  #sysiob
	stx  iobyte	; init iobyte crccheck on,verify on

	ldx  #0
	stx  relsw	; huge rel
        stx  wpsw       ; clear wp switch
        stx  nodrv      ; clr not active flag
        stx  ndbl       ; lsb
        stx  ndbh       ; msb
	stx  dskid
	stx  dskid+1
	rts
strrd   jsr  sethdr     ; start dbl buf, use
        jsr  rdbuf      ; trk, sec as start block
        jsr  watjob
        jsr  getbyt
        sta  track
        jsr  getbyt
        sta  sector
        rts

strdbl  jsr  strrd
        lda  track
        bne  str1
        rts

str1    jsr  dblbuf
        jsr  sethdr
        jsr  rdbuf
        jmp  dblbuf

rdbuf   lda  #read_dv	; rd job on trk, sec
        bne  strtit

wrtbuf  lda  #wrtsd_dv	; wr job on trk, sec
strtit  sta  cmd
        jsr  getact
        tax
        jsr  setljb
        txa
        pha
        asl  a
        tax
        lda  #0
        sta  buftab,x
        jsr  typfil
        cmp  #4
        bcs  wrtc1      ; not sequential type

        inc  nbkl,x
        bne  wrtc1

        inc  nbkh,x
wrtc1   pla
        tax
        rts

fndrch  lda  sa
        cmp  #maxsa+1
        bcc  fndc20

        and  #$f
fndc20  cmp  #cmdsa
        bne  fndc25

        lda  #errsa
fndc25  tax
        sec
        lda  lintab,x
        bmi  fndc30

        and  #$f
        sta  lindx
        tax
        clc
fndc30  rts

fndwch  lda  sa
        cmp  #maxsa+1
        bcc  fndw13

        and  #$f
fndw13  tax
        lda  lintab,x
        tay
        asl  a
        bcc  fndw15

        bmi  fndw20

fndw10  tya
        and  #$0f
        sta  lindx
        tax
        clc
        rts

fndw15  bmi  fndw10

fndw20  sec
        rts
typfil          	; get file type
        ldx  lindx
        lda  filtyp,x
        lsr  a
        and  #7
        cmp  #reltyp
        rts

getpre  jsr  getact
        asl  a
        tax
        ldy  lindx
        rts

; read byte from active buffer
; and set flag if last data byte
; if last then z=1 else z=0 ;

getbyt
	ldx  lindx
	lda  buf0,x	; active buffer
	bpl  +

	lda  buf1,x
+	and  #$bf
        asl  a
        tax
        ldy  lindx
        lda  lstchr,y
        beq  getb1

        lda  (buftab,x)
        pha
        lda  buftab,x
        cmp  lstchr,y
        bne  getb2

        lda  #$ff
        sta  buftab,x
getb2   pla
        inc  buftab,x
        rts

getb1   lda  (buftab,x)
        inc  buftab,x
        rts
;
; read a char from file and read next
; block of file if needed.
; set chnrdy=eoi if end of file
;
rdbyt   jsr  getbyt
        bne  rd3
        sta  data

rd0     lda  lstchr,y
        beq  rd1
        lda  #eoiout
rd01    sta  chnrdy,y
        lda  data
        rts
rd1     jsr  dblbuf
        lda  #0
        sta  temp
        ldx  lindx
        lda  buf0,x
        bpl  rdypnt

        lda  buf1,x
rdypnt  and  #$bf
        asl  a
        tax
        lda  buftab+1,x
        sta  dirbuf+1
        lda  temp
        sta  buftab,x
        sta  dirbuf
        jsr  getbyt
        cmp  #0
        beq  rd4

        sta  track
        jsr  getbyt
        sta  sector
        jsr  dblbuf
        ldx  lindx
        lda  buf0,x
        bpl  rdydrv

        lda  buf1,x
rdydrv  and  #$bf
        tax
        ldx  lindx
        lda  buf0,x
        bpl  rdydr1

        lda  buf1,x
rdydr1  and  #$bf
        asl  a
        tay
        lda  track
        sta  hdrs,y
        lda  sector
        sta  hdrs+1,y
        jsr  rdbuf
        jsr  dblbuf
        lda  data
rd3     rts
rd4     jsr  getbyt
        ldy  lindx
        sta  lstchr,y
        lda  data
        rts

; write a char to chanl and write
; buffer out to disk if its full
;
wrtbyt  jsr  putbyt
        beq  wrt0

        rts

wrt0    jsr  nxtts
        lda  #0
        jsr  setpnt
        lda  track
        jsr  putbyt
        lda  sector
        jsr  putbyt
        jsr  wrtbuf
        jsr  dblbuf
        jsr  sethdr
        lda  #2
        jmp  setpnt
;
; inc pointer of active buffer
; by .a
;
incptr
        sta  temp
        jsr  getpnt
        clc
        adc  temp
        sta  buftab,x
        sta  dirbuf
        rts
;
; sec carry auto boot loader
;
;
vujade  lda  dejavu	; clear bit7
	and  #all-bit7
	sta  dejavu
	lda  #0
	ror  a		; new bit 7
	ora  dejavu
	sta  dejavu
	rts
