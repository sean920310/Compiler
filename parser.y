%{
#include "main.h"

void yyerror(const char *s);
extern int yylex();
extern int yyparse();

#define MAX_SYMBOLS 512
#define MAX_ARRAYS 512
#define YYDEDUG 1

Symbol symbolTable[MAX_SYMBOLS];
ArrayData arrayTable[MAX_ARRAYS];
int symbolCount = 0;
int arrayCount = 0;

int addSymbol(const char *name, SymbolType valueType) {
    if (symbolCount < MAX_SYMBOLS) {
        symbolTable[symbolCount].name = strdup(name);
        symbolTable[symbolCount].type = valueType;
        symbolCount++;
        return 0; // success
    }
    return -1; // symbol table full
}

Symbol* findSymbol(const char *name) {
    for (int i = 0; i < symbolCount; i++) {
        if (strcmp(symbolTable[i].name, name) == 0) {
            return &symbolTable[i];
        }
    }
    return NULL; // not found
}

int addArray(const char *name, SymbolType valueType) {
    if (symbolCount < MAX_SYMBOLS) {
        arrayTable[symbolCount].name = strdup(name);
        arrayTable[symbolCount].type = valueType;
        arrayCount++;
        return 0; // success
    }
    return -1; // array table full
}

ArrayData* findArray(const char *name) {
    for (int i = 0; i < arrayCount; i++) {
        if (strcmp(arrayTable[i].name, name) == 0) {
            return &arrayTable[i];
        }
    }
    return NULL; // not found
}

void printSymbol(const Symbol *symbol)
{
    if(symbol->isVar){
        fprintf(yyout, "%s", symbol->name);
        printf("%s", symbol->name); 
    }
    else{
        switch (symbol->type)
        {
        case TYPE_INT:
            fprintf(yyout, "%d", symbol->value.intNum);
            break;
        case TYPE_REAL:
            fprintf(yyout, "%f", symbol->value.realNum);
            break;
        case TYPE_BOOL:
            fprintf(yyout, "%d", symbol->value.boolVal);
            break;
        case TYPE_CHAR:
            fprintf(yyout, "%c", symbol->value.charVal);
            break;
        case TYPE_STRING:
            fprintf(yyout, "%s", symbol->value.strVal);
            break;
        }
    }
}

void copyExpr(ExprData *des, const ExprData *src)
{
    memcpy(des->symbols, src->symbols, src->symbolCount);
    des->symbolCount = src->symbolCount;
}

void concatExpr(ExprData *result, const ExprData *lhs = nullptr, const ExprData *rhs = nullptr, const char *concatChar = nullptr)
{
    result->symbolCount = 0;
    if(lhs != nullptr)
    {
        for (int i = 0; i < lhs->symbolCount; i++)
        {
            result->symbols[i] = lhs->symbols[i];
        }
        result->symbolCount = lhs->symbolCount;
    }

    if (concatChar != nullptr)
    {
        Symbol charSymbol;
        charSymbol.isVar = 1;
        charSymbol.name = strdup(concatChar);
        result->symbols[result->symbolCount] = charSymbol;
        result->symbolCount++;
    }

    if(rhs != nullptr)
    {
        for (int i = 0; i < rhs->symbolCount; i++)
        {
            result->symbols[result->symbolCount + i] = rhs->symbols[i];
        }
        result->symbolCount += rhs->symbolCount;
    }
}

%}

%union {
    Symbol          symbol;
    int             intNum;
    float           realNum;
    char            charVal;
    int             boolVal;
    char*           strVal;
    SymbolType      symbolType;
    ExprData        exprData;
    ArrayData       arrData;
}

%token FUN MAIN PRINT PRINTLN CLASS RET
%token VAR VAL BOOL CHAR INT REAL B_TRUE B_FALSE
%token PLUS MINUS ASTERISK DIVIDE
%token ASSIGN EQUAL INEQUAL GREATER LESS GREATER_EQUAL LESS_EQUAL COMMA SEMICOLON COLON
%token LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE

