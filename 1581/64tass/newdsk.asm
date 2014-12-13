; new: initialize a disk, disk is
;  soft-sectored, bit avail. map,
;  dir, & 1st block are all inited

new     jsr  onedrv
        lda  fildrv     ; set up drive #
        bpl  n10

        lda  #badfn     ; bad drive # given
        jmp  cmderr

n10     lda  #0
        sta  nodrv      ; clr drive status
	sta  wpstat	; and write protect status
        jsr  setlds
        ldx  #0         ; drv 0
        ldy  filtbl+1   ; get disk id
        cpy  cmdsiz     ; is this new or clear?
        beq  n20        ; next if new

        lda  cmdbuf,y   ; format disk
        sta  dskid,x    ; store in proper drive
        lda  cmdbuf+1,y ; (y=0)
        sta  dskid+1,x
	jsr  clrchn	; clear all channels
	jsr  jintdsk	; init disk
        jsr  format     ; format disk
	jsr  clrbam	; zero bam
        jmp  n30

n20	jsr  jintdsk	; init disk
	jsr  initdr     ; clear directory only
        lda  dskver     ; use current version #
        cmp  vernum
        beq  n30

        jmp  vnerr      ; wrong version #

n30     lda  jobnum
        tay
        asl  a
        tax
        lda  dsknam     ; set ptr to disk name
        sta  buftab,x
        ldx  filtbl
        lda  #27
        jsr  trname     ; transfer cmd buf to bam
        ldy  #0
        sty  dirbuf     ; reset lsb
        lda  dirtrk
        sta  (dirbuf),y ; directory track
        iny
	lda  #sysdirsec
    	sta  dirst
        sta  (dirbuf),y ; link to first dir blk
        iny
        lda  vernum
        sta  dskver
        sta  (dirbuf),y ; format type
        iny
        lda  #0         ; null
        sta  (dirbuf),y
        ldy  #22        ; skip name
        lda  dskid
        sta  (dirbuf),y ; set the disk id '3d'
        iny
        lda  dskid+1
        sta  (dirbuf),y
        iny
        lda  #160       ; shifted space
        sta  (dirbuf),y
        iny
        lda  dosver
        sta  (dirbuf),y
        iny
        lda  dskver
        sta  (dirbuf),y
        iny
        lda  #160       ; shftd space
        sta  (dirbuf),y
        iny
        sta  (dirbuf),y
        iny
        lda  #0         ; nulls
n32     sta  (dirbuf),y ; clr remaining
        iny
        bne  n32

        lda  #00
        jsr  settrk     ; dirtrk, 00
        jsr  drtwrt     ; write it out
        lda  #0
        sta  dirbuf     ; lsb reset
        tay     	; set up 1st dir blk
n34     sta  (dirbuf),y
        iny
        bne  n34

        iny     	; set sector link
        lda  #$ff
        sta  (dirbuf),y
        lda  dirst	; wrt it to dirtrk
        jsr  settrk
        jsr  drtwrt
        jsr  newmap     ; build new bam
	lda  dirtrk
	sta  track
	lda  #0
	sta  sector	; allocate 3 sectors & directory sector
	jsr  wused	; 0
	inc  sector
	jsr  wused	; 1
	inc  sector
	jsr  wused	; 2

	lda  dirst
	sta  sector
	jsr  wused	; 3 usually
        jsr  bamout     ; write the bams
	jsr  initdr	; read it back
        jmp  endcmd

settrk  sta  sector
        lda  dirtrk
        sta  track
        rts

clrbam	lda  #0
	tay
-	sta  bam1,y	; zero
	sta  bam2,y
	iny
	bne  -

	rts
