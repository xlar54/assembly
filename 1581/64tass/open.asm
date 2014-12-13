;open channel from ieee
;  parses the input string that is
;  sent as an open data channel,
;  load, or save.  channels are allocated
;  and the directory is searched for
;  the filename contained in the string.

open    lda  sa
        sta  tempsa
        jsr  cmdset     ; initiate cmd ptrs
        stx  cmdnum
        ldx  cmdbuf
        lda  tempsa
        bne  op021

        cpx  #'*'       ; load last?
        bne  op021

        lda  prgtrk
        beq  op0415     ; no last prog, init 0

        sta  track      ; load last program
        lda  #0
        sta  fildrv
        lda  #prgtyp
        sta  pattyp
        lda  prgsec
        sta  sector
        jsr  setlds     ; make sure led gets turned on!!
        jsr  opnrch
        lda  #prgtyp+prgtyp
endrd   ldx  lindx
        sta  filtyp,y
        jmp  endcmd

op021   cpx  #'$'
        bne  op041

        lda  tempsa     ; load directory
        bne  op04

        jmp  loadir

op04    jsr  simprs     ; open dir as seq file
        lda  dirtrk
        sta  track
        lda  #0
        sta  sector
        jsr  opnrch
        lda  #seqtyp+seqtyp
        jmp  endrd

op041   cpx  #'#'       ; "#" is direct access
        bne  op042

        jmp  opnblk
op0415  lda  #prgtyp    ; program type
        sta  typflg
        jsr  initdr
op042   jsr  prscln     ; look for ":"
        bne  op049

        ldx  #0
        beq  op20       ; bra

op049   txa
        beq  op10

        lda  #badsyn    ; something amiss
        jmp  cmderr

op10    dey     	; back up to ":"
        beq  op20       ; 1st char is ":"

        dey
op20    sty  filtbl     ; save filename ptr
        lda  #$8d       ; look for cr-shifted
        jsr  parse
        inx
        stx  f2cnt
        jsr  onedrv
        jsr  optsch
        jsr  ffst       ; look for file entry
        ldx  #0
        stx  rec
        stx  mode       ; read mode
        stx  type       ; deleted
        inx
        cpx  f1cnt
        bcs  op40       ; no parameters

        jsr  cktm       ; check for type & mode
        inx
        cpx  f1cnt
        bcs  op40       ; only one parameter

        cpy  #reltyp
        beq  op60       ; set record size

        jsr  cktm       ; set type/mode
op40    ldx  tempsa
        stx  sa         ; set sa back
        cpx  #2
        bcs  op45       ; not load or save

        stx  mode       ; mode=sa
        lda  type
        bne  op50       ; type from parm

        lda  #prgtyp
        sta  type       ; use prg
op45    lda  type
        bne  op50       ; type from parm

        lda  pattyp
        and  #typmsk
        sta  type       ; type from file
        lda  filtrk
        bne  op50       ; yes, it exists

        lda  #seqtyp
        sta  type       ; default is seq
op50    lda  mode
        cmp  #wtmode
        beq  op75       ; go write

        jmp  op90

op60    ldy  filtbl,x   ; get record size
        lda  cmdbuf,y
        sta  rec
        lda  filtrk
        bne  op40       ; it's here, read

        lda  #wtmode    ; use write to open
        sta  mode
        bne  op40       ; (bra)

op75    lda  pattyp
        and  #$80
        tax
        bne  op81

        lda  #$20       ; open write
        bit  pattyp
        beq  op80

        jsr  deldir     ; created
        jmp  opwrit

op80    lda  filtrk
        bne  op81
        jmp  opwrit     ; not found, ok!

op81    lda  cmdbuf
        cmp  #'@'       ; check for replace
        beq  op82

        txa
        bne  op815

        lda  #flexst
        jmp  cmderr

op815   lda  #badfn
        jmp  cmderr

op82    lda  pattyp     ; replace
        and  #typmsk
        cmp  type
        bne  op115

        cmp  #reltyp
        beq  op115

        jsr  opnwch
        lda  lindx
        sta  wlindx
        lda  #irsa      ; internal chan
        sta  sa
        jsr  fndrch
        lda  index
        jsr  setpnt
        ldy  #0
        lda  (dirbuf),y
        ora  #$20       ; set replace bit
        sta  (dirbuf),y
        ldy  #26
        lda  track
        sta  (dirbuf),y
        iny
        lda  sector
        sta  (dirbuf),y
        ldx  wlindx
        lda  entsec
        sta  dsec,x
        lda  entind
        sta  dind,x
        jsr  curblk
        jsr  drtwrt
        jmp  opfin