%token <intNum>     INTEGER
%token <realNum>    REALNUMBER
%token <strVal>     STRING
%token <strVal>     IDENTIFIER

%type <symbol> value assignment
%type <symbolType> type
%type <exprData> expr
%type <arrData> array


%left PLUS MINUS
%left ASTERISK DIVIDE
%right UMINUS

%%

program:
      { fprintf(yyout, "#include <stdio.h>\n#include <stdlib.h>\n"); } main
    ;
    
main:
      FUN MAIN LEFT_PAREN RIGHT_PAREN LEFT_BRACE { fprintf(yyout, "int main() {\n"); } func RIGHT_BRACE { fprintf(yyout, "}"); } 
    ;

func:
      
    | stmt_list                  
    ;

stmt_list:
      stmt SEMICOLON                    { fprintf(yyout, ";\n"); }
    | stmt_list stmt SEMICOLON          { fprintf(yyout, ";\n"); }
    ;

stmt:
      expr            
    | declare
    | assignment 
    | print
    ;

declare:
      VAR IDENTIFIER COLON type                 { addSymbol($2, $4); fprintf(yyout, " %s", $2); }
    | VAR IDENTIFIER COLON type ASSIGN expr     { 
                                                    addSymbol($2, $4);
                                                    fprintf(yyout, " %s = ", $2); 
                                                    for (int i = 0; i < $6.symbolCount; i++) {
                                                        const Symbol* symbol = &($6.symbols[i]);
                                                        printSymbol(symbol); 
                                                    }
                                                } 
    | VAR IDENTIFIER COLON type LEFT_BRACKET INTEGER RIGHT_BRACKET ASSIGN LEFT_BRACE array RIGHT_BRACE      { 
                                                                                                                addArray($2, $4); 
                                                                                                                fprintf(yyout, " %s[%d] = {", $2, $6);
                                                                                                                ArrayData* arr = findArray($2); 
                                                                                                                memcpy(arr->value, $10.value, $10.count);
                                                                                                                arr->count = $10.count;
                                                                                                                for(int i=0;i<$10.count;i++){
                                                                                                                    Symbol* symbol = &($10.value[i]);
                                                                                                                    printSymbol(symbol);
                                                                                                                    if(i != $10.count - 1){
                                                                                                                        fprintf(yyout, ", ");
                                                                                                                    }
                                                                                                                }
                                                                                                                fprintf(yyout, "}");

                                                                                                            }
    ;


assignment:
      IDENTIFIER ASSIGN expr    { 
                                    fprintf(yyout, "%s = ", $1); 
                                    Symbol *s = findSymbol($1);
                                        if (s) {
                                            
                                        } else {
                                            yyerror("Error: undeclared variable" );
                                        }
                                    for (int i = 0; i < $3.symbolCount; i++) {
                                        const Symbol* symbol = &($3.symbols[i]);
                                        printSymbol(symbol); 
                                    }
                                    
                                }        
    ;

type:
      BOOL                              { $$ = TYPE_BOOL; fprintf(yyout, "int");}
    | CHAR                              { $$ = TYPE_CHAR; fprintf(yyout, "char");}
    | INT                               { $$ = TYPE_INT; fprintf(yyout, "int");}
    | REAL                              { $$ = TYPE_REAL; fprintf(yyout, "float");}
    ;

array:
      value                             { $$.count = 1; $$.value[0] = $1; }                                                 
    | array COMMA value                 { 
                                            memcpy($$.value, $1.value, $1.count);
                                            $$.value[$1.count] = $3;
                                            $$.count = $1.count + 1;
                                        }

