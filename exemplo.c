#include <stdio.h>
#include "meuAlocador.h"

int main (long int argc, char** argv) {
  void *a, *b, *c, *d, *e, *f, *g, *h;

  iniciaAlocador();               // Impressão esperada
                                  //
  imprimeMapa();                  // <vazio>

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
  //g = (void *) alocaMem(96 + 47);
  //imprimeMapa();
  //liberaMem(f);
  //imprimeMapa();
  //h = (void *) alocaMem(96 + 46 + 24 + 28);
  //imprimeMapa();
  //liberaMem(g);
  //imprimeMapa();
  //liberaMem(h);
  //imprimeMapa();
  //h = (void *) alocaMem(96 + 46 + 24 + 28 + 24 + 96 + 48);
  //imprimeMapa();
  //liberaMem(h);
  
  liberaMem(b);
    

  finalizaAlocador();
}
