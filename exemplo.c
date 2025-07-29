#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a, *b, *c, *d, *e, *f, *g, *h;

  iniciaAlocador();              
  imprimeMapa();                

  a = (void *) alocaMem(10);
  imprimeMapa();
  b = (void *) alocaMem(4);
  c = (void *) alocaMem(14);
  d = (void *) alocaMem(10);
  e = (void *) alocaMem(8);
  f = (void *) alocaMem(28);
  imprimeMapa();
                          
  liberaMem(a);
  liberaMem(c);
  liberaMem(e);
  imprimeMapa();
  liberaMem(f);
  liberaMem(d);
  imprimeMapa();
  g = (void *) alocaMem(60 + 73);
  imprimeMapa();
  liberaMem(b);
  imprimeMapa();
  finalizaAlocador();
}