expr:
      value                                                         { $$.symbols[0] = $1; $$.symbolCount = 1; }                              
    | expr PLUS expr                                                { concatExpr(&($$), &($1), &($3), "+"); }
    | expr MINUS expr                                               { concatExpr(&($$), &($1), &($3), "-"); } 
    | expr ASTERISK expr                                            { concatExpr(&($$), &($1), &($3), "*"); } 
    | expr DIVIDE expr                                              { concatExpr(&($$), &($1), &($3), "/"); }
    | LEFT_PAREN expr RIGHT_PAREN                                   { 
                                                                        concatExpr(&($$), nullptr, &($2), "(");
                                                                        ExprData temp = $$;
                                                                        concatExpr(&($$), &(temp), nullptr, ")");
                                                                    }
    | MINUS expr %prec UMINUS                                       { concatExpr(&($$), nullptr, &($2), "-"); }
    ;

print:
      PRINT LEFT_PAREN expr RIGHT_PAREN     { 
                                                fprintf(yyout, "printf(");
                                                SymbolType pType = NONE;
                                                for (int i = 0; i < $3.symbolCount; i++) {
                                                    const Symbol* symbol = &($3.symbols[i]);
                                                    if (pType == NONE){
                                                        pType = symbol->type;
                                                    }
                                                }
                                                switch (pType) {
                                                case TYPE_INT:
                                                    fprintf(yyout, "\"%%d\", ");
                                                    break;
                                                case TYPE_REAL:
                                                    fprintf(yyout, "\"%%f\", ");
                                                    break;
                                                case TYPE_BOOL:
                                                    fprintf(yyout, "\"%%d\", ");
                                                    break;
                                                case TYPE_CHAR:
                                                    fprintf(yyout, "\"%%c\", ");
                                                    break;
                                                case TYPE_STRING:
                                                    fprintf(yyout, "\"%%s\", ");
                                                    break;
                                                }
                                                for (int i = 0; i < $3.symbolCount; i++) {
                                                    const Symbol* symbol = &($3.symbols[i]);
                                                    printSymbol(symbol);
                                                }
                                                fprintf(yyout, ")");
                                            } 
    | PRINTLN LEFT_PAREN expr RIGHT_PAREN   {
                                                fprintf(yyout, "printf(");
                                                SymbolType pType  = NONE;
                                                for (int i = 0; i < $3.symbolCount; i++) {
                                                    const Symbol* symbol = &($3.symbols[i]);
                                                    if (pType == NONE){
                                                        pType = symbol->type;
                                                    }
                                                }
                                                switch (pType) {
                                                case TYPE_INT:
                                                    fprintf(yyout, "\"%%d\\n\", ");
                                                    break;
                                                case TYPE_REAL:
                                                    fprintf(yyout, "\"%%f\\n\", ");
                                                    break;
                                                case TYPE_BOOL:
                                                    fprintf(yyout, "\"%%d\\n\", ");
                                                    break;
                                                case TYPE_CHAR:
                                                    fprintf(yyout, "\"%%c\\n\", ");
                                                    break;
                                                case TYPE_STRING:
                                                    fprintf(yyout, "\"%%s\\n\", ");
                                                    break;
                                                }
                                                for (int i = 0; i < $3.symbolCount; i++) {
                                                    const Symbol* symbol = &($3.symbols[i]);
                                                    printSymbol(symbol);
                                                }
                                                fprintf(yyout, ")");
                                            } 
    ;

value:
      REALNUMBER                        { $$.type = TYPE_REAL; $$.value.realNum = $1; $$.isVar = 0; }
    | INTEGER                           { $$.type = TYPE_INT; $$.value.intNum = $1; $$.isVar = 0; }
    | STRING                            { $$.type = TYPE_STRING; $$.value.strVal = strdup($1); $$.isVar = 0;}
    | IDENTIFIER                        { 
                                            Symbol *s = findSymbol($1);
                                            if (s) {
                                                $$.type = s->type;
                                                $$.name = strdup(s->name);
                                                $$.isVar = 1;
                                            } else {
                                                yyerror("Error: undeclared variable" );
                                            } 
                                        }  
    | MINUS REALNUMBER %prec UMINUS     { $$.type = TYPE_REAL; $$.value.realNum = -$2; $$.isVar = 0; }
    | MINUS INTEGER %prec UMINUS        { $$.type = TYPE_INT; $$.value.intNum = -$2; $$.isVar = 0; }
    
    ;

%%
