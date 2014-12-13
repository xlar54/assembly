setlst  ldx  lindx
        lda  nr,x
        sta  r1
        dec  r1
        cmp  #2
        bne  setl01

        lda  #$ff
        sta  r1
setl01  lda  rs,x
        sta  r2
        jsr  getpnt
        ldx  lindx
        cmp  r1
        bcc  setl10

        beq  setl10

        jsr  dblbuf
        jsr  fndlst
        bcc  setl05

        ldx  lindx
        sta  lstchr,x
        jmp  dblbuf

setl05  jsr  dblbuf
        lda  #$ff
        sta  r1
setl10  jsr  fndlst
        bcs  setl40

        jsr  getpnt
setl40  ldx  lindx
        sta  lstchr,x
        rts

fndlst  jsr  set00
        ldy  r1         ; offset to start at
fndl10  lda  (dirbuf),y
        bne  fndl20

        dey
        cpy  #2
        bcc  fndl30

        dec  r2         ; limit counter
        bne  fndl10

fndl30  dec  r2
        clc     	;  not found here
        rts

fndl20  tya     	; found the end char
        sec
        rts
