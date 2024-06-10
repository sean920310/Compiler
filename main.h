#ifndef MAIN_H
#define MAIN_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

using namespace std;

extern FILE *yyout;

typedef enum
{
    NONE,
    TYPE_INT,
    TYPE_REAL,
    TYPE_BOOL,
    TYPE_CHAR,
    TYPE_STRING
} SymbolType;

typedef union
{
    int intNum;
    float realNum;
    char charVal;
    int boolVal;
    char *strVal;
} SymbolValue;

typedef struct
{
    char name[64];
    int isVar;
    SymbolType type;
    SymbolValue value;
} Symbol;

typedef struct
{
    Symbol symbols[512];
    int symbolCount;
} ExprData;

void printSymbol(const Symbol *symbol);

/*
    結合lhs + concatSymbol + rhs
    回傳給 result
*/
void concatExpr(ExprData *result, const ExprData *lhs, const ExprData *rhs, const char *concatChar);

#endif
