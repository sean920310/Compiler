%{
    #include <stdio.h>
    #include <stdlib.h>
    void yyerror(const char *s);
    int lineNum = 1;
%}

%x COMMENT
%x STRING
%x MULTI_LN_COMMENT
ESCAPE_SEQ          [nt\'\"\?\\]
DIGIT               [0-9]  
INT                 (0|[1-9]{DIGIT}*)
REAL                {DIGIT}+"."{DIGIT}+
IDENTIFIER          [_a-zA-Z][a-zA-Z0-9_]*
WRONG_IDENTIFIER    {DIGIT}+{IDENTIFIER}



%%

\/\/                { BEGIN COMMENT; }
<COMMENT>\n         { BEGIN 0; ECHO; lineNum++; }
<COMMENT>.          { ; }

\"                  { BEGIN STRING; }
<STRING>\"          { BEGIN 0; printf("<STRING>"); }
<STRING>\\\n        { lineNum++; }
<STRING>\n          { yyerror("Missing \" "); yyterminate(); }
<STRING><<EOF>>     { yyerror("Missing \" "); yyterminate(); }
<STRING>\\\"        { ; }
<STRING>.           { ; }

\/\*                        { BEGIN MULTI_LN_COMMENT; }
<MULTI_LN_COMMENT><<EOF>>   { yyerror("Missing */ "); yyterminate(); }
<MULTI_LN_COMMENT>\*\/      { BEGIN 0; }       
<MULTI_LN_COMMENT>.         { ; }

"var"               { printf("<VAR>"); }
"val"               { printf("<VAL>"); }
"bool"              { printf("<BOOL>"); }
"char"              { printf("<CHAR>"); }
"int"               { printf("<INT>"); }
"real"              { printf("<REAL>"); }
"true"              { printf("<TRUE>"); }
"false"             { printf("<FALSE>"); }
"class"             { printf("<CLASS>"); }
"fun"               { printf("<FUN>"); }
"ret"               { printf("<RET>"); }

"if"                { printf("<IF>"); }
"else"              { printf("<ELSE>"); }
"for"               { printf("<FOR>"); }
"while"             { printf("<WHILE>"); }
"do"                { printf("<DO>"); }
"switch"            { printf("<SWITCH>"); }
"case"              { printf("<CASE>"); }

"+"                 { printf("<PLUS>"); }
"-"                 { printf("<MINUS>"); }
"*"                 { printf("<ASTERISK>"); }
"/"                 { printf("<DIVIDE>"); }

"="                 { printf("<ASSIGN>"); }
"=="                { printf("<EQUAL>"); }
"!="                { printf("<INEQUAL>"); }
">"                 { printf("<GREATER>"); }
"<"                 { printf("<LESS>"); }
">="                { printf("<GREATER_EQUAL>"); }
"<="                { printf("<LESS_EQUAL>"); }
","                 { printf("<COMMA>"); }
";"                 { printf("<SEMICOLON>"); }
":"                 { printf("<COLON>"); }


"("                 { printf("<LEFT_PAREN>"); }
")"                 { printf("<RIGHT_PAREN>"); }
"["                 { printf("<LEFT_BRACKET>"); }
"]"                 { printf("<RIGHT_BRACKET>"); }
"{"                 { printf("<LEFT_BRACE>"); }
"}"                 { printf("<RIGHT_BRACE>"); }

\n                  { lineNum++; ECHO;}
\'\\{ESCAPE_SEQ}\'  { printf("<ESCAPE_SEQ>"); }
\'.\'               { printf("<CHARACTER>"); }
{WRONG_IDENTIFIER}  { yyerror("Wrong identifier name"); yyterminate();}
{IDENTIFIER}        { printf("<IDENTIFIER>"); }
{INT}               { printf("<INTEGER>"); }
{REAL}              { printf("<REALNUMBER>"); }

[ ]                 { ECHO; }
\t                  { ECHO; }

.                   { yyerror("Unexpected character"); yyterminate();}

%%

int yywrap(void) {
    return 1;
}

void yyerror(const char *s) {
    printf("ERROR ln%d: %s : %s\n", lineNum, s, yytext);
}

int main(int argc, char* argv[]) {
    if(argc < 2){
        printf("ERROR: Missing input file\n");
        return -1;
    }


    const char* sFile = argv[1];
    FILE* fp = fopen(sFile, "r");
    if (fp == NULL) {
        printf("cannot open %s\n", sFile);
        return -1;
    }
    yyin = fp;
    yylex();
    return 0;
}