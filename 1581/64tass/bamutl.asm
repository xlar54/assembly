rdbam   lda  jobnum     ; save it
	sta  tmpjbn
	lda  bam1       ; is it in memory?
	bne  bamend     ; yes

	lda  #>(bam1-buff0)
	ldx  #1         ; sector
	jsr  setts
	jsr  doread
	lda  #>(bam2-buff0)
	ldx  #2         ; sec number
	jsr  setts
	jsr  doread
	jmp  bamend

bamout  lda  jobnum     ; save it
	sta  tmpjbn
	lda  #>(bam1-buff0)
	ldx  #1         ; sector
	jsr  setts
	jsr  dowrit
	lda  #>(bam2-buff0)
	ldx  #2         ; sector
	jsr  setts
	jsr  dowrit
bamend  lda  tmpjbn
	sta  jobnum     ; restore it
	lda  #0
	sta  wbam       ; it clean now!
	rts

rddir   jsr  mapout     ; wrt bams if dirty
	ldx  #0         ; sector
	lda  jobnum
	jsr  setts      ; set dir hdrs
	jsr  doread     ; rd in the dir
	jmp  rdbam      ; rd bams if not in memory

setts   sta  jobnum     ;
	stx  sector     ; set up t/s
	ldx  dirtrk     ; trk #18
	stx  track
	jmp  seth       ; setup hdrs

setbpt  jsr  rdbam      ; rd bam if not in memory
setbp2  lda  #>bam1     ; preset bam pointers
	sta  bmpnt+1
	lda  #0         ; default bam1 addr
	sta  bmpnt
	rts

numfre  lda  ndbl
	sta  nbtemp
	lda  ndbh
	sta  nbtemp+1
	rts