op90    lda  filtrk     ; open read (& load)
        bne  op100

        lda  #flntfd    ; track not recorded
        jmp  cmderr     ; not found

op100   lda  mode
        cmp  #mdmode
        beq  op110

        lda  #$20
        bit  pattyp
        beq  op110

        lda  #filopn
        jmp  cmderr

op110   lda  pattyp
        and  #typmsk    ; type is in index table
        cmp  type
        beq  op120

op115   lda  #mistyp    ; type mismatch
        jmp  cmderr

op120   ldy  #0         ; everything is ok!
        sty  f2ptr
        ldx  mode
        cpx  #apmode
        bne  op125

        cmp  #reltyp
        beq  op115

        lda  (dirbuf),y
        and  #$4f
        sta  (dirbuf),y
        lda  sa
        pha
        lda  #irsa
        sta  sa
        jsr  curblk
        jsr  drtwrt
        pla
        sta  sa
op125   jsr  opread
        lda  mode
        cmp  #apmode
        bne  opfin

        jsr  append
        jmp  endcmd

opread  ldy  #19
        lda  (dirbuf),y
        sta  trkss
        iny
        lda  (dirbuf),y
        sta  secss
        iny
        lda  (dirbuf),y
        ldx  rec
        sta  rec
        txa
        beq  op130

        cmp  rec
        beq  op130

        lda  #norec
        jsr  cmderr

op130   ldx  f2ptr
        lda  filtrk,x
        sta  track
        lda  filsec,x
        sta  sector
        jsr  opnrch
        ldy  lindx      ; open a read chnl
        ldx  f2ptr
        lda  entsec,x
        sta  dsec,y
        lda  entind,x
        sta  dind,y
        rts
opwrit  jsr  opnwch
        jsr  addfil     ; add to directory
opfin   lda  sa
        cmp  #2
        bcs  opf1

        jsr  gethdr
        lda  track
        sta  prgtrk
        lda  sector
        sta  prgsec
opf1    jmp  endsav

cktm    ldy  filtbl,x   ; get ptr
        lda  cmdbuf,y   ; get char
        ldy  #nmodes
ckm1    dey
        bmi  ckm2       ; no valid mode

        cmp  modlst,y
        bne  ckm1

        sty  mode       ; mode found
ckm2    ldy  #ntypes
ckt1    dey
        bmi  ckt2       ; no valid type

        cmp  tplst,y
        bne  ckt1

        sty  type       ; type found
ckt2    rts

append  jsr  gcbyte
        lda  #lrf
        jsr  tstflg
        beq  append

        jsr  rdlnk
        ldx  sector
        inx
        txa
        bne  ap30

        jsr  wrt0       ; get another block

        lda  #2
ap30    jsr  setpnt
        ldx  lindx
        lda  #rdylst
        sta  chnrdy,x
        lda  #$80       ; chnl bit
        ora  lindx
        ldx  sa
        sta  lintab,x
        rts
; load directory
loadir  lda  #ldcmd
        sta  cmdnum
        lda  #0         ; load only drive zero
        ldx  cmdsiz
        dex
        beq  ld02

        dex     	; load by name
        bne  ld03

        lda  cmdbuf+1
        jsr  tst0v1
        bmi  ld03

ld02    sta  fildrv     ; ld dir with a star
        inc  f1cnt
        inc  f2cnt
        inc  filtbl
        lda  #$80
        sta  pattyp
        lda  #'*'
        sta  cmdbuf     ; cover both cases
        sta  cmdbuf+1
        bne  ld10       ; (branch)

ld03    jsr  prscln
        bne  ld05       ; found ":"

        jsr  cmdrst     ; search by name on both drives
        ldy  #3
ld05    dey
        dey
        sty  filtbl
        jsr  tc35       ; parse & set tables
        jsr  fs1set
        jsr  alldrs
ld10    jsr  optsch     ; new directory
        jsr  newdir
        jsr  ffst
        jsr  stdir      ; start directory
        jsr  getbyt     ; set 1st byte
        ldx  lindx
        sta  chndat,x
        lda  #4
        sta  filtyp,x
        lda  #0
        sta  buftab+cbptr
        rts
