%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

FILE *fout;
extern FILE *yyin;
extern int linenum;

char temp_cache[10000] = "";	//Block Cache icin kullanılıyor!
char *up_temp[1000][1000];	// $$ depolamalarında kullanılmak için
int up_num = 0;
%}
%union{int number; char *string;}
%token <string> INTEGER VARIABLE STRING IDENT DSTRING COMMENTLINE SHELLPREDIRECTIVE
%type <string> variable_body operator compare_operator expr if_statement statement statements assignment print_statement comment printables comparison mute_statement mute_statements elif_statement shell_command
%token COMMENTLINE ECHOFUNC RW_WHILE RW_IF RW_ELIF RW_FI RW_ELSE RW_THEN DOLLAR ASSIGNOP PLUSOP MULTOP DIVOP MINUSOP OPENP CLOSEP OPENCURLY CLOSEDCURLY OPENBRACKET CLOSEDBRACKET EQUAL NOTEQUAL GREATER GREATEQ LESS LESSEQ
%%

program :
	statements if_statement { printf("\n"); }
	|
	statements if_statement statements { printf("\n"); }
	|
	statements
	;

if_statement:
	RW_IF OPENBRACKET comparison CLOSEDBRACKET RW_THEN mute_statements RW_FI{
		printf("if(%s){\n",$3);
		printf("%s",temp_cache);
		printf("}\n");
	}
	;


statements:
	statement statements
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
	assignment		{ sprintf(temp_cache + strlen(temp_cache),"\t%s\n",$1); }
	|
	print_statement 	{ sprintf(temp_cache + strlen(temp_cache),"\t%s\n",$1); }
	|
	SHELLPREDIRECTIVE	{ sprintf(temp_cache + strlen(temp_cache),"\t%s\n",$1); }
	|
	COMMENTLINE  		{ sprintf(temp_cache + strlen(temp_cache),"\t%s\n",$1); }
	|
	RW_ELSE 		{ sprintf(temp_cache + strlen(temp_cache),"}else{\n"); }	//IF ICINDE ELSE VARSA
	|
	elif_statement 		{ sprintf(temp_cache + strlen(temp_cache),"}elsif(%s){\n",$1); }	//IF ICINDE ELSEIF VARSA
	;


assignment:
	variable_body ASSIGNOP STRING {
		
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "%s = %s;",$1,$3);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	variable_body ASSIGNOP expr { 
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "%s = %s;",$1,$3);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	variable_body ASSIGNOP shell_command {
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "%s = %s;",$1, $3);
		$$=up_temp[up_num];
		up_num++;
	}
	;


shell_command:
	DOLLAR OPENP OPENP expr CLOSEP CLOSEP{ //SHELL COMMAND
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[3], "%s",$4);
		$$=up_temp[up_num];
		up_num++;
	}
	;


elif_statement:
	RW_ELIF OPENBRACKET comparison CLOSEDBRACKET RW_THEN {
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "%s",$3);
		$$=up_temp[up_num];
		up_num++;
		
	}
	;

expr:
	INTEGER {$$=$1;}
	|
	variable_body {$$=$1;}
	|
	expr operator expr {
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "%s%s%s", $1, $2, $3);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	OPENP expr operator expr CLOSEP {
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "(%s%s%s)", $2, $3, $4);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	expr operator OPENP expr CLOSEP {
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "%s%s(%s)", $1, $2, $4);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	OPENP expr CLOSEP operator expr {
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "(%s)%s%s", $2, $4, $5);
		$$=up_temp[up_num];
		up_num++;
	}

	;

print_statement:
	ECHOFUNC printables { 
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "print %s . \"\\n\";",$2);
		$$=up_temp[up_num];
		up_num++;
	}
	;

comparison:
	variable_body compare_operator expr{
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "%s%s%s",$1, $2, $3);
		$$=up_temp[up_num];
		up_num++;
	}
	;

variable_body:
	IDENT  { 
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "$%s",$1);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	DOLLAR IDENT  { 
		strcpy(up_temp[up_num],"");
		snprintf(up_temp[up_num], sizeof up_temp[up_num], "$%s",$2);
		$$=up_temp[up_num];
		up_num++;
	}
	;

printables:
	STRING { $$ = $1; }
	|
	DSTRING { $$ = $1; }
	|
	variable_body { $$ = $1; }
	|
	shell_command {$$ = $1;}
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
	EQUAL { $$ = " == ";}
	|
	NOTEQUAL { $$ = " != ";}
	|
	GREATER { $$ = " > ";}
	|
	GREATEQ { $$ = " >= ";}
	|
	LESS { $$ = " < ";}
	|
	LESSEQ { $$ = " <= ";}
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
