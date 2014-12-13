;  memory access commands
;  "-" must be 2nd char
mem     lda  cmdbuf+1
        cmp  #'-'
        bne  cmer

        lda  cmdbuf+3   ; set adr in temp
        sta  temp
        lda  cmdbuf+4
        sta  temp+1
        ldy  #0
        lda  cmdbuf+2
        cmp  #'R'
        beq  memrd      ; read

        cmp  #'W'
        beq  memwrt     ; write

        cmp  #'E'
        bne  cmer       ; error

        jmp  (temp)     ; execute

memrd   lda  (temp),y
        sta  data
        lda  cmdsiz
        cmp  #6
        bcc  m30

        ldx  cmdbuf+5
        dex
        beq  m30

        txa
        clc
        adc  temp
        inc  temp
        sta  lstchr+errchn
        lda  temp
        sta  cb+2
        lda  temp+1
        sta  cb+3
        jmp  ge20

m30     jsr  fndrch
        jmp  ge15

cmer    lda  #badcmd    ; bad command
        jmp  cmderr

memwrt  lda  cmdbuf+6,y ; write
        sta  (temp),y   ; transfer from cmdbuf
        iny
        cpy  cmdbuf+5   ; # of bytes to write
        bcc  memwrt

        rts
