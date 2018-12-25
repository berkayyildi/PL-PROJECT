%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

FILE *fout;
extern FILE *yyin;
extern int linenum;
char temp_cache[1000] = "";
char temp0[1000] = "";
char temp1[1000] = "";
char temp2[1000] = "";
char temp3[1000] = "";
char temp4[1000] = "";
char temp5[1000] = "";
char temp6[1000] = "";
char temp7[1000] = "";
char temp8[1000] = "";
%}
%union{int number; char *string;}
%token <string> INTEGER VARIABLE STRING IDENT DSTRING COMMENTLINE SHELLPREDIRECTIVE
%type <string> variable_body operator compare_operator expr if_statement statement statements assignment print_statement comment printables comparison mute_statement mute_statements
%token COMMENTLINE ECHOFUNC RW_WHILE RW_IF RW_ELIF RW_FI RW_ELSE RW_THEN DOLLAR ASSIGNOP PLUSOP MULTOP DIVOP MINUSOP OPENP CLOSEP OPENCURLY CLOSEDCURLY OPENBRACKET CLOSEDBRACKET EQUAL NOTEQUAL GREATER GREATEQ LESS LESSEQ
%%

program :
	statements if_statement { printf("\n"); }
	|
	statements
	;

if_statement:
	RW_IF OPENBRACKET comparison CLOSEDBRACKET RW_THEN mute_statements RW_FI{
		printf("if(%s){\n",$3);
		printf("%s",temp_cache);
		printf("}");
	}
	;

statements:
	statement statements { $$ = temp0; }
	|
	statement
	;

statement:
	assignment  		{ $$ = $1; printf("%s\n",$1);}
	|
	print_statement  	{ $$ = $1; printf("%s\n",$1); }
	|
	SHELLPREDIRECTIVE	{ $$ = "\n"; }
	|
	COMMENTLINE  		{ $$ = $1; printf("%s\n",$1); }
	;

mute_statements:
	mute_statements mute_statement 
	|
	mute_statement
	;

mute_statement:
	assignment		{ sprintf(temp_cache + strlen(temp_cache),"%s\n",$1); }
	|
	print_statement 	{ sprintf(temp_cache + strlen(temp_cache),"%s\n",$1); }
	|
	SHELLPREDIRECTIVE	{ sprintf(temp_cache + strlen(temp_cache),"%s\n",$1); }
	|
	COMMENTLINE  		{ sprintf(temp_cache + strlen(temp_cache),"%s\n",$1); }
	;


assignment:
	variable_body ASSIGNOP STRING {
		strcpy(temp1,"");
		snprintf(temp1, sizeof temp1, "$%s = %s;",$1,$3);
		$$=temp1;
	}
	|
	variable_body ASSIGNOP expr { 
		strcpy(temp2,"");
		snprintf(temp2, sizeof temp2, "$%s = %s;",$1,$3);
		$$=temp2;
	}
	|
	variable_body ASSIGNOP DOLLAR OPENP OPENP expr CLOSEP CLOSEP { //SHELL COMMAND CATCH
		strcpy(temp3,"");
		snprintf(temp3, sizeof temp3, "$%s = %s;",$1,$6);
		$$=temp3;
	}
	;




expr:
	INTEGER {$$=$1;}
	|
	variable_body {$$=$1;}
	|
	expr operator expr {
		strcpy(temp4,"");
		snprintf(temp4, sizeof temp4, "%s%s%s", $1, $2, $3);
		$$=temp4;	
	}
	|
	expr operator OPENP expr CLOSEP {
		strcpy(temp5,"");
		snprintf(temp5, sizeof temp5, "%s%s(%s)", $1, $2, $4);
		$$=temp5;	
	}
	|
	OPENP expr CLOSEP operator expr {
		strcpy(temp5,"");
		snprintf(temp5, sizeof temp5, "(%s)%s%s", $2, $4, $5);
		$$=temp5;	
	}

	;

print_statement:
	ECHOFUNC printables { 
		strcpy(temp6,"");
		snprintf(temp6, sizeof temp6, "print $%s . \"\\n\";",$2);
		$$=temp6;
	}
	;

printables:
	STRING { $$ = $1; }
	|
	DSTRING { $$ = $1; }
	|
	variable_body { $$ = $1; }
	;

comparison:
	variable_body compare_operator expr{
		strcpy(temp8,"");
		snprintf(temp8, sizeof temp8, "%s%s%s",$1, $2, $3);
		$$=temp8;
	}
	;

operator:
	PLUSOP { $$ = "+";}
	|
	MINUSOP { $$ = "-";}
	|
	MULTOP { $$ = "*";}
	|
	DIVOP { $$ = "/";}
	;

compare_operator:
	EQUAL { $$ = "==";}
	|
	NOTEQUAL { $$ = "!=";}
	|
	GREATER { $$ = ">";}
	|
	GREATEQ { $$ = ">=";}
	|
	LESS { $$ = "<";}
	|
	LESSEQ { $$ = "<=";}
	;

variable_body:
	IDENT { $$=$1; }
	|
	DOLLAR IDENT { $$ = $2; }
	;


%%
void yyerror(char *s){
	fprintf(stderr,"Error at line: %d\n",linenum);
}
int yywrap(){
	return 1;
}
int main(int argc, char *argv[])
{
    /* Call the lexer, then quit. */
    yyin=fopen(argv[1],"r");
    fout = fopen(argv[2],"w");
    yyparse();
    fclose(yyin);
    fclose(fout);
    return 0;
}
