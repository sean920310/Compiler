#include "main.h"
#include "parser.tab.h"

extern int yyparse(void);
extern FILE *yyin, *yyout;

int main(int argc, char *argv[])
{
    if (argc < 2)
    {
        printf("ERROR: Missing input file\n");
        return -1;
    }

    const char *iFile = argv[1];
    const char *oFile = "output.c";
    FILE *fp = fopen(iFile, "r");
    if (fp == NULL)
    {
        printf("cannot open %s\n", iFile);
        return -1;
    }

    yyin = fp;
    yyout = fopen(oFile, "w");
    yyparse();

    fclose(fp);

    return 0;
}