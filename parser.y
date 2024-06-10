%{
#include "main.h"

void yyerror(const char *s);
extern int yylex();
extern int yyparse();

#define MAX_SYMBOLS 1024


Symbol symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

int addSymbol(const char *name, SymbolType valueType) {
    if (symbolCount < MAX_SYMBOLS) {
        strcpy(symbolTable[symbolCount].name, name);
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

void printSymbolVal(Symbol *symbol)
{
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
    }
}

%}

%union {
    Symbol          symbol;
    int             intNum;
    float           realNum;
    char            charVal;
    int             boolVal;
    char*           id;
}

%token FUN MAIN PRINT CLASS RET
%token VAR VAL BOOL CHAR INT REAL B_TRUE B_FALSE
%token PLUS MINUS ASTERISK DIVIDE
%token ASSIGN EQUAL INEQUAL GREATER LESS GREATER_EQUAL LESS_EQUAL COMMA SEMICOLON COLON
%token LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE

%token <intNum>     INTEGER
%token <realNum>    REALNUMBER
%token <id>         IDENTIFIER

%type <symbol> value expr assignment type

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
      VAR IDENTIFIER COLON type                 { addSymbol($2, $4.type); fprintf(yyout, " %s", $2); }
    | VAR IDENTIFIER COLON type ASSIGN expr     { addSymbol($2, $4.type); fprintf(yyout, " %s = ", $2); printSymbolVal(&$6); } 
    ;

type:
      BOOL                              { $$.type = TYPE_BOOL; fprintf(yyout, "int");}
    | CHAR                              { $$.type = TYPE_CHAR; fprintf(yyout, "char");}
    | INT                               { $$.type = TYPE_INT; fprintf(yyout, "int");}
    | REAL                              { $$.type = TYPE_REAL; fprintf(yyout, "float");}
    ;

assignment:
      IDENTIFIER ASSIGN expr    { 
                                    fprintf(yyout, "%s = ", $1); 
                                    Symbol *s = findSymbol($1);
                                        if (s) {
                                            
                                        } else {
                                            yyerror("Error: undeclared variable" );
                                        }
                                    printSymbolVal(&$3); 
                                    
                                }        
    ;

expr:
      value                                                         { $$ = $1; }                              
    | expr PLUS expr                                                { fprintf(yyout, "+"); }
    | expr MINUS expr                                               { fprintf(yyout, "-"); } 
    | expr ASTERISK expr                                            { fprintf(yyout, "*"); } 
    | expr DIVIDE expr                                              { fprintf(yyout, "/"); }
    | MINUS { fprintf(yyout, "-"); } expr %prec UMINUS              { $$ = $3; }
    ;

print:
      PRINT LEFT_PAREN expr RIGHT_PAREN { 
                                            fprintf(yyout, "printf(");
                                            switch ($3.type) {
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
                                            }
                                            if($3.isVar){
                                                fprintf(yyout, "%s", $3.name);
                                                printf("%s", $3.name); 
                                            }
                                            else{
                                                printSymbolVal(&$3);
                                            }
                                            fprintf(yyout, ")");
                                        } 
    ;

value:
      REALNUMBER                        { $$.type = TYPE_REAL; $$.value.realNum = $1; $$.isVar = 0; }
    | INTEGER                           { $$.type = TYPE_INT; $$.value.intNum = $1; $$.isVar = 0; }
    | IDENTIFIER                        { 
                                            Symbol *s = findSymbol($1);
                                            if (s) {
                                                $$.type = s->type;
                                                strcpy($$.name, s->name);
                                                $$.isVar = 1;
                                            } else {
                                                yyerror("Error: undeclared variable" );
                                            } 
                                        } 
    ;

%%
