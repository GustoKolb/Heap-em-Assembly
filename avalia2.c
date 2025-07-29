#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a,*b,*c,*d,*e;

  iniciaAlocador();
  imprimeMapa();
  // 0) estado inicial

  a=(void *) alocaMem(10);
  imprimeMapa();
  b=(void *) alocaMem(30);
  imprimeMapa();
  c=(void *) alocaMem(20);
  imprimeMapa();
  d=(void *) alocaMem(40);
  imprimeMapa();
  e =(void *) alocaMem(50);
  imprimeMapa();
  // 1) Espero ver quatro segmentos ocupados

  liberaMem(a);
  imprimeMapa();
  liberaMem(c);
  imprimeMapa();
  liberaMem(e);
  imprimeMapa();
  // 2) Espero ver quatro segmentos alternando
  //    ocupados e livres

  //b virou a
  a=(void *) alocaMem(5);
  imprimeMapa();
  //d virou c
  c=(void *) alocaMem(9);
  imprimeMapa();
  // 3) Deduzam

  liberaMem(c);
  imprimeMapa();
  liberaMem(a);
  imprimeMapa();
  liberaMem(b);
  imprimeMapa();
  liberaMem(d);
  imprimeMapa();
   // 4) volta ao estado inicial

  finalizaAlocador();
}
