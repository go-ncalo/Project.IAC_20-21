;===============================================================================
; Jogo "Dino"
;
; Grupo 12
;
; Gonçalo Mateus - 99225
; Guilherme Patrão - 99230
;===============================================================================
; CONSTANTES
;===============================================================================
; STACK POINTER
STACKPOINTER    EQU     6000h

; Altura máxima
ALTURAMAX       EQU     4

; Terminal
TERM_READ       EQU     FFFFh
TERM_WRITE      EQU     FFFEh
TERM_STATUS     EQU     FFFDh
TERM_CURSOR     EQU     FFFCh
TERM_COLOR      EQU     FFFBh

; Mostradores de 7 segmentos
DISP7_D0        EQU     FFF0h
DISP7_D1        EQU     FFF1h
DISP7_D2        EQU     FFF2h
DISP7_D3        EQU     FFF3h
DISP7_D4        EQU     FFEEh
DISP7_D5        EQU     FFEFh

; Temporizador
TIMER_CONTROL   EQU     FFF7h
TIMER_COUNTER   EQU     FFF6h
TIMER_SETSTART  EQU     1
TIMER_SETSTOP   EQU     0
TIMERCOUNT_INIT EQU     1

; Jogo
GAME_START      EQU     1
GAME_STOP       EQU     0
DINO_JUMP       EQU     1
DINO_JUMPD      EQU     0

; Mask
INT_MASK        EQU     FFFAh
INT_MASK_VAL    EQU     80FFh 
              
; Dimensão do terreno
dimensao        EQU     79


;===============================================================================
; VARIÁVEIS/POSIÇÕES DE MEMÓRIA
;===============================================================================
                ORIG    1000h
DIGITO1         WORD    0
DIGITO2         WORD    0
DIGITO3         WORD    0
DIGITO4         WORD    0
DIGITO5         WORD    0
DIGITO6         WORD    0
                
                
                ORIG    0000h
; Seed inicial
SEED            WORD    5

; Jogo
GAME_CONTROL    WORD    0
DINO_AIR        WORD    0
altura_dino     WORD    0
POSICAO_DINO    WORD    2405h

; Terreno
                ORIG    4000h
terreno         TAB     80
                
; Temporizador                
                ORIG    0008h
TIMER_COUNTVAL  WORD    TIMERCOUNT_INIT 
TIMER_TICK      WORD    0               
                                        
TIME            WORD    0

;===============================================================================
; CÓDIGO
;===============================================================================

                ORIG    0000h
                ; interrupcoes
                MVI     R1,INT_MASK
                MVI     R2,INT_MASK_VAL
                STOR    M[R1],R2
                ENI
                
                MVI     R6, STACKPOINTER
                
;===============================================================================
; status: rotina que inicia o jogo caso GAME_CONTROL seja 1.
;===============================================================================
status:         MVI     R1, GAME_CONTROL
                LOAD    R1, M[R1]
                CMP     R1, R0
                BR.Z    status
                
                JAL     main
                
;===============================================================================
; atualizajogo: rotina que atualiza o terreno do jogo movendo todos os elementos
;               uma posição para a esquerda.
;===============================================================================                
atualizajogo:   MVI     R5, 2500h
                DEC     R6
                STOR    M[R6], R7
                
                DEC     R6
                STOR    M[R6], R5
                
                DEC     R6
                STOR    M[R6], R1 ; guardar o argumento inicial R1
                
                DEC     R6
                STOR    M[R6], R2 ; guardar o argumento inicial R2

.loop:          INC     R1 

                LOAD    R5, M[R1]
                DEC     R1 
                
                STOR    M[R1], R5
                INC     R1
                
; após as instrucões de cima, R1 fica com o valor da posição à sua direita

                DEC     R2
                CMP     R2, R0
                BR.NZ   .loop ; assegura que o loop acima se repete 79 vezes
                
                MVI     R1, ALTURAMAX ; altura máxima
                MVI     R2, SEED
                
                JAL     geracacto ; R3 = valor gerado por geracacto
                
                LOAD    R2, M[R6] ; restaurar valor do arg inicial R2 - dimensao
                INC     R6
                
                LOAD    R1, M[R6] ; restaurar valor do arg inicial R1 - terreno
                INC     R6
                
                ADD     R1, R1, R2 ; última posição da tabela
                
                STOR    M[R1], R3 ; colocar em R1 o valor gerado pela geracacto
                
                SUB     R1, R1, R2 ; voltar à primeira posição da tabela
                
                LOAD    R5, M[R6]
                INC     R6
                
                LOAD    R7, M[R6] ; restaurar valor de R7
                INC     R6
                
                INC     R2
                
                JMP     R7
                
