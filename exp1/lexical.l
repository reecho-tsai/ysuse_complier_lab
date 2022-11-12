/* Part1: Header and Varibles */
%{
    #include <stdlib.h>
    #include <stdio.h>

    FILE* f;
	int i;
	int comment_flag;
	int comment_begin;
%}

/* Part2: Define of Regex */
INT 0|[1-9][0-9]*
FLOAT {INT}\.[0-9]+
NUMBER {INT}|{FLOAT}

ID [a-z_A-Z][a-z_A-Z0-9]*

STRUCT struct
RETURN return
IF if
ELSE else
WHILE while
TYPE int|float

SEMI  ;
COMMA ,

ASSIGNOP =
PLUS  \+
MINUS \-
STAR  \*
DIV   \/
AND   &&
DOT   \.
NOT   \!

LP    \(
RP    \)
LB    \[
RB    \]
LC    \{
RC    \}

COMMENT ("//".*)|("/*"([*]*(([^*/])+([/])*)*)*"*/")
COMMENT_BEGIN "/*"
SPACE [ \f\n\r\t\v]+
AERROR .

/*第三部分 操作 action 这里面的注释必须顶格一个空格*/
%%
 /*跳过空白和注释*/
{SPACE} {}
{COMMENT} { printf("COMMENT %s\n", yytext);}
{COMMENT_BEGIN} {
	comment_flag = 1;
	comment_begin = yylineno;}
 /*未终结注释错误*/
<<EOF>> {
	if(comment_flag == 1){
		printf("UNTERMINATED_COMMENT at line %d\n",yylineno);
		comment_flag = 0;}
	yyterminate();
}
 /*关键字*/
{TYPE} |
{STRUCT} |
{RETURN} |
{IF} |
{ELSE} |
{WHILE} { printf("KEYWORD %s\n",yytext);}

 /*数字类型表示*/
{INT} {if(comment_flag!=1)  printf("INT %s\n", yytext);}
{FLOAT} {if(comment_flag!=1)  printf("FLOAT %s\n", yytext);}
 /*标点*/
{SEMI} {if(comment_flag!=1)  printf("SEMI :%s\n", yytext);}
{COMMA} {if(comment_flag!=1)  printf("COMMA %s\n", yytext);}
 /*运算符*/
{ASSIGNOP} |
{PLUS} |
{MINUS} |
{STAR} |
{DIV} |
{AND} |
{DOT} |
{NOT} {if(comment_flag!=1)  printf("OPERATOR %s\n",yytext);}
 /*括号*/
{LP} {if(comment_flag!=1)  printf("LP :%s\n", yytext);}
{RP} {if(comment_flag!=1)  printf("RP :%s\n", yytext);}
{LB} {if(comment_flag!=1)  printf("LB :%s\n", yytext);}
{RB} {if(comment_flag!=1)  printf("RB :%s\n", yytext);}
{LC} {if(comment_flag!=1)  printf("LC :%s\n", yytext);}
{RC} {if(comment_flag!=1)  printf("RC :%s\n", yytext);}
 /*标识符*/
{ID} {if(comment_flag!=1)  printf("ID %s\n", yytext);}
 /*错误*/
{AERROR} {if(comment_flag!=1) printf("Error type A at line %d: mysterious charachter '%s'\n",yylineno,yytext);}
%%
int main(int argc,char** argv){
	if(argc<2){

		yylex();
		return 0;
	}
	for(i=1;i<argc;i++){
		f=fopen(argv[i],"r");
		if(!f){
			perror(argv[i]);
			return 1;
		}
		comment_flag = 0;

        yyrestart(f);
        yylex();
        fclose(f);
	}
	return 0;
}

int yywrap()
{
    return 1;
}