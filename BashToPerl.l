digit	[0-9]
letter	[A-Za-z]
%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"
int linenum=1;
%}
%%
"#!/bin/sh" return SHELLPREDIRECTIVE;
#.*				{yylval.string = strdup(yytext);return COMMENTLINE;}
"echo" 	return ECHOFUNC;
"while" return RW_WHILE;
"if" 	return RW_IF;
"elif" 	return RW_ELIF;
"fi" 	return RW_FI;
"else" 	return RW_ELSE;
"then" 	return RW_THEN;
{letter}({letter}|{digit})*	{yylval.string = strdup(yytext);return IDENT;}
[0-9]+				{yylval.string = strdup(yytext);return INTEGER;}
"$"	return DOLLAR;
=	return ASSIGNOP;
"+"	return PLUSOP;
"*"	return MULTOP;
"/"	return DIVOP;
"-"	return MINUSOP;
"("	return OPENP;
")"	return CLOSEP;
"{"	return OPENCURLY;
"}"	return CLOSEDCURLY;
"["	return OPENBRACKET;
"]"	return CLOSEDBRACKET;
"-eq"	return EQUAL;
"-ne"	return NOTEQUAL;
"-gt"	return GREATER;
"-ge"	return GREATEQ;
"-lt"	return LESS;
"-le"	return LESSEQ;
\".*\"  {yylval.string = strdup(yytext);return DSTRING;}
\'.*\'  {yylval.string = strdup(yytext);return STRING;}
\n	{linenum++;}
[ \t]+
("#".*) 
. 

%%
