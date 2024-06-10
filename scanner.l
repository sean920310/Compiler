%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "main.h"
    #include "parser.tab.h"
    void yyerror(const char *s);
    int lineNum = 1;
    #define MAX_STRING 2

    char stringBuffer[MAX_STRING] = {0};
    int stringCount = 0;

%}

%x COMMENT
%x STRINGS
%x MULTI_LN_COMMENT
ESCAPE_SEQ          [nt\'\"\?\\]
DIGIT               [0-9]  
INT                 (0|[1-9]{DIGIT}*)
REAL                {DIGIT}+"."{DIGIT}+
IDENTIFIER          [_a-zA-Z][a-zA-Z0-9_]*
WRONG_IDENTIFIER    {DIGIT}+{IDENTIFIER}



%%

\/\/                { BEGIN COMMENT; }
<COMMENT>\n         { BEGIN 0; printf("\n"); lineNum++; }
<COMMENT>.          { ; }

\"                      { BEGIN STRINGS; stringBuffer[0] = '"', stringBuffer[1] = '\0';}
<STRINGS>\"             { printf("<STRINGS>"); strcat(stringBuffer, "\""); yylval.strVal = strdup(stringBuffer); BEGIN 0; return STRING; }
<STRINGS>\\\n           { strcat(stringBuffer, yytext); stringCount += 2; lineNum++; }
<STRINGS>\n             { yyerror("Missing \" "); yyterminate(); }
<STRINGS><<EOF>>        { yyerror("Missing \" "); yyterminate(); }
<STRINGS>\\\"           { strcat(stringBuffer, yytext); stringCount++; }
<STRINGS>.              { strcat(stringBuffer, yytext); stringCount++; }

\/\*                        { BEGIN MULTI_LN_COMMENT; }
<MULTI_LN_COMMENT><<EOF>>   { yyerror("Missing */ "); yyterminate(); }
<MULTI_LN_COMMENT>\*\/      { BEGIN 0; }       
<MULTI_LN_COMMENT>.         { ; }

"var"               { printf("<VAR>"); return VAR; }
"val"               { printf("<VAL>"); return VAL; }
"bool"              { printf("<BOOL>"); return BOOL; }
"char"              { printf("<CHAR>"); return CHAR; }
"int"               { printf("<INT>"); return INT; }
"real"              { printf("<REAL>"); return REAL; }
"true"              { printf("<TRUE>"); return B_TRUE; }
"false"             { printf("<FALSE>"); return B_FALSE; }
"class"             { printf("<CLASS>"); return CLASS; }
"fun"               { printf("<FUN>"); return FUN; }
"main"              { printf("<MAIN>"); return MAIN; }
"print"             { printf("<PRINT>"); return PRINT; }
"println"           { printf("<PRINTLN>"); return PRINTLN; }
"ret"               { printf("<RET>"); return RET; }

"if"                { printf("<IF>"); }
"else"              { printf("<ELSE>"); }
"for"               { printf("<FOR>"); }
"while"             { printf("<WHILE>"); }
"do"                { printf("<DO>"); }
"switch"            { printf("<SWITCH>"); }
"case"              { printf("<CASE>"); }

"+"                 { printf("<PLUS>"); return PLUS; }
"-"                 { printf("<MINUS>"); return MINUS; }
"*"                 { printf("<ASTERISK>"); return ASTERISK; }
"/"                 { printf("<DIVIDE>"); return DIVIDE; }

"="                 { printf("<ASSIGN>"); return ASSIGN; }
"=="                { printf("<EQUAL>"); return EQUAL; }
"!="                { printf("<INEQUAL>"); return INEQUAL; }
">"                 { printf("<GREATER>"); return GREATER; }
"<"                 { printf("<LESS>"); return LESS; }
">="                { printf("<GREATER_EQUAL>"); return GREATER_EQUAL; }
"<="                { printf("<LESS_EQUAL>"); return LESS_EQUAL; }
","                 { printf("<COMMA>"); return COMMA; }
";"                 { printf("<SEMICOLON>"); return SEMICOLON; }
":"                 { printf("<COLON>"); return COLON; }


"("                 { printf("<LEFT_PAREN>"); return LEFT_PAREN; }
")"                 { printf("<RIGHT_PAREN>"); return RIGHT_PAREN; }
"["                 { printf("<LEFT_BRACKET>"); }
"]"                 { printf("<RIGHT_BRACKET>"); }
"{"                 { printf("<LEFT_BRACE>"); return LEFT_BRACE; }
"}"                 { printf("<RIGHT_BRACE>"); return RIGHT_BRACE; }

\n                  { lineNum++; printf("\n");}
\'\\{ESCAPE_SEQ}\'  { printf("<ESCAPE_SEQ>"); }
\'.\'               { printf("<CHARACTER>"); }
{WRONG_IDENTIFIER}  { yyerror("Wrong identifier name"); yyterminate();}
{IDENTIFIER}        { printf("<IDENTIFIER>"); yylval.strVal = strdup(yytext); return IDENTIFIER;}
{INT}               { printf("<INTEGER>"); sscanf(yytext, "%d", &(yylval.intNum)); return INTEGER; }
{REAL}              { printf("<REALNUMBER>"); sscanf(yytext, "%f", &(yylval.realNum)); return REALNUMBER; }

[ ]                 { printf(" "); }
\t                  { printf("\t"); }

.                   { yyerror("Unexpected character"); yyterminate();}

%%

int yywrap(void) {
    return 1;
}

void yyerror(const char *s) {
    printf("ERROR ln%d: %s : %s\n", lineNum, s, yytext);
}