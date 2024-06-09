#include "main.h"
#include "parser.tab.h"

extern int yyparse(void);
extern FILE* yyin;

int main()
{
    const char* sFile = "file.txt";
    FILE* fp = fopen(sFile, "r");
    if (fp == NULL) {
        printf("cannot open %s\n", sFile);
        return -1;
    }
    
    yyin = fp;
    yyparse();

    fclose(fp);

    return 0;
}