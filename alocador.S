.section .data
topoInicialHeap: .quad 0
inicio_heap:     .quad 0
espaco: .byte ' '
livre: .byte '-'
ocupado: .byte '+'
header: .byte '#'
quebra_linha: .byte '\n'

.section .bss
lista_livres:    .skip 8
lista_ocupados:  .skip 8
buffer:          .skip 1

.section .text
.global iniciaAlocador, finalizaAlocador
.global alocaMem, liberaMem, imprimeMapa

.equ SYS_BRK, 12
.equ HEADER_SIZE, 24

# iniciaAlocador:
# Salva o topo inicial da heap e inicializa ponteiros das listas
iniciaAlocador:
    mov $SYS_BRK, %rax
    xor %rdi, %rdi
    syscall
    mov %rax, topoInicialHeap(%rip)
    mov %rax, inicio_heap(%rip)
    movq $0, lista_livres(%rip)
    movq $0, lista_ocupados(%rip)
    ret

# finalizaAlocador:
# Restaura a heap ao valor inicial
finalizaAlocador:
    mov topoInicialHeap(%rip), %rdi
    mov $SYS_BRK, %rax
    syscall
    ret

# alocaMem(int size)
# Aloca memória de tamanho >= size
alocaMem:
    push %rbp
    mov %rsp, %rbp

    mov %rdi, %r12          # r12 = tamanho requisitado
    mov lista_livres(%rip), %r13  # r13 = ptr para percorrer lista de livres
    movq $0, %r15           #maior tamanho
    movq $0, %r10


//.loop_busca:
//    test %r13, %r13 // if lista_livre == 0
//    je .aloca_novo_bloco
//    mov 8(%r13), %r14       # tamanho do bloco
//    cmp %r12, %r14
//    jl .proximo

.loop_busca:
    test %r13, %r13 // if lista_livre == 0
    je .verificacao
    mov 8(%r13), %r14       # tamanho do bloco
    cmp %r12, %r14
    jl .proximo             # se não cabe, proximo
    cmp %r14, %r15
    jl .muda_maior

.proximo:
    mov 16(%r13), %r13
    jmp .loop_busca

.verificacao:
    test %r10, %r10         #verifica se achou algum capaz
    je .aloca_novo_bloco


.achou:
    # Achou bloco adequado
    mov %r10, %r13
    movb $1, (%r13) #marca como ocupado
    call remover_da_lista_livres
    call inserir_lista_ocupados
    mov %r13, %rax
    add $HEADER_SIZE, %rax
    pop %rbp
    ret

//.proximo:
//    mov 16(%r13), %r13
//    jmp .loop_busca


.muda_maior:
    mov %r14, %r15      #novo tamanho
    mov %r13, %r10      #ponteiro para o bloco
    jmp .proximo


# Não encontrou bloco adequado
.aloca_novo_bloco:
    mov %r12, %r14
    add $HEADER_SIZE, %r14  # tamanho + header
    mov $SYS_BRK, %rax
    mov $0, %rdi        
    syscall
    mov %rax, %r15         # endereço do novo bloco
    add %r14, %rax
    mov %rax, %rdi          #rdi = novo topo
    mov $SYS_BRK, %rax
    syscall

    movb $1, (%r15)         #ocupado
    mov %r12, 8(%r15)       #escreve tamanho
    movq $0, 16(%r15)        #NULL
    mov %r15, %r13
    call inserir_lista_ocupados
    mov %r15, %rax          
    add $HEADER_SIZE, %rax  #retorna em rax o começo do espaço alocado
    pop %rbp
    ret

# liberaMem(void* ptr)
# Libera o bloco e tenta fusão
liberaMem:
    push %rbp
    mov %rsp, %rbp
    mov %rdi, %rax
    sub $HEADER_SIZE, %rax
    movb $0, (%rax)           # marca como livre
    mov %rax, %r13
    call remover_da_lista_ocupados
    call inserir_lista_livres
    call funde_blocos_livres
    mov $0, %eax
    pop %rbp
    ret

imprimeMapa:
    push %rbp
    mov %rsp, %rbp

    mov inicio_heap(%rip), %r14 #avança na heap
    mov $SYS_BRK, %rax          # syscall: brk
    xor %rdi, %rdi
    syscall
    mov %rax, %r15
.print_blocos:
    cmp %r15, %r14 #compara inicio com o fim da heap
    jae .done



.print_header:
    lea header(%rip), %rsi   # passa o que printar como parametro
    movq $1, %rdi      # passa o tamanho 
    call print

.print_bytes:
    mov 8(%r14), %r10       # tamanho da área
    mov (%r14), %al         # verifica se é + ou -
    cmp $1, %al
    je .ocupado
    lea livre(%rip), %rsi
    mov %r10, %rdi
    jmp .print
.ocupado:
    lea ocupado(%rip), %rsi
    mov %r10, %rdi
.print:
    call print
    lea espaco(%rip), %rsi  #imprime o espaço após cada bloco
    mov $1, %rdi
    call print

.imprime_prox:

    mov 8(%r14), %r11
    add $HEADER_SIZE, %r14
    add %r11, %r14
    jmp .print_blocos

