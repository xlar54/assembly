pezro   ldx  #0         ; err #1 for zero page
	.byte skip2	; skip next two bytes
perr    ldx  temp       ; get error #
        txs     	; use stack as storage reg.
pe20    tsx     	; restore error #
pe30    lda  #pwr_led+act_led
        ora  pa
        sta  pa		; turn on led
        tya     	; clear inner ctr
pd10    clc
pd20    adc  #1         ; count inner ctr
        bne  pd20

        dey     	; done ?
        bne  pd10       ; no

        lda  pa
        and  #all-pwr_led-act_led
        sta  pa		; turn off all led
pe40    tya     	; clear inner ctr
pd11    clc
pd21    adc  #1         ; count inner ctr
        bne  pd21

        dey     	; done ?
        bne  pd11       ; no

        dex     	; blinked # ?
        bpl  pe30       ; no - blink again

        cpx  #$f9       ; waited between counts ?
        bne  pe40       ; no

        beq  pe20       ; always - all again

dskint  sei     	; reset entry
        cld
	lda  #init_prt_pa
	sta  pa
	lda  #init_dd_pa
	sta  ddpa

	lda  #init_prt_pb
	sta  pb
	lda  #init_dd_pb
	sta  ddpb
	lda  #0
	sta  tima_h	; set baud rate up
	lda  #6
	sta  tima_l	; 6uS bit
	lda  #1
	sta  cra	; sp input, phi2, cont, start
	lda  #$9a
	sta  icr	; irq on flag, sp, timerb

        ldy  #0
        ldx  #0
pu10    txa     	; fill z-page with
        sta  $0,x       ; accend pattern
        inx
        bne  pu10

pu20    txa     	; chk pattern by inc
        cmp  $0,x       ; ...back to orig #
        bne  pezro      ; bad bits

pu30    inc  $0,x       ; bump contents
        iny
        bne  pu30       ; not done

        cmp  $0,x       ; check for good count
        bne  pezro      ; something's wrong

        sty  $0,x       ; leave z-page zeroed
        lda  $0,x       ; check it
        bne  pezro      ; wrong

        inx     	; next!
        bne  pu20       ; not all done
; test 32k byte rom

; enter x=start page
; exit if ok

rm10    inc  temp       ; next error #
	ldx  #127	; 128 pages
        stx  ip+1       ; save page, start x=0
	inx
        lda  #0
        sta  ip         ; zero lo indirect
	ldy  #2		; skip signature bytes
        clc
rt10    inc  ip+1       ; do it backwards
rt20    adc  (ip),y     ; total checksum in a
        iny
        bne  rt20

        dex
        bne  rt10

        adc  #255        ; add in last carry
	sta  ip+1
	bne  perr2      ; no - show error number

; test all common ram

cr20    lda  #$01       ; start of 1st block
cr30    sta  ip+1       ; save page #
        inc  temp       ; bump error #

; enter x=# of pages in block
; ip ptr to first page in block
; exit if ok

ramtst  ldx  #31	; save page count
ra10    tya     	; fill with adr sensitive pattern
        clc
        adc  ip+1
        sta  (ip),y
        iny
        bne  ra10

        inc  ip+1
        dex
        bne  ra10

        ldx  #31	; restore page count
ra30    dec  ip+1       ; check pattern backwards
ra40    dey
        tya     	; gen pattern again
        clc
        adc  ip+1
        cmp  (ip),y     ; ok ?
        bne  perr2      ; no - show error #

        eor  #$ff       ; yes - test inverse pattern
        sta  (ip),y
        eor  (ip),y     ; ok ?
        sta  (ip),y     ; leave memory zero
        bne  perr2      ; no - show error #

        tya
        bne  ra40

        dex
        bne  ra30

	lda  #bit7
	sta  dejavu	; enable autoloader
        bne  diagok

perr2   jmp  perr
diagok  sei
	ldx  #dtos
	stx  tos
        txs
	jsr  vectors	; setup default vectors
	jsr  restore	; restore all
	bit  dejavu
	bpl  diagrtn	; boot?

	jmp  cbmboot	; try to boot "COPYRIGHT CBM 86" USR file

