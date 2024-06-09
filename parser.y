%{
#include "main.h"

void yyerror(const char *s);
extern int yylex();
extern int yyparse();

%}

%union {
    int     intNum;
    float   realNum;
}

%token FUN MAIN PRINT
%token PLUS MINUS ASTERISK DIVIDE
%token ASSIGN EQUAL INEQUAL GREATER LESS GREATER_EQUAL LESS_EQUAL COMMA SEMICOLON COLON
%token LEFT_PAREN RIGHT_PAREN LEFT_BRACKET RIGHT_BRACKET LEFT_BRACE RIGHT_BRACE

%token <intNum>   INTEGER
%token <realNum> REALNUMBER

%type <realNum> value expr

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
      
    | stmt                  
    ;

stmt:
    stmt SEMICOLON
    | expr                  { printf("Result: %f\n", $1); }
    ;


expr:
      value                 { $$ = $1; }
    | expr PLUS expr         { $$ = $1 + $3; }
    | expr MINUS expr         { $$ = $1 - $3; }
    | expr ASTERISK expr         { $$ = $1 * $3; }
    | expr DIVIDE expr         { $$ = $1 / $3; }
    | MINUS expr %prec UMINUS { $$ = -$2; }
    | PRINT LEFT_PAREN expr RIGHT_PAREN { printf($3;}
    ;

value:
      REALNUMBER                 { $$ = $1; }
    | INTEGER               { $$ = (float)$1; }
    ;

%%