.done:
    lea quebra_linha(%rip), %rsi
    mov $2, %rdi
    call print
    popq %rbp
    ret

# ------------------------
# Funções auxiliares abaixo
# ------------------------





# void print(int vezes, char *caractere)
print:
    push %rbp
    mov %rsp, %rbp

    mov %rdi, %rbx        # quantas vezes
    mov %rsi, %r12        # o que quer printar
    xor %r13, %r13        # contador

.print_loop:
    cmp %r13, %rbx
    je .fim_print_loop

    mov %r12, %rsi        # endereço
    mov $1, %rdx          # tamanho
    mov $1, %rax          # syscall write
    mov $1, %rdi          # stdout
    syscall

    inc %r13
    jmp .print_loop

.fim_print_loop:
    pop %rbp
    ret




# inserir_lista_ocupados: insere r13 na lista_ocupados
inserir_lista_ocupados:
    mov lista_ocupados(%rip), %rax
    mov %rax, %r14 //antecessor
    cmp $0, %r14
    je .primeiro_ocupados
    cmp %r14, %r13
    jl .insere_cabeca_ocupados
.loop_busca_ocupados:
    mov 16(%rax), %rax
    #mov %rcx, %rax
    cmp $0, %rax
    je .insere_fim_ocupados
    cmp %rax, %r13
    jl .insere_ocupados
    mov 16(%r14), %r14
    jmp .loop_busca_ocupados

.primeiro_ocupados:
    mov %r13, lista_ocupados(%rip)
    ret


.insere_cabeca_ocupados:
    mov %r14, 16(%r13)
    mov %r13, lista_ocupados(%rip)
    ret
.insere_ocupados:
    mov %r13, %rcx
    mov %rcx, 16(%r14)
    mov %rax, 16(%r13)
    ret
.insere_fim_ocupados: //verificar o ponteiro para o nada
    mov %r13, 16(%r14)
    ret



# insere r13 na lista_livres em ordem
inserir_lista_livres:
    mov lista_livres(%rip), %rax
    mov %rax, %r14 //antecessor
    cmp $0, %r14
    je .primeiro_livres
    cmp %r14, %r13
    jl .insere_cabeca_livres
.loop_busca_livres:
    mov 16(%rax), %rax
    #mov %rcx, %rax
    cmp $0, %rax
    je .insere_fim_livres
    cmp %rax, %r13
    jl .insere_livres
    mov 16(%r14), %rcx
    mov %rcx, %r14
    jmp .loop_busca_livres

.primeiro_livres:
    mov %r13, lista_livres(%rip)
    ret


.insere_cabeca_livres:
    mov %r14, 16(%r13)
    mov %r13, lista_livres(%rip)
    ret
.insere_livres:
    mov %r13, %rcx
    mov %rcx, 16(%r14)
    mov %rax, 16(%r13)
    ret
.insere_fim_livres: //verificar o ponteiro para o nada
    mov %r13, 16(%r14)
    ret



# remover_da_lista_ocupados: remove r13 de lista_ocupados
remover_da_lista_ocupados:

    mov lista_ocupados(%rip), %r14
    cmp %r14, %r13
    je .remove_inicio_ocupados
.next_lf_ocupados:
    mov %r14, %r15
    mov 16(%r14), %r14  #avança lista 
    cmp %r14, %r13
    jne .next_lf_ocupados
    mov 16(%r13), %rax
    mov %rax, 16(%r15)
    movq $0, 16(%r13)
    ret
.remove_inicio_ocupados:
    mov 16(%r13), %rax
    mov %rax, lista_ocupados(%rip)
    movq $0, 16(%r13)
    ret
   

# remover_da_lista_livres: remove r13 de lista_livres
remover_da_lista_livres:
    mov lista_livres(%rip), %r14
    cmp %r14, %r13
    je .remove_inicio_livres
.next_lf_livres:
    mov %r14, %r15
    mov 16(%r14), %r14  #avança lista 
    cmp %r14, %r13
    jne .next_lf_livres
    mov 16(%r13), %rax
    mov %rax, 16(%r15)
    movq $0, 16(%r13)
    ret
.remove_inicio_livres:
    mov 16(%r13), %rax
    mov %rax, lista_livres(%rip)
    movq $0, 16(%r13)
    ret

# funde_blocos_livres: percorre e funde blocos contíguos
funde_blocos_livres:
    mov lista_livres(%rip), %rdi
.fusao_loop:
    mov 16(%rdi), %rax  
    test %rax, %rax
    je .fundo
    mov 8(%rdi), %rsi #tamanho do bloco
    lea (%rdi, %rsi, 1), %rax 
    add $HEADER_SIZE, %rax # rax chega no proximo bloco
    mov 16(%rdi), %rdx
    cmp %rax, %rdx #compara o prox bloco com prox da lista
    jne .next
    mov 8(%rdx), %rcx #tam do prox da lista
    add %rcx, %rsi
    add $HEADER_SIZE, %rsi #soma tudo
    mov %rsi, 8(%rdi)
    mov 16(%rdx), %rcx
    mov %rcx, 16(%rdi) #aponta para o prox da lista
    jmp .fusao_loop
.next:
    mov 16(%rdi), %rdi #move para o prox da lista
    jmp .fusao_loop
.fundo:
    ret
