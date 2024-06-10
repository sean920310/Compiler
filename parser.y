%{
#include "main.h"

void yyerror(const char *s);
extern int yylex();
extern int yyparse();
extern FILE *yyout;

#define MAX_SYMBOLS 1024

typedef enum { TYPE_INT, TYPE_REAL, TYPE_BOOL, TYPE_STRING } SymbolType;

typedef struct {
    char name[1024];
    SymbolType type;
    float value;
} Symbol;

Symbol symbolTable[MAX_SYMBOLS];
int symbolCount = 0;

int addSymbol(const char *name, float value) {
    if (symbolCount < MAX_SYMBOLS) {
        strcpy(symbolTable[symbolCount].name, name);
        symbolTable[symbolCount].value = value;
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

%}

%union {
    int     intNum;
    float   realNum;
    char    charVal;
    int     boolVal;
    char*   id;
}

%token FUN MAIN PRINT CLASS RET
%token VAR VAL BOOL CHAR INT REAL B_TRUE B_FALSE
%token PLUS MINUS ASTERISK DIVIDE
%token ASSIGN EQUAL INEQUAL GREATER LESS GREATER_EQUAL LESS_EQUAL COMMA SEMICOLON COLON
%token LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE

%token <intNum>   INTEGER
%token <realNum> REALNUMBER
%token <id> IDENTIFIER

%type <realNum> value expr assignment

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
      expr                              { printf("Result: %f\n", $1); }
    | declare 
    | assignment 
    | print
    ;

declare:
      VAR IDENTIFIER COLON type         { addSymbol($2, 0); fprintf(yyout, " %s", $2); }
    | VAR IDENTIFIER COLON type ASSIGN  { addSymbol($2, 0); fprintf(yyout, " %s = ", $2); } expr
    ;

type:
      BOOL                              { fprintf(yyout, "int");}
    | CHAR                              { fprintf(yyout, "char");}
    | INT                               { fprintf(yyout, "int");}
    | REAL                              { fprintf(yyout, "float");}
    ;

assignment:
      IDENTIFIER ASSIGN { fprintf(yyout, "%s = ", $1); } expr       { 
                                                                        Symbol *s = findSymbol($1);
                                                                            if (s) {
                                                                                s->value = $4;
                                                                                $$ = $4;
                                                                            } else {
                                                                                yyerror("Error: undeclared variable" );
                                                                            } 
                                                                    }        
    ;

expr:
      value                                                                     { $$ = $1; }
    | expr PLUS { fprintf(yyout, "+"); } expr                                   { $$ = $1 + $4; }
    | expr MINUS { fprintf(yyout, "-"); } expr                                  { $$ = $1 - $4; }
    | expr ASTERISK { fprintf(yyout, "*"); } expr                               { $$ = $1 * $4; }
    | expr DIVIDE { fprintf(yyout, "/"); } expr                                 { $$ = $1 / $4; }
    | MINUS { fprintf(yyout, "-"); } expr %prec UMINUS                          { $$ = -$3; }
    ;

print:
    | PRINT LEFT_PAREN { fprintf(yyout, "printf(\"%%f\", "); } expr RIGHT_PAREN { printf("%f", $4); fprintf(yyout, ")"); }

value:
      REALNUMBER                        { $$ = $1; fprintf(yyout, "%f", $1); }
    | INTEGER                           { $$ = (float)$1; fprintf(yyout, "%d", $1); }
    | IDENTIFIER                        { 
                                            Symbol *s = findSymbol($1);
                                                if (s) {
                                                    $$ = s->value;
                                                } else {
                                                    yyerror("Error: undeclared variable" );
                                                } 
                                            fprintf(yyout, "%s", s->name);
                                        } 
    ;

%%
