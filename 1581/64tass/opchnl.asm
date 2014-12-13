; open a read chanl with 2 buffers
; will insert sa in lintab
; and inits all pointers.
; relative ss and ptrs are set.

opnrch  lda  #1         ; get one data buffer
        jsr  getrch
        jsr  initp      ; clear pointers
        lda  type
        pha
        asl  a
        sta  filtyp,x   ; set file type
        jsr  strrd      ; read 1st one or two blocks
        ldx  lindx
        lda  track
        bne  or10

        lda  sector
        sta  lstchr,x   ; set last char ptr
or10    pla
        cmp  #reltyp
        bne  or30       ; must be sequential stuff

        ldy  sa
        lda  lintab,y   ; set channel as r/w
        ora  #$40
        sta  lintab,y
        lda  rec
        sta  rs,x       ; set record size
        jsr  getbuf     ; get ss buffer
        bpl  or20

        jmp  gberr      ; no buffer

or20    ldx  lindx
        sta  ss,x
	pha
	jsr  hugerel
	beq  or21

	pla
        ldy  trkss      ; set ss track
        sty  track
        ldy  secss      ; set ss sector
        sty  sector
        jsr  seth       ; set ss header
        jsr  rdss       ; read it in
        jsr  watjob
	jmp  orow	; continue
or21
	pla
	lda  trkss
	sta  ssstrk,x
	lda  secss
	sta  ssssec,x
	lda  #all
	sta  sssgrp,x	; no group is resident, ok...

orow    ldx  lindx
        lda  #2
        sta  nr,x       ; set for nxtrec
        lda  #0
        jsr  setpnt     ; set first data byte
        jsr  rd40       ; set up 1st record
        jmp  gethdr     ; restore t&s

or30    jsr  rdbyt      ; sequential set up
        ldx  lindx
        sta  chndat,x
        lda  #rdytlk
        sta  chnrdy,x
        rts
initp   ldx  lindx      ; init var's, open chnl
        lda  buf0,x     ; lstjob,sets act buf#,lstchr
        asl  a          ; buf pntrs in buftbl=2
        bmi  initp0

        tay
        lda  #2
        sta  buftab,y
initp0  lda  buf1,x
        ora  #$80
        sta  buf1,x
        asl  a
        bmi  initp1

        tay
        lda  #2
        sta  buftab,y
initp1  lda  #0
        sta  lstchr,x
        sta  nbkl,x
        sta  nbkh,x
        rts

; open a write chanl with 2 buffers

opnwch  jsr  intts      ; get first track,sector
opnwch1 lda  #1
        jsr  getwch     ; get 1 buffers for writing
        jsr  sethdr     ; set up buffer headers
        jsr  initp      ; zropnt
        ldx  lindx
        lda  type
        pha
        asl  a
        sta  filtyp,x   ; set filtyp=seq
        pla
        cmp  #reltyp
        beq  ow10

        lda  #rdylst    ; active listener
        sta  chnrdy,x
        rts

ow10    ldy  sa
        lda  lintab,y
        and  #$3f
        ora  #$40
        sta  lintab,y   ; set channel as r/w
        lda  rec
        sta  rs,x       ; set record size
        jsr  getbuf     ; get ss buffer
        bpl  ow20

        jmp  gberr      ; no buffer

ow20    ldx  lindx
        sta  ss,x
        jsr  clrbuf
        jsr  nxtts
        lda  track
        sta  trkss      ; save ss t&s
        lda  sector
        sta  secss
        ldx  lindx
        lda  ss,x
        jsr  seth       ; set ss header
        lda  #0
        jsr  setssp
        lda  #0         ; set null link
        jsr  putss
        lda  #ssioff+1  ; set last char
        jsr  putss
        lda  #0         ; set this ss #
        jsr  putss
        lda  rec        ; record size
        jsr  putss
        lda  track
        jsr  putss
        lda  sector
        jsr  putss
        lda  #ssioff
        jsr  setssp
        jsr  gethdr     ; get first t&s
        lda  track
        jsr  putss
        lda  sector
        jsr  putss
        jsr  wrtss      ; write it out
        jsr  watjob
	jsr  hugerel
	bne  ow21

	jsr  owbrel
ow21
        lda  #2
        jsr  setpnt
        ldx  lindx      ; set nr for null buffer
        sec
        lda  #0
        sbc  rs,x
        sta  nr,x
        jsr  nulbuf     ; null records
        jsr  nullnk
        jsr  wrtout
        jsr  watjob
        jsr  mapout
        jmp  orow
owbrel
	ldx  lindx
	lda  ss,x	; get ss buffer #
	jsr  clrbuf	; clean 'em out
	jsr  setssp	; set ss pointer
	lda  trkss
	jsr  putss	; set track link
	lda  secss
	jsr  putss	; set sector link
	lda  #all-1
	jsr  putss	; set sss id
	lda  trkss
	jsr  putss	; set ss track
	lda  secss
	jsr  putss	; set ss sector
	jsr  nxtts	; get next track and sector
	ldx  lindx
	lda  track
	sta  ssstrk,x	; save sss track
	sta  trkss
	lda  sector
	sta  ssssec,x	; save sss sector
	sta  secss
	lda  #all
	sta  sssgrp,x	; no resident ss
	jsr  wrtsss	; write the sss
	jmp  gethdr
;
; put a byte into the ss
;
putss
	pha
        ldx  lindx
        lda  ss,x
        jmp  putb1
