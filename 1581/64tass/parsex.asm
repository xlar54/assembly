;parse & execute string in cmdbuf
parsxq  lda  #0
	sta  wbam
	jsr  okerr
	lda  orgsa
	bpl  ps05

	and  #$f
	cmp  #$f
	beq  ps05

	jmp  open
ps05    jsr  cmdset     ; set variables,regs
	lda  (cb),y
	sta  char
	ldx  #ncmds-1   ; search cmd table
ps10    lda  cmdtbl,x
	cmp  char
	beq  ps20

	dex
	bpl  ps10

bcerr   lda  #badcmd    ; no such cmd
	jmp  cmderr

ps20    stx  cmdnum     ; x= cmd #
	cpx  #pcmd      ; cmds not parsed
	bcc  ps30

	jsr  tagcmd     ; set tables, pointers &patterns
ps30    ldx  cmdnum
	lda  cjumpl,x
	sta  temp
	lda  cjumph,x
	sta  temp+1
	jmp  (temp)     ; command table jump
endcmd  lda  #0
	sta  wbam
endsav  lda  erword
	beq  +

	jmp  cmderr

+       ldy  #0
	tya
	sta  track
scrend  sty  sector     ; scratch entry
partend sty  cb
	jsr  errmsg
	jsr  erroff
scren1  lda  #0
	sta  nodrv
	jsr  clrcb
	jmp  freich     ; free internal channel
clrcb   ldy  #cmdlen-1
	lda  #0
clrb2   sta  cmdbuf,y
	dey
	bpl  clrb2

	rts

cmderr  ldy  #0         ; cmd level err proc
	sty  track
	sty  sector
	jmp  cmder2

simprs  ldx  #0         ; simple parser
	stx  filtbl
	lda  #':'
	jsr  parse
	beq  sp10

	dey
	dey
	sty  filtbl
sp10    jmp  setany     ; set drive #
prscln  ldy  #0
	ldx  #0
	lda  #':'
	jmp  parse      ; find pos'n of ":"

tagcmd  jsr  prscln     ; tag cmd string,setup cmd..
	bne  tc30       ; struc, image & file pntrs

tc25    lda  #nofile    ; none, no files
	jmp  cmderr

tc30    dey
	dey
	sty  filtbl     ; ":"-1 starts fs1
	txa
	bne  tc25       ; err: "," before ":"

tc35    lda  #'='       ; search: "="
	jsr  parse
	txa             ; ?file count= 1-1?
	beq  tc40

	lda  #%01000000 ; g1-bit
tc40    ora  #%00100001 ; e1,^e2-bits
	sta  image      ; fs structure
	inx
	stx  f1cnt
	stx  f2cnt      ; init for no fs2
	lda  patflg
	beq  tc50

	lda  #%10000000 ; p1-bit
	ora  image
	sta  image
	lda  #0
	sta  patflg     ; clear pattern flag
tc50    tya             ; ptr to fs2
	beq  tc75       ;  fs2 not here

	sta  filtbl,x
	lda  f1cnt      ; fs2 is here now,...
	sta  f2ptr      ; ...now set f2 ptr
	lda  #$8d       ; find cr-shifted
	jsr  parse      ; parse rest of cmd string
	inx             ; advance filtbl ptr to end
	stx  f2cnt      ; save it
	dex             ; restore for test
	lda  patflg     ; save last pattern
	beq  tc60       ; ?any patterns?

	lda  #%1000     ; yes, p2-bit
tc60    cpx  f1cnt      ; ?f2cnt=f1cnt+1?
	beq  tc70

	ora  #%0100     ; g2-bit
tc70    ora  #%0011     ; e2-bit,^e2-bit
	eor  image      ; eor clears ^e2-bit
	sta  image
tc75    lda  image
	ldx  cmdnum
	and  struct,x   ; match cmd template
	bne  tc80

	rts

tc80    sta  erword     ; **could be warning
	lda  #badsyn    ; err: bad syntax
	jmp  cmderr
;parse string
;  looks for special chars,
;  returning when var'bl char
;  is found
;   a: var'bl char
;   x: in,out: index, filtbl+1
;   y: in: index, cmdbuf
;     out: new ptr, =0 if none
;         (z=1) if y=0
;
parse   sta  char       ; save var'bl char
pr10    cpy  cmdsiz     ; stay in string
	bcs  pr30

	lda  (cb),y     ; match char
	iny
	cmp  char
	beq  pr35       ; found char

	cmp  #'*'       ; match pattern chars
	beq  pr20

	cmp  #'?'
	bne  pr25

pr20    inc  patflg     ; set pattern flag
pr25    cmp  #','       ; match file separator
	bne  pr10

	tya
	sta  filtbl+1,x         ; put ptrs in table
	lda  patflg     ; save pattern for ea file
	and  #$7f
	beq  pr28

	lda  #$80       ; retain pattern presence...
	sta  pattyp,x
	sta  patflg     ; ...but clear count
pr28    inx
	cpx  #mxfils-1
	bcc  pr10       ; no more than mxfils

pr30    ldy  #0         ; y=0 (z=1)
pr35    lda  cmdsiz
	sta  filtbl+1,x
	lda  patflg
	and  #$7f
	beq  pr40

	lda  #$80
	sta  pattyp,x
pr40    tya             ; z is set
	rts
;initialize command tables, ptrs, etc.
;
cmdset  .proc
	ldy  buftab+cbptr
	beq  cs08

	dey
	beq  cs07

	lda  cmdbuf
	cmp  #'U'       ; U0...?
	bne  m1

	lda  cmdbuf+1
	cmp  #'0'
	beq  m2

m1      lda  cmdbuf,y
	.byte skip2
m2      lda  #0
	cmp  #cr
	beq  cs08

	dey
	lda  cmdbuf
	cmp  #'U'       ; U0...?
	bne  m3

	lda  cmdbuf+1
	cmp  #'0'
	beq  m4

m3      lda  cmdbuf,y
	.byte skip2
m4      lda  #0
	cmp  #cr
	beq  cs08

	iny
cs07    iny
cs08    sty  cmdsiz     ; set cmd string size
	cpy  #cmdlen+1
	ldy  #$ff
	bcc  cmdrst

	sty  cmdnum
	lda  #longln    ; long line error
	jmp  cmderr
	.pend

cmdrst  ldy  #0         ; clr vars, tbls
	tya
	sta  buftab+cbptr
	sta  rec
	sta  type
	sta  typflg
	sta  f1ptr
	sta  f2ptr
	sta  f1cnt
	sta  f2cnt
	sta  patflg
	sta  erword
	ldx  #mxfils
cs10    sta  filtbl-1,x
	sta  entsec-1,x
	sta  entind-1,x
	sta  fildrv-1,x
	sta  pattyp-1,x
	sta  filtrk-1,x
	sta  filsec-1,x
	dex
	bne  cs10

	rts

; turn on activity led

erroff  lda  #0
	sta  erword
	lda  ledprint
	and  #all-pwr_led
	sta  ledprint
	rts

erron   lda  #80
	sta  erword
setlds  lda  ledprint
	ora  #act_led
	sta  ledprint
	rts
