LEX=flex
YACC=bison
CC=g++
OBJECT=main

$(OBJECT): lex.yy.o parser.tab.o main.o
		$(CC) main.o lex.yy.o parser.tab.o -o $(OBJECT)

lex.yy.o: lex.yy.c parser.tab.h main.h
		$(CC) -c lex.yy.c

parser.tab.o: parser.tab.c main.h
		$(CC) -c parser.tab.c

parser.tab.c parser.tab.h: parser.y
		$(YACC) -d parser.y

lex.yy.c: scanner.l
		$(LEX) scanner.l

main.o: main.cpp
		$(CC) -c main.cpp

clean:
		rm -f $(OBJECT) *.o lex.yy.c parser.tab.h parser.tab.c