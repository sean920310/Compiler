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
    char *name;
    int isVar;
    int isArr;
    SymbolType type;
    SymbolValue value;
} Symbol;

typedef struct
{
    Symbol symbols[64];
    int symbolCount;
} ExprData;

typedef struct
{
    char *name;
    SymbolType type;
    Symbol value[100];
    int count;
} ArrayData;

void printSymbol(const Symbol *symbol);

void copyExpr(ExprData *des, const ExprData *src);

/*
    結合lhs + concatSymbol + rhs
    回傳給 result
*/
void concatExpr(ExprData *result, const ExprData *lhs, const ExprData *rhs, const char *concatChar);

// void operatExpr(ExprData *result, const ExprData *lhs, const ExprData *rhs, const char *op);

#endif
