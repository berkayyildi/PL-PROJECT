all: yacc lex
	cc lex.yy.c y.tab.c -o BashToPerl

yacc: BashToPerl.y
	yacc -d BashToPerl.y

lex: BashToPerl.l
	lex BashToPerl.l


