; Paradoxon Basic C64 cartridge file
; https://github.com/c1570/ParadoxonBasicCRT
; https://www.c64-wiki.com/wiki/Paradoxon_Basic
; xa65 assembler syntax
; * fast reset (no mem test)
; * does not overwrite BASIC on reset
; * fixes RND(0)
; * fixes function key handling

	* = $0000

        .asc "C64 CARTRIDGE   "
        .byt $00,$00,$00,$40,$01,$00,$00,$03
        .byt $01,$01
        .byt $00,$00,$00,$00,$00,$00
        .asc "Paradoxon Basic+ 2022",$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; ------------- CHIP0
        .byt "CHIP",$00,$00,$40,$10,$00,$00,$00
        .byt $00
        .byt $80,$00
        .byt $40,$00

        * = $8000
        .word cold_start
        .word warm_start
        .byt $c3,$c2,$cd,$38,$30
cold_start:
        sei
        lda #$40
        sta $dfff  ; activate game and exrom lines
        lda #$33
        sta $01    ; enable cart low, cart high, charset rom, kernal rom
        lda #$2f
        sta $00    ; set cpu port to output
        lda #$00
        sta $22
        sta $24
        lda #$90
        sta $23
        lda #$d0
        sta $25
        ldy #$00
copyloop:
        lda ($22),y
        sta ($24),y
        iny
        bne copyloop
        inc $23
        inc $25
        bne copyloop ; if dest addr overflows we're done


; disable RAM test for faster startup
        lda #$86   ; 86 62  STX $62
        sta $fe86
        lda #$62
        sta $fe87
        lda #$ea   ; EA     NOP
        ldx #$14
noploop:
        sta $fe88,x
        dex
        bpl noploop


; fix RND(0) at F09E (was E09E): make it read from CIA not RAM
        ldx #$00
rndfixloop:
        lda rndpatch,x
        sta $f09e,x
        inx
        cpx #(rndpatchend-rndpatch)
        bne rndfixloop
        beq fctnkeysfix
rndpatch:
        sei
        inc $01
        lda $dc04
        sta $62
        lda $dc05
        sta $64
        lda $dc08
        sta $63
        lda $dc09
        sta $65
        dec $01
        cli
        jmp $f0e3
rndpatchend=*


; fix function keys which were active on running BASIC program
fctnkeysfix:
        ldx #$00
fctnkeysfix1loop:
        lda fctnkeyspatch1,x
        sta $d480,x
        inx
        cpx #(fctnkeyspatch1end-fctnkeyspatch1)
        bne fctnkeysfix1loop
        ldx #$00
fctnkeysfix2loop:
        lda fctnkeyspatch2,x
        sta $fd7e,x
        inx
        cpx #(fctnkeyspatch2end-fctnkeyspatch2)
        bne fctnkeysfix2loop
        jmp trampoline

fctnkeyspatch1:
ld480	jmp ($0302)
ld483	ldx #$ff
	stx $3a    ; patch - set 3a to ff before calling INLIN
	jsr $d560
	stx $7a
	sty $7b
	jsr $0073
	tax
	beq ld480
fctnkeyspatch1end=*

fctnkeyspatch2:
	lda $3a
	cmp #$ff
	bne lfdd4  ; patch - exit if not in direct mode
lfd7e	cpx #$ff
	beq lfda9
lfd82	ldx $c6
	beq lfdd4
lfd86	lda $0276,x
	cmp #$85
	bcc lfdd4
lfd8d	cmp #$8d
	bcs lfdd4
lfd91	sbc #$83
	sta $fe
	dec $c6
lfd97	sec
	sbc #$01
	asl
	asl
	asl
	asl
	asl
	sta $fd2e
	adc #$1f
	sta $fd2f
	bne lfdd4
lfda9	lda $028d ; patch from here: rewrite to have space for direct mode check at beginning
	lsr       ; SHIFT flag goes to carry
	and #$02  ; CTRL pressed?
	beq lfdd4 ; no, exit
	lda $cb   ; 0..63 - F7=3,F1=4,F3=5,F5=6
	rol       ; F1=8,F2=9,F3=0a,F4=0b,F5=0c,F6=0d,F7=6,F8=7
	cmp #$0e
	bcs lfdd4
	cmp #$06
	bcc lfdd4
	tax
	lda $fdc6,x ; fdc6+6 is ftable
	sta $fe
	bne lfd97
	.byt $00,$00 ; filler
ftable:	.byt $84,$88,$81,$85,$82,$86,$83,$87
lfdd4	jmp $02fb
fctnkeyspatch2end=*


trampoline:
        ldx #11
tcloop: lda scrc,x
        sta $0400,x
        dex
        bpl tcloop
        jmp $0400
scrc:
        lda #$35
        sta $01
        lda #$f0    ; deactive game and exrom lines
        sta $dfff
        jmp ($fffc)


warm_start: rts

        endat9000:
        * = $9000
        .dsb (*-endat9000), 0
        .bin 2,$3000,"dump_d000_ffff.prg"

; ------------- CHIP1
        .byt "CHIP",$00,$00,$40,$10,$00,$00,$00
        .byt $01
        .byt $80,$00
        .byt $40,$00
        * = $8000
endofchip1:
        * = $C000
        .dsb (*-endofchip1), 0

; ------------- CHIP2
        .byt "CHIP",$00,$00,$40,$10,$00,$00,$00
        .byt $02
        .byt $80,$00
        .byt $40,$00
        * = $8000
endofchip2:
        * = $C000
        .dsb (*-endofchip2), 0

; ------------- CHIP3
        .byt "CHIP",$00,$00,$40,$10,$00,$00,$00
        .byt $03
        .byt $80,$00
        .byt $40,$00
        * = $8000
endofchip3:
        * = $C000
        .dsb (*-endofchip3), 0
