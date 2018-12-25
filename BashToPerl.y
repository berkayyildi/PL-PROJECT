%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
typedef struct symbol_table_entry{
	int typ;
	char *ident;
	int val;
	char* st;
    struct symbol_table_entry *next;
}symbol_table_entry;

symbol_table_entry *symbol_table_head;

void addToSymbolTable(int,int,char*,char*,symbol_table_entry**);

void printAllSymbolElementsWithValue(symbol_table_entry *);

symbol_table_entry* findIdent(char*,symbol_table_entry*);

FILE *fout;

void addToSymbolTable(int type,int val, char* st,char *ident,symbol_table_entry **head){
    symbol_table_entry *new_entry;
    symbol_table_entry *tmp;
    new_entry=(symbol_table_entry*)malloc(sizeof(symbol_table_entry));
    new_entry->typ=type;
    new_entry->ident=ident;
    new_entry->val=val;
    new_entry->st=st;
    new_entry->next=NULL;
    if(*head==NULL){
    	*head=new_entry;
    }else{
    	tmp=*head;
    	while(tmp->next!=NULL){
    		tmp=tmp->next;
    	}
    	tmp->next=new_entry;
    }
    
}

void printAllSymbolElementsWithValue(symbol_table_entry *head){
    while(head!=NULL){
	if ( head-> typ == 0 ){
    		//printf("$%s = %d;\n",head->ident, head->val);
	}
	else{
		//printf("$%s = %s;\n",head->ident, head->st);
	}
    	head=head->next;
    }
}

symbol_table_entry* findIdent(char* ident,symbol_table_entry *symbol_entry){
	while(symbol_entry!=NULL && (strcmp(ident,symbol_entry->ident))){
		symbol_entry=symbol_entry->next;
	}
	return symbol_entry;
}

void controlandPrintDoubleQuotedString(char *dstr){
	const char s[2] = ".";
   char *dstrWithoutNewLineAndDot;
   
   dstrWithoutNewLineAndDot = strtok(dstr, s);
   fprintf(fout,"%s",dstrWithoutNewLineAndDot);
	
}

char* deleteSingleQuotes(char* str){
	unsigned int length = strlen(str);
	*(str+(length-1))='\0';
	return str+1;
}

extern FILE *yyin;
extern int linenum;
char writeBuffer[100];
char cache[1000];
%}
%union{int number; char *string;}
%token <string> INTEGER VARIABLE STRING IDENT DSTRING COMMENTLINE
%type <string> variable_body operator compare_operator expr shellcommand
%token SHELLPREDIRECTIVE COMMENTLINE ECHOFUNC RW_WHILE RW_IF RW_ELIF RW_FI RW_ELSE RW_THEN DOLLAR ASSIGNOP PLUSOP MULTOP DIVOP MINUSOP OPENP CLOSEP OPENCURLY CLOSEDCURLY OPENBRACKET CLOSEDBRACKET EQUAL NOTEQUAL GREATER GREATEQ LESS LESSEQ
%%

program :
	statements {printAllSymbolElementsWithValue(symbol_table_head);}

statements:
	statement statements 
	|
	statement {sprintf(cache,"");}
	|
	;

statement:
	assignment  {printf ("%s",cache); sprintf(cache,"");}
	|
	print_statement  {printf ("%s",cache); sprintf(cache,"");}
	|
//	while_loop
	|
	SHELLPREDIRECTIVE
	|
	comment  {printf ("%s",cache); sprintf(cache,"");}
	;
/*
mute_statements:
	mute_statement mute_statements 
	|
	mute_statement
	;

mute_statement:
	assignment 
	|
	print_statement
	|
	while_loop
	;

*/
assignment:
	numeric_assignment
	|
	string_assignment
	;
/*
while_loop:
	RW_WHILE OPENP variable_body compare_operator expr CLOSEP OPENCURLY mute_statements CLOSEDCURLY{
		if ($4 == 1)printf("for (; $%s < %d ;) { \n",$3,$5);
		if ($4 == 2)printf("for (; $%s > %d ;) { \n",$3,$5);
		if ($4 == 3)printf("for (; $%s != %d ;) { \n",$3,$5);
		if ($4 == 4)printf("for (; $%s == %d ;) { \n",$3,$5);

		printf ("%s",cache);
		sprintf(cache,"");
		printf("}\n");
	}
	;
*/
numeric_assignment:
	variable_body ASSIGNOP expr { 
		sprintf(cache + strlen(cache),"$%s = %s;\n",$1,$3);
	}
	|
	variable_body ASSIGNOP shellcommand { 
		sprintf(cache + strlen(cache),"$%s = %s;\n",$1,$3);
	}
	;

shellcommand:
	DOLLAR OPENP OPENP expr CLOSEP CLOSEP{
		//Dont print anything
		$$ = $4;
	}
	;

comment:
	COMMENTLINE{
		sprintf(cache + strlen(cache),"%s\n",$1);
	}
	;

string_assignment:
	variable_body ASSIGNOP STRING {
		symbol_table_entry *entry;
		entry=findIdent($1,symbol_table_head);
		entry->st=deleteSingleQuotes($3);
	}
	;

expr:
	INTEGER {$$=$1;}
	|
	variable_body {$$=$1;}
	|
	expr operator expr {
		char strconcat[1000];
		snprintf(strconcat, sizeof strconcat, "%s%s%s", $1, $2, $3);
		$$=strconcat;	
	}
	|
	expr operator OPENP variable_body operator INTEGER CLOSEP {
		char strconcat[1000];
		snprintf(strconcat, sizeof strconcat, "%s%s(%s%s%s)", $1, $2, $4, $5, $6);
		$$=strconcat;	
	}

	;

print_statement:
	ECHOFUNC STRING 	{ sprintf(cache + strlen(cache),"print %s . \"\\n\" \n",$2);}
	|
	ECHOFUNC DSTRING 	{ sprintf(cache + strlen(cache),"print $%s . \"\\n\"; \n",$2); }
	|
	ECHOFUNC variable_body 	{ sprintf(cache + strlen(cache),"print $%s . \"\\n\"; \n",$2); }
	|
	ECHOFUNC variable_body 	{ sprintf(cache + strlen(cache),"print $%s . \"\\n\"; \n",$2); }
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
	IDENT { $$ = $1; }
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
    symbol_table_head=NULL;
    yyin=fopen(argv[1],"r");
    fout = fopen(argv[2],"w");
    yyparse();
    fclose(yyin);
    fclose(fout);
    return 0;
}
