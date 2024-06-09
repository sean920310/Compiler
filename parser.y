%{
#include "main.h"

void yyerror(const char *s);
extern int yylex();
extern int yyparse();

#define MAX_SYMBOLS 256

typedef struct {
    char name[32];
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
    char*  id;
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
      main
    ;
    
main:
      FUN MAIN LEFT_PAREN RIGHT_PAREN LEFT_BRACE func RIGHT_BRACE { printf("\nend!!!\n"); }
    ;

func:
      
    | stmt_list                  
    ;

stmt_list:
      stmt SEMICOLON
    | stmt_list stmt SEMICOLON
    ;

stmt:
      expr                              { printf("Result: %f\n", $1); }
    | declare 
    | assignment 
    ;

declare:
      VAR IDENTIFIER COLON type         { addSymbol($2, 0); printf("Declared variable %s\n", $2); }
    ;

type:
      BOOL
    | CHAR
    | INT
    | REAL
    ;

assignment:
      IDENTIFIER ASSIGN expr            { 
                                            Symbol *s = findSymbol($1);
                                                if (s) {
                                                    s->value = $3;
                                                    $$ = $3;
                                                } else {
                                                    yyerror("Error: undeclared variable" );
                                                } 
                                        }        
    ;

expr:
      value                             { $$ = $1; }
    | expr PLUS expr                    { $$ = $1 + $3; }
    | expr MINUS expr                   { $$ = $1 - $3; }
    | expr ASTERISK expr                { $$ = $1 * $3; }
    | expr DIVIDE expr                  { $$ = $1 / $3; }
    | MINUS expr %prec UMINUS           { $$ = -$2; }
    | PRINT LEFT_PAREN expr RIGHT_PAREN { printf("%f", $3);}
    ;

value:
      REALNUMBER                        { $$ = $1; }
    | INTEGER                           { $$ = (float)$1; }
    | IDENTIFIER                        { 
                                            Symbol *s = findSymbol($1);
                                                if (s) {
                                                    $$ = s->value;
                                                } else {
                                                    yyerror("Error: undeclared variable" );
                                                } 
                                        } 
    ;

%%