diagrtn lda  #$73       ; pwr on msg
        jsr  errts0     ; copyright cbm dos
	jsr  tstatn	; check for atn
	jmp  jidle
restore lda  pa         ; compute primary addr
	and  #dev_sel1+dev_sel2
        lsr  a
        lsr  a
        lsr  a
        ora  #$48       ; talk address
        sta  tlkadr
        eor  #$60       ; listen address
        sta  lsnadr

        ldx  #numjob
	lda  #>bam2
dskin0  sta  bufind,x     ; set buff indirects
	sec
	sbc  #1
        dex
        bpl  dskin0

        ldx  #0         ; init buf pntr tbl
        ldy  #0
intt1   lda  #0
        sta  buftab,x
        inx
        lda  bufind,y
        sta  buftab,x
        inx
        iny
        cpy  #bfcnt+2   ; include bams
        bne  intt1

        lda  #<cmdbuf   ; set pntr to cmdbuf
        sta  buftab,x
        lda  #>cmdbuf
        sta  buftab+1,x
        lda  #<errbuf   ; set pntr to errbuf
        sta  buftab+2,x
        lda  #>errbuf
        sta  buftab+3,x
        lda  #$ff
        ldx  #maxsa
dskin1  sta  lintab,x
        dex
        bpl  dskin1

        ldx  #mxchns-1
dskin2  sta  buf0,x     ; set buff as unused
        sta  buf1,x
        sta  ss,x
        dex
        bpl  dskin2

        lda  #bfcnt+2   ; set buffer pointers
        sta  buf0+cmdchn
        lda  #bfcnt+3
        sta  buf0+errchn
        lda  #errchn
        sta  lintab+errsa
        lda  #cmdchn+$80
        sta  lintab+cmdsa
        lda  #lxint     ; lindx 0 to 4 free
        sta  linuse
        lda  #rdylst
        sta  chnrdy+cmdchn
        lda  #rdytlk
        sta  chnrdy+errchn
        lda  #$80       ; all 7 bufs free
        sta  bufuse
        lda  #1
        sta  wpsw
        jsr  usrint     ; init user jmp
        jsr  lruint
        lda  #1         ; set up sec offset
        sta  secinc
        lda  #2
        sta  revcnt     ; set up recovery count
	lda  #0
	sta  dkoramask	; ora mask for burst
	lda  #all
	sta  dkandmask	; *

	lda  #<buffcache
	sta  cache	; indirect for track cache buffer
	lda  #>buffcache
	sta  cache+1	; indirect for track cache buffer

	lda  #bit3
	sta  fsflag	; fast serial enabled

	lda  #$33
	sta  dosver	; init DOS version & type
	lda  #$44
	sta  vernum

	lda  #sysiob
	sta  iobyte	; bit-7 verify on, bit-6 crc check on, bit-5 part on

	lda  #$50	; +700 mS.
	sta  motoracc	; acceleration startup

	lda  #32
	sta  sieeeset	; track buffer timeout

	ldx  #0		; job #0
        lda  #reset_dv	; reset device & restore head
	jsr  strobe_controller
	cmp  #2
	bcs  +		; controller error

	lda  #restore_dv
	jmp  strobe_controller

+	lda  #cntrer
	jmp  errts0	; controller error

setdef	lda  #0
 	sta  pstartrk	; physical starting track

        lda  #1
 	sta  startrk	; logical starting track
	lda  #sysdirsec
	sta  dirst	; starting directory sector
	lda  #81
	sta  maxtrk
	lda  #79
	sta  pmaxtrk	; physical ending track for formatting
	lda  #systrack
	sta  dirtrk	; system track
	rts

psetdef	lda  #40	; ****** 24h, 28H *****
	sta  numsec	; logical number of sectors per cylinder

	ldy  #sysiz
	sty  psectorsiz	; physical sector size (512)
	lda  nsecks,y
	sta  pnumsec	; physical number of sectors per cylinder
	sta  pendsec	; last physical sector number
	sta  maxsek
	dey
	sty  pstartsec	; physical starting sector
	sty  minsek

	lda  #$f5
	sta  fillbyte	; fill byte ($f5 - verify with track cache)

	lda  #35
	sta  gap3	; gap for formatting
	rts
