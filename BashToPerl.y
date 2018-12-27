%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

FILE *fout;
extern FILE *yyin;
extern int linenum;

char up_temp[1000][1000];	// $$ depolamalarında kullanılmak için
int up_num = 0;

%}
%union{int number; char *string;}
%token <string> INTEGER VARIABLE STRING IDENT DSTRING COMMENTLINE SHELLPREDIRECTIVE 
%type <string> program statements statement variable_body operator compare_operator expr if_blocks elseif_statement assignment  printables comparison shell_command print_statement
%token ECHOFUNC RW_WHILE RW_IF RW_ELIF RW_FI RW_ELSE RW_THEN DOLLAR ASSIGNOP PLUSOP MULTOP DIVOP MINUSOP OPENP CLOSEP OPENCURLY CLOSEDCURLY OPENBRACKET CLOSEDBRACKET EQUAL NOTEQUAL GREATER GREATEQ LESS LESSEQ SPACE RW_DO RW_DONE
%%

program :
	statements		{  printf("%s\n",$1); fprintf(fout,"%s\n",$1); }	//Write to console and to output file
	;

statements:
	statements if_blocks	{ 
		
		sprintf(up_temp[up_num], "%s%s",$1, $2);
		$$=up_temp[up_num];
		up_num++; 
	}
	|
	statements statement 	{ 
		
		sprintf(up_temp[up_num], "%s%s",$1, $2);
		$$=up_temp[up_num];
		up_num++;
		
	}
	|
	statement		{ $$ = $1; }
	;

statement:
	assignment		{ $$ = $1; }
	|
	print_statement		{ $$ = $1; }
	|
	SHELLPREDIRECTIVE	{ $$ = "\n"; }
	|
	COMMENTLINE  		{ $$ = "\n"; }
	|
	RW_WHILE OPENBRACKET comparison CLOSEDBRACKET RW_DO statements RW_DONE{
		sprintf(up_temp[up_num], "while (%s)\n{\n%s}\n",$3, $6);
		$$=up_temp[up_num];
		up_num++;
		
	}
	;

if_blocks:
	RW_IF OPENBRACKET comparison CLOSEDBRACKET RW_THEN statements RW_FI{

		sprintf(up_temp[up_num], "if (%s)\n{\n%s}\n",$3, $6);
		$$=up_temp[up_num];
		up_num++;
		
	}
	|
	RW_IF OPENBRACKET comparison CLOSEDBRACKET RW_THEN statements elseif_statement RW_FI{
		
		sprintf(up_temp[up_num], "if (%s)\n{\n%s}\n%s",$3, $6, $7);
		$$=up_temp[up_num];
		up_num++;
		
	}
	|
	RW_IF OPENBRACKET comparison CLOSEDBRACKET RW_THEN statements RW_ELSE statements RW_FI{

		sprintf(up_temp[up_num], "if (%s)\n{\n%s}else{\n%s}\n",$3, $6, $8);
		$$=up_temp[up_num];
		up_num++;
		
	}
	|
	RW_IF OPENBRACKET comparison CLOSEDBRACKET RW_THEN statements elseif_statement RW_ELSE statements RW_FI{

		sprintf(up_temp[up_num], "if (%s)\n{\n%s}\n%selse{\n%s}",$3, $6, $7, $9);
		$$=up_temp[up_num];
		up_num++;

	}
	;

elseif_statement:
	RW_ELIF OPENBRACKET comparison CLOSEDBRACKET RW_THEN statements{

		sprintf(up_temp[up_num], "elsif (%s)\n{\n%s}",$3, $6);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	RW_ELIF OPENBRACKET comparison CLOSEDBRACKET RW_THEN statements elseif_statement{

		sprintf(up_temp[up_num], "elsif (%s){\n%s}",$3, $6);
		$$=up_temp[up_num];
		up_num++;

	}

	;

assignment:
	variable_body ASSIGNOP STRING {
		sprintf(up_temp[up_num], "%s = %s;\n",$1,$3);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	variable_body ASSIGNOP expr { 
		sprintf(up_temp[up_num], "%s = %s;\n",$1,$3);
		$$=up_temp[up_num];
		up_num++;

	}
	|
	variable_body ASSIGNOP shell_command {
		sprintf(up_temp[up_num], "%s = %s;\n",$1,$3);
		$$=up_temp[up_num];
		up_num++;
	}
	;


print_statement:
	ECHOFUNC printables{
		sprintf(up_temp[up_num], "print %s . \"\\n\";\n", $2);
		$$=up_temp[up_num];
		up_num++;
	}
	;


shell_command:
	DOLLAR OPENP OPENP expr CLOSEP CLOSEP { //SHELL COMMAND
		
		sprintf(up_temp[up_num], "%s",$4);
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
		
		sprintf(up_temp[up_num], "%s%s%s", $1, $2, $3);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	OPENP expr operator expr CLOSEP {
		
		sprintf(up_temp[up_num], "(%s%s%s)", $2, $3, $4);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	expr operator OPENP expr CLOSEP {
		
		sprintf(up_temp[up_num], "%s%s(%s)", $1, $2, $4);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	OPENP expr CLOSEP operator expr {
		
		sprintf(up_temp[up_num], "(%s)%s%s", $2, $4, $5);
		$$=up_temp[up_num];
		up_num++;
	}

	;

comparison:
	variable_body compare_operator expr{
		
		sprintf(up_temp[up_num], "%s%s%s",$1, $2, $3);
		$$=up_temp[up_num];
		up_num++;
	}
	;

variable_body:
	IDENT  { 
		
		sprintf(up_temp[up_num], "$%s",$1);
		$$=up_temp[up_num];
		up_num++;
	}
	|
	DOLLAR IDENT  { 
		
		sprintf(up_temp[up_num], "$%s",$2);
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