;===============================================================================
; geracacto: rotina que gera um número pseudo-aleatório.
;===============================================================================
geracacto:      LOAD    R4, M[R2]

                DEC     R6
                STOR    M[R6], R5
                
                DEC     R6
                STOR    M[R6], R1
                
                MVI     R5, 1
                AND     R5, R4, R5 ; bit = x AND 1
                SHR     R4 ; x = x >> 1
                
                STOR    M[R2], R4 ; guardar o valor de x // 2
                
                MVI     R4, 1
                CMP     R5, R4
                LOAD    R4, M[R2] ; restaurar o valor R4
                BR.NZ   .if ; if bit != x: goto .final
                
                
                ; if bit == x :
                MVI     R5, B400h
                XOR     R4, R4, R5 ; x = XOR(x, B400h)
                                
.if:            MVI     R5, 62258
                CMP     R4, R5
                BR.C    .zero ; if x < 62258: goto .zero
                
                ; return 
                DEC     R1 ; altura - 1 
                AND     R3, R4, R1 ; return x AND (altura - 1)
                INC     R3 ; return (x AND (altura - 1)) + 1

; finalizar a funcao, carregar os valores e voltar para o endereco de R7
.final:         STOR    M[R2], R4
                
                LOAD    R1, M[R6]
                INC     R6
                
                LOAD    R5, M[R6]
                INC     R6
                
                JMP     R7
                
; return 0 e finalizar a funcao para o caso de x < 62258                
.zero:          MOV     R3, R0
                BR      .final

;===============================================================================
; temporizador: rotina que inica o temporizador.
;===============================================================================
temporizador:   DEC     R6
                STOR    M[R6], R7
                
                DEC     R6 
                STOR    M[R6], R3
                
                DEC     R6 
                STOR    M[R6], R1
                
                DEC     R6
                STOR    M[R6], R2
                
                MVI     R2,TIMERCOUNT_INIT
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2          ; define a velocidade de atualização
                                          ; do temporizador
                MVI     R1,TIMER_TICK
                STOR    M[R1],R0
                
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2          ; inicia o temporizador
                
                MVI     R5,TIMER_TICK
.LOOP:          LOAD    R1,M[R5]
                CMP     R1,R0
                JAL.NZ  .contagem
                BR      .LOOP
                
;===============================================================================
; contagem: atualiza o temporizador e mostra os valores no display de
;           7 segmentos.
;===============================================================================
.contagem:      MVI     R1,TIME ; Atualiza o tempo
                LOAD    R2,M[R1]
                INC     R2
                STOR    M[R1],R2
                
                MVI     R4, DIGITO1
                LOAD    R5, M[R4]
                INC     R5
                STOR    M[R4], R5
                MVI     R5, DISP7_D0
                MVI     R4, DIGITO1
                LOAD    R4, M[R4]
                STOR    M[R5], R4
                MVI     R3, 9
                CMP     R4, R3
                BR.Z    .zeroD1
                BR      .exitCont
                
.zeroD1:        MVI     R4, DIGITO1  
                STOR    M[R4], R0
                
                MVI     R4, DIGITO2
                LOAD    R5, M[R4]
                INC     R5
                STOR    M[R4], R5
                MVI     R5, DISP7_D1
                MVI     R4, DIGITO2
                LOAD    R4, M[R4]
                STOR    M[R5], R4
                
                MVI     R3, 9
                CMP     R4, R3
                BR.Z    .zeroD2
                BR      .exitCont
                
.zeroD2:        MVI     R4, DIGITO2
                STOR    M[R4], R0
                
                MVI     R4, DIGITO3
                LOAD    R5, M[R4]
                INC     R5
                STOR    M[R4], R5
                MVI     R5, DISP7_D2
                MVI     R4, DIGITO3
                LOAD    R4, M[R4]
                STOR    M[R5], R4
                MVI     R3, 9
                CMP     R4, R3
                BR.Z    .zeroD3
                BR      .exitCont

