stdir   lda  #0         ; start dir loading func, get
        sta  sa         ; buffr and get it started
        lda  #1         ; allocate chanl and 1 bufefer
        jsr  getrch
        lda  #0
        jsr  setpnt
        ldx  lindx
        lda  #0
        sta  lstchr,x
        jsr  getact
        tax
        lda  #0
        sta  lstjob,x
        lda  #1         ; put sal in buffer
        jsr  putbyt
        lda  #4         ; put sah in buffer
        jsr  putbyt
        lda  #1         ; insert fhoney links (0101)
        jsr  putbyt
        jsr  putbyt
        lda  nbtemp
        jsr  putbyt     ; put in drvnum
        lda  #0
        jsr  putbyt
        jsr  movbuf     ; get disk name
        jsr  getact
        asl  a
        tax
        dec  buftab,x
        dec  buftab,x
        lda  #0         ; end of this line
        jsr  putbyt
dir1    lda  #1         ; insert fhoney links ($0101)
        jsr  putbyt
        jsr  putbyt
        jsr  getnam     ; get #bufrs and file name
        bcc  dir3       ; test if last entry

        lda  nbtemp
        jsr  putbyt
        lda  nbtemp+1
        jsr  putbyt
        jsr  movbuf
        lda  #0         ; end of entry
        jsr  putbyt
        bne  dir1

dir10   jsr  getact
        asl  a
        tax
        lda  #0
        sta  buftab,x
        lda  #rdytlk
        ldy  lindx
        sta  dirlst
        sta  chnrdy,y   ; dir list buff full
        lda  data
        rts

dir3    lda  nbtemp     ; this is end of load
        jsr  putbyt
        lda  nbtemp+1
        jsr  putbyt
        jsr  movbuf
        jsr  getact
        asl  a
        tax
        dec  buftab,x
        dec  buftab,x
        lda  #0         ; end of listing (000)
        jsr  putbyt
        jsr  putbyt
        jsr  putbyt
        jsr  getact
        asl  a
        tay
        lda  buftab,y
        ldx  lindx
        sta  lstchr,x
        dec  lstchr,x
        jmp  dir10

movbuf  ldy  #0         ; file name to lsting buf
movb1   lda  nambuf,y
        jsr  putbyt
        iny
        cpy  #27
        bne  movb1

        rts

getdir  jsr  getbyt     ; get dir char
        beq  getd3

        rts

getd3   sta  data
        ldy  lindx
        lda  lstchr,y
        beq  gd1

        lda  #eoiout
        sta  chnrdy,y
        lda  data
        rts

gd1     pha
        jsr  dir1
        pla
        rts
