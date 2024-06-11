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
        symbolTable[symbolCount].name = (char*)malloc(strlen(name) + 1);
        if (symbolTable[symbolCount].name != NULL) {
            strcpy(symbolTable[symbolCount].name, name);
        }
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
    if (arrayCount < MAX_SYMBOLS) {
        arrayTable[arrayCount].name = (char*)malloc(strlen(name) + 1);
        if (arrayTable[arrayCount].name != NULL) {
            strcpy(arrayTable[arrayCount].name, name);
        }
        arrayTable[arrayCount].type = valueType;
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

void modifyType(Symbol *symbol, SymbolType des)
{
    SymbolType src = symbol->type;
    switch (des)
    {
    case TYPE_INT:
        switch (src)
        {
        case TYPE_REAL:
            symbol->value.intNum = (int)symbol->value.realNum;
            break;
        case TYPE_BOOL:
            symbol->value.intNum = symbol->value.boolVal ? 1 : 0;
            break;
        case TYPE_CHAR:
            symbol->value.intNum = (int)symbol->value.charVal;
            break;
        default:
            printf("Error: Unsupported conversion to TYPE_INT.\n");
            return;
        }
        break;

    case TYPE_REAL:
        switch (src)
        {
        case TYPE_INT:
            symbol->value.realNum = (float)symbol->value.intNum;
            break;
        case TYPE_BOOL:
            symbol->value.realNum = symbol->value.boolVal ? 1.0f : 0.0f;
            break;
        case TYPE_CHAR:
            symbol->value.realNum = (float)symbol->value.charVal;
            break;
        default:
            printf("Error: Unsupported conversion to TYPE_REAL.\n");
            return;
        }
        break;

    case TYPE_BOOL:
        switch (src)
        {
        case TYPE_INT:
            symbol->value.boolVal = symbol->value.intNum != 0;
            break;
        case TYPE_REAL:
            symbol->value.boolVal = symbol->value.realNum != 0.0f;
            break;
        case TYPE_CHAR:
            symbol->value.boolVal = symbol->value.charVal != '\0';
            break;
        case TYPE_STRING:
            symbol->value.boolVal = strlen(symbol->value.strVal) > 0;
            free(symbol->value.strVal);
            break;
        default:
            printf("Error: Unsupported conversion to TYPE_BOOL.\n");
            return;
        }
        break;

    case TYPE_CHAR:
        switch (src)
        {
        case TYPE_INT:
            symbol->value.charVal = (char)symbol->value.intNum;
            break;
        case TYPE_REAL:
            symbol->value.charVal = (char)symbol->value.realNum;
            break;
        case TYPE_BOOL:
            symbol->value.charVal = symbol->value.boolVal ? '1' : '0';
            break;
        default:
            printf("Error: Unsupported conversion to TYPE_CHAR.\n");
            return;
        }
        break;
    }
    symbol->type = des;
}

SymbolValue operateSymbolVal(const SymbolValue lhs, const SymbolValue rhs, const char *op)
{
    SymbolValue result;
    if (strcmp(op, "+") == 0)
    {
        result.intNum = lhs.intNum + rhs.intNum;
        result.realNum = lhs.realNum + rhs.realNum;
    }
    else if (strcmp(op, "-") == 0)
    {
        result.intNum = lhs.intNum - rhs.intNum;
        result.realNum = lhs.realNum - rhs.realNum;
    }
    else if (strcmp(op, "*") == 0)
    {
        result.intNum = lhs.intNum * rhs.intNum;
        result.realNum = lhs.realNum * rhs.realNum;
    }
    else if (strcmp(op, "/") == 0)
    {
        result.intNum = lhs.intNum / rhs.intNum;
        result.realNum = lhs.realNum / rhs.realNum;
    }
    return result;
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

void operatExpr(ExprData *result, const ExprData *lhs, const ExprData *rhs, const char *op)
{
    int arrOp = 0;
    for (int i = 0; i < lhs->symbolCount; i++)
    {
        if (!arrOp && lhs->symbols[i].isArr)
        {
            arrOp = 1;
            break;
        }
    }
    for (int i = 0; i < rhs->symbolCount; i++)
    {
        if (!arrOp && rhs->symbols[i].isArr)
        {
            arrOp = 1;
            break;
        }
    }
    printf("isArr: %d", arrOp);
    if (arrOp)
    {
        if (lhs->symbolCount > 1 || rhs->symbolCount > 1)
            return;
        const ArrayData *lArr = findArray(lhs->symbols[0].name);
        const ArrayData *rArr = findArray(rhs->symbols[0].name);
        addArray("c==3", lArr->type);
        ArrayData *resultArr = findArray("c==3");
        if (strcmp(op, "+") == 0)
        {
            int count = lArr->count > rArr->count ? lArr->count : rArr->count;
            
            result->symbolCount = 1;
            result->symbols->isArr = 1;
            strcpy(result->symbols->name, "c==3");

            for (int i = 0; i < count; i++)
            {
                SymbolValue empty;
                SymbolValue lVal = i > lArr->count - 1 ? empty : lArr->value[i].value;
                SymbolValue rVal = i > rArr->count - 1 ? empty : rArr->value[i].value;
                SymbolValue resultVal = operateSymbolVal(lVal, rVal, op);
                resultArr->value[i].value = resultVal;
            }
        }
        else if (strcmp(op, "*") == 0)
        {
        }
    }
    else
    {
        concatExpr(result, lhs, rhs, op);
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
%nonassoc UMINUS

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
                                                                                                                addSymbol($2, $4);
                                                                                                                addArray($2, $4); 
                                                                                                                fprintf(yyout, " %s[%d] = {", $2, $6);
                                                                                                                ArrayData* arr = findArray($2); 
                                                                                                                memcpy(arr->value, $10.value, $10.count);
                                                                                                                arr->count = $10.count;
                                                                                                                for(int i=0;i<$10.count;i++){
                                                                                                                    Symbol* symbol = &($10.value[i]);
                                                                                                                    if(symbol->type != arr->type){
                                                                                                                        modifyType(symbol, arr->type);
                                                                                                                    }
                                                                                                                    printSymbol(symbol);
                                                                                                                    if(i != $10.count - 1){
                                                                                                                        fprintf(yyout, ", ");
                                                                                                                    }
                                                                                                                }
                                                                                                                fprintf(yyout, "}");
                                                                                                                Symbol *s = findSymbol($2);
                                                                                                                if (s) {
                                                                                                                    s->isArr = 1;
                                                                                                                } else {
                                                                                                                    yyerror("Error: undeclared variable" );
                                                                                                                }
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
    | expr PLUS expr                                                { operatExpr(&($$), &($1), &($3), "+"); }
    | expr MINUS expr                                               { concatExpr(&($$), &($1), &($3), "-"); } 
    | expr ASTERISK expr                                            { concatExpr(&($$), &($1), &($3), "*"); } 
    | expr DIVIDE expr                                              { concatExpr(&($$), &($1), &($3), "/"); }
    | LEFT_PAREN expr RIGHT_PAREN                                   { 
                                                                        concatExpr(&($$), nullptr, &($2), "(");
                                                                        ExprData temp = $$;
                                                                        concatExpr(&($$), &(temp), nullptr, ")");
                                                                    }
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
                                                $$.isArr = s->isArr;
                                            } else {
                                                yyerror("Error: undeclared variable" );
                                            } 
                                        }  
    | MINUS value %prec UMINUS          { 

                                            $$ = $2;
                                            switch ($2.type)
                                            {
                                            case TYPE_INT:
                                                $$.value.intNum = -$2.value.intNum;
                                                break;
                                            case TYPE_REAL:
                                                $$.value.realNum = -$2.value.realNum;
                                                break;
                                            }
                                        }
    ;

%%