.zeroD3:        MVI     R4, DIGITO3
                STOR    M[R4], R0
                MVI     R4, DIGITO4
                LOAD    R5, M[R4]
                INC     R5
                STOR    M[R4], R5
                MVI     R5, DISP7_D3
                MVI     R4, DIGITO4
                LOAD    R4, M[R4]
                STOR    M[R5], R4
                MVI     R3, 9
                CMP     R4, R3
                BR.Z    .zeroD4
                BR      .exitCont
                
.zeroD4:        MVI     R4, DIGITO4
                STOR    M[R4], R0
                MVI     R4, DIGITO5
                LOAD    R5, M[R4]
                INC     R5
                STOR    M[R4], R5
                MVI     R5, DISP7_D4
                MVI     R4, DIGITO5
                LOAD    R4, M[R4]
                STOR    M[R5], R4
                MVI     R3, 9
                CMP     R4, R3
                BR      .exitCont
                
.exitCont:      LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                LOAD    R3, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
;===============================================================================
; desenhar: rotina que desenha o terreno de jogo no terminal.
;===============================================================================
desenhar:       DEC     R6
                STOR    M[R6], R7
                
.desenha:       DEC     R6
                STOR    M[R6], R1
                DEC     R6
                STOR    M[R6], R2
                DEC     R6
                STOR    M[R6], R5
                LOAD    R3, M[R1]
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                STOR    M[R2], R5
                MVI     R4, 2505h
                CMP     R5, R4
                BR.NZ   .comp
                MVI     R4, 219
                STOR    M[R1], R4
                BR.Z    dino          
.comp:          CMP     R3, R0
                BR.Z    .des_terreno
                MVI     R4, 100h
                SUB     R5, R5, R4
                STOR    M[R2], R5
                BR.NZ   .des_cactos
                
.des_terreno:   MVI     R4, 219
                STOR    M[R1], R4
                MVI     R3, 4
                
.loop:          MVI     R4, 100h
                SUB     R5, R5, R4
                STOR    M[R2], R5
                MVI     R4, 255
                STOR    M[R1], R4
                DEC     R3
                CMP     R3, R0
                BR.NZ   .loop
                BR      .final
                
.des_cactos:    MVI     R4, 4006h
                CMP     R4, R0
                MVI     R4, 204
                STOR    M[R1], R4
                MVI     R4, 100h
                SUB     R5, R5, R4
                STOR    M[R2], R5
                DEC     R3
                CMP     R3, R0
                BR.NZ   .des_cactos
                
.final:         LOAD    R5, M[R6]
                INC     R6
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                INC     R1
                INC     R5
                DEC     R2
                CMP     R2, R0
                BR.NZ   .desenha
                
                MVI     R1, terreno
                MVI     R2, dimensao                
                LOAD    R7, M[R6]
                INC     R6
                JMP     R7
                
;===============================================================================
; dino: desenha o dinossauro na sua posição.
;===============================================================================                
dino:           MVI     R4, altura_dino
                LOAD    R4, M[R4]
                CMP     R4, R0
                BR.NZ   .sem_dino
                MVI     R4, 100h
                SUB     R5, R5, R4
                STOR    M[R2], R5
                MVI     R4, 'D'
                STOR    M[R1], R4
                MVI     R4, 2405h
                CMP     R4, R5
                BR.Z    desenhar.final
                JMP     R7

.sem_dino:       MVI     R4, 219
                STOR    M[R1], R4
                BR      desenhar.final
                
;===============================================================================
; movimento: rotina que desenha as diversas posições enquanto o dinossauro está
;            a saltar.
;===============================================================================                
movimento:      DEC     R6
                STOR    M[R6], R7
                
                DEC     R6 
                STOR    M[R6], R5
                
                DEC     R6
                STOR    M[R6], R4
                
                DEC     R6 
                STOR    M[R6], R1
                
                DEC     R6
                STOR    M[R6], R2
                
                DSI
                MVI     R4, DINO_AIR
                LOAD    R1, M[R4]
                MVI     R5, 1
                CMP     R1, R5
                BR.Z    .salto
                MVI     R5, -1
                CMP     R1, R5
                BR.Z    .fazerdescer
                BR      .exitd

