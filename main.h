#ifndef MAIN_H
#define MAIN_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

using namespace std;

extern FILE *yyout;

typedef enum
{
    TYPE_INT,
    TYPE_REAL,
    TYPE_BOOL,
    TYPE_CHAR
} SymbolType;

typedef union
{
    int intNum;
    float realNum;
    char charVal;
    int boolVal;
    char *id;
} SymbolValue;

typedef struct
{
    char name[1024];
    int isVar;
    SymbolType type;
    SymbolValue value;
} Symbol;

void printSymbolVal(Symbol *symbol);

#endif