.fazerdescer:   MVI     R3, POSICAO_DINO
                LOAD    R3, M[R3]
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                MVI     R5, 100h
                MVI     R4, ' '
                STOR    M[R2], R3
                STOR    M[R1], R4
                MVI     R4, 'D'
                ADD     R3, R3, R5
                STOR    M[R2], R3
                STOR    M[R1], R4
                MVI     R4, POSICAO_DINO
                STOR    M[R4], R3
                
                MVI     R4, altura_dino
                LOAD    R5, M[R4]
                DEC     R5
                STOR    M[R4], R5
                
                LOAD    R4, M[R4]
                CMP     R4, R0
                BR.Z    .velocidade0
                BR      .exitd
                
.salto:        
                MVI     R3, POSICAO_DINO
                LOAD    R3, M[R3]

                
.loop:          DEC     R6
                STOR    M[R6], R4
                DEC     R6
                STOR    M[R6], R5
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                MVI     R5, 100h
                MVI     R4, ' '
                STOR    M[R2], R3
                STOR    M[R1], R4
                MVI     R4, 'D'
                SUB     R3, R3, R5
                STOR    M[R2], R3
                STOR    M[R1], R4
                MVI     R4, POSICAO_DINO
                STOR    M[R4], R3
                
                MVI     R4, altura_dino
                LOAD    R5, M[R4]
                INC     R5
                STOR    M[R4], R5
                
                MVI     R5, 5
                LOAD    R4, M[R4]
                CMP     R4, R5
                BR.NZ   .exitsalto
                
                MVI     R4, DINO_AIR
                MVI     R5, -1
                STOR    M[R4], R5
                
.exitsalto:     LOAD    R5, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                BR      .exitd
                
.velocidade0:   MVI     R4, DINO_AIR
                STOR    M[R4], R0
                
.exitd:         ENI
                LOAD    R2, M[R6]
                INC     R6
                
                LOAD    R1, M[R6]
                INC     R6
                
                LOAD    R4, M[R6]
                INC     R6
                
                LOAD    R5, M[R6]
                INC     R6
                
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7
                
;===============================================================================
; colisao: rotina que verifica se o dinossauro colidiu com algum cacto.
;===============================================================================
colisao:        DEC     R6 
                STOR    M[R6], R7
                
                DEC     R6 
                STOR    M[R6], R1
                
                DEC     R6
                STOR    M[R6], R2
                
                MVI     R1, altura_dino
                LOAD    R1, M[R1]
                MVI     R2, 4006h
                LOAD    R2, M[R2]
                CMP     R1, R2
                JMP.N   gameover
                
                LOAD    R2, M[R6]
                INC     R6
                
                LOAD    R1, M[R6]
                INC     R6
                
                LOAD    R7, M[R6]
                INC     R6
                
                JMP     R7

;===============================================================================
; gameover: rotina que acaba o jogo.
;===============================================================================
gameover:       DEC     R6
                STOR    M[R6], R7
                
                DEC     R6 
                STOR    M[R6], R5
                
                DEC     R6
                STOR    M[R6], R4
                
                DEC     R6 
                STOR    M[R6], R1
                
                DEC     R6
                STOR    M[R6], R2
                
                MVI     R1, TERM_WRITE
                MVI     R2, TERM_CURSOR
                MVI     R4, 1520h
                STOR    M[R2], R4

                MVI 	R4, 'G'
                STOR 	M[R1], R4

                MVI 	R4, ' '
                STOR 	M[R1], R4

                MVI 	R4, 'A'
                STOR 	M[R1], R4

                MVI 	R4, ' '
                STOR 	M[R1], R4

                MVI 	R4, 'M'
                STOR 	M[R1], R4

                MVI 	R4, ' '
                STOR 	M[R1], R4

                MVI 	R4, 'E'
                STOR 	M[R1], R4

                MVI     R5, 4
.loop:          MVI 	R4, ' '
                STOR 	M[R1], R4
                DEC     R5
                CMP     R5, R0
                BR.NZ   .loop

                MVI 	R4, 'O'
                STOR 	M[R1], R4

                MVI 	R4, ' '
                STOR 	M[R1], R4

                MVI 	R4, 'V'
                STOR 	M[R1], R4

                MVI 	R4, ' '
                STOR 	M[R1], R4

                MVI 	R4, 'E'
                STOR 	M[R1], R4

                MVI 	R4, ' '
                STOR 	M[R1], R4
                
                MVI     R4, 'R'
                STOR    M[R1], R4

                MVI     R4, GAME_CONTROL
                MVI     R5, GAME_STOP
                STOR    M[R4], R5
                
                LOAD    R2, M[R6]
                INC     R6
                LOAD    R1, M[R6]
                INC     R6
                LOAD    R4, M[R6]
                INC     R6
                LOAD    R5, M[R6]
                INC     R6
                LOAD    R7, M[R6]
                INC     R6
                JMP     status
                
;===============================================================================
; temp_auxiliar: rotina auxiliar para interrupções causadas pelo temporizador.
;===============================================================================   
temp_auxiliar:  DEC     R6
                STOR    M[R6],R1
                
                DEC     R6
                STOR    M[R6],R2
                
                ; RESTART TIMER
                MVI     R1,TIMER_COUNTVAL
                LOAD    R2,M[R1]
                MVI     R1,TIMER_COUNTER
                STOR    M[R1],R2          ; set timer to count value
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2          ; start timer
                ; INC TIMER FLAG
                MVI     R2,TIMER_TICK
                LOAD    R1,M[R2]
                INC     R1
                STOR    M[R2],R1
                ; RESTORE CONTEXT
                
                LOAD    R2,M[R6]
                INC     R6
                
                LOAD    R1,M[R6]
                INC     R6
                
                JMP     R7

;===============================================================================
; TRATAMENTO DE INTERRUPÇÕES
;===============================================================================
                ORIG    7FF0h
timer:          DEC     R6
                STOR    M[R6],R7
                ; CALL AUXILIARY FUNCTION
                JAL     temp_auxiliar
                
                LOAD    R7,M[R6]
                INC     R6
                
                RTI
                
                ORIG    7F00h
botao_zero:     DEC     R6
                STOR    M[R6], R1
                
                DEC     R6
                STOR    M[R6], R2
                
                DEC     R6
                STOR    M[R6], R4
                
                DEC     R6
                STOR    M[R6], R5
                
                MVI     R4, GAME_CONTROL
                MVI     R5, GAME_START
                STOR    M[R4], R5
                MVI     R1,TIMER_CONTROL
                MVI     R2,TIMER_SETSTART
                STOR    M[R1],R2
                
                LOAD    R5, M[R6]
                INC     R6
                
                LOAD    R4, M[R6]
                INC     R6
                
                LOAD    R2, M[R6]
                INC     R6
                
                LOAD    R1, M[R6]
                INC     R6
                
                RTI
                
                ORIG    7F30h  
tecla_up:       DEC     R6
                STOR    M[R6],R7
                
                DEC     R6
                STOR    M[R6],R5
                
                DEC     R6
                STOR    M[R6],R4
                
                MVI     R4, DINO_AIR
                LOAD    R4, M[R4]
                CMP     R4, R0
                BR.NZ   .exitint
                MVI     R4, DINO_AIR
                MVI     R5, DINO_JUMP
                STOR    M[R4], R5
                
.exitint:       ; RESTORE CONTEXT
                LOAD    R4,M[R6]
                INC     R6
                
                LOAD    R5,M[R6]
                INC     R6
                
                LOAD    R7,M[R6]
                INC     R6
                
                RTI
                
;===============================================================================
; PROGRAMA PRINCIPAL
;===============================================================================                
main:           MVI     R1, TERM_CURSOR
                MVI     R4, FFFFh
                STOR    M[R1], R4
                MVI     R1, terreno
                MVI     R2, dimensao
                MVI     R4, 5
                
loop:           JAL     temporizador

                JAL     atualizajogo
                
                JAL     desenhar
                
                JAL     colisao
                
                JAL     movimento
                
                BR      loop
                
Fim:            BR      Fim
