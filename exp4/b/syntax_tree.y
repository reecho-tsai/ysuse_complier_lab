/*
*bison语法分析，对每条规则 按照孩子兄弟表示法建立语法结点
*/
%{
#include<unistd.h>
#include<stdio.h>   
#include "syntax_tree.h"
%}

%union{
    tnode type_tnode;
	// 这里声明double是为了防止出现指针错误（segmentation fault）
	double d;
}

/*声明记号*/
%token <type_tnode> INT FLOAT
%token <type_tnode> TYPE STRUCT RETURN IF ELSE WHILE ID COMMENT SPACE SEMI COMMA ASSIGNOP PLUS
%token <type_tnode> MINUS STAR DIV AND OR DOT NOT LP RP LB RB LC RC AERROR RELOP EOL

%type  <type_tnode> Program ExtDefList ExtDef ExtDecList Specifire StructSpecifire 
%type  <type_tnode> OptTag Tag VarDec FunDec VarList ParamDec Compst StmtList Stmt DefList Def DecList Dec Exp Args

/*优先级*/
/*C-minus中定义的运算符的优先级，并没有包括所有C语言的*/
%nonassoc LOWER_THAN_ELSE 
%nonassoc ELSE
%left COMMA
%right ASSIGNOP
%left OR
%left AND
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT 
%left LP RP LB RB DOT


/*产生式*/
/*$$表示左表达式 ${num}表示右边的第几个表达式*/
%%
/*High-level Definitions*/
Program:ExtDefList {$$=newAst("Program",1,$1); }
    ;
ExtDefList:ExtDef ExtDefList {$$=newAst("ExtDefList",2,$1,$2); }
	| {$$=newAst("ExtDefList",0,-1); }
	;
ExtDef:Specifire ExtDecList SEMI    {$$=newAst("ExtDef",3,$1,$2,$3);}    
	|Specifire SEMI	{$$=newAst("ExtDef",2,$1,$2); }
	|Specifire FunDec Compst	{
			$$=newAst("ExtDef",3,$1,$2,$3); 
			// 设置函数声明的返回值类型并检查返回类型错误
			newfunc(1,$1);
		}
	;
ExtDecList:VarDec {
		$$=newAst("ExtDecList",1,$1); 
		// 错误类型7:变量出现重复定义
		if(findvar($1)) 
			printf("Error type 7 at Line %d:Redefined Variable '%s'\n",yylineno,$1->content);
        else newvar(1,$1);
	}
	|VarDec COMMA ExtDecList {$$=newAst("ExtDecList",3,$1,$2,$3); }
	;
/*Specifire*/
Specifire:TYPE {$$=newAst("Specifire",1,$1);}
	|StructSpecifire {$$=newAst("Specifire",1,$1); }
	;
StructSpecifire:STRUCT OptTag LC DefList RC {
		// 结构体定义完成，当前在结构体定义外部
		inStruc = 0;
		$$=newAst("StructSpecifire",5,$1,$2,$3,$4,$5); 
		// 错误类型11:结构体的名字与前面定义过的结构体或变量的名字重复
		if(findstruc($2))	
			printf("Error type 11 at Line %d:Duplicated name '%s'\n",yylineno,$2->content);
        else newstruc(1,$2);
	}
	|STRUCT Tag {$$=newAst("StructSpecifire",2,$1,$2); }
	;
OptTag:ID {$$=newAst("OptTag",1,$1); }
	|{$$=newAst("OptTag",0,-1); }
	;
Tag:ID {$$=newAst("Tag",1,$1); }
	;
/*Declarators*/
VarDec:ID {$$=newAst("VarDec",1,$1); $$->tag=1;$$->content=$1->content;}
	|VarDec LB INT RB {$$=newAst("VarDec",4,$1,$2,$3,$4); $$->content=$1->content;$$->tag=4;}
	;
FunDec:ID LP VarList RP {
		$$=newAst("FunDec",4,$1,$2,$3,$4); $$->content=$1->content;
		// 错误类型8:函数出现重复定义（即同样的函数名出现了不止一次定义）
		if(findfunc($1)) 
			printf("Error type 8 at Line %d:Redefined Function '%s'\n",yylineno,$1->content);
		// 设置函数名称以及参数列表
        else newfunc(2,$1,$3);
	}
	|ID LP RP {
		$$=newAst("FunDec",3,$1,$2,$3); $$->content=$1->content;
		// 错误类型8:函数出现重复定义（即同样的函数名出现了不止一次定义）
		if(findfunc($1)) 
			printf("Error type 8 at Line %d:Redefined Function '%s'\n",yylineno,$1->content);
		// 设置函数名称以及参数列表
        else newfunc(2,$1,$3);
	}
	;
VarList:ParamDec COMMA VarList {$$=newAst("VarList",3,$1,$2,$3); }
	|ParamDec {$$=newAst("VarList",1,$1); }
	;
ParamDec:Specifire VarDec {
		$$=newAst("ParamDec",2,$1,$2); 
		// 错误类型7:变量出现重复定义
		if(findvar($2)||findarray($2))  
			printf("Error type 7 at Line %d:Redefined Variable '%s'\n",yylineno,$2->content);
        else if($2->tag==4) 
			newarray(1,$2);
        else 
			newvar(1,$2);
	}
    ;

/*Statement*/
Compst:LC DefList StmtList RC {$$=newAst("Compst",4,$1,$2,$3,$4); }
	;
StmtList:Stmt StmtList{$$=newAst("StmtList",2,$1,$2); }
	| {$$=newAst("StmtList",0,-1); }
	;
Stmt:Exp SEMI { $$=newAst("Stmt",2,$1,$2); }
	|Compst { $$=newAst("Stmt",1,$1); }
	|RETURN Exp SEMI {
		$$=newAst("Stmt",3,$1,$2,$3);
		    getrtype($2);
	}
    |IF LP Exp RP Stmt %prec LOWER_THAN_ELSE {$$=newAst("Stmt",5,$1,$2,$3,$4,$5); }
    |IF LP Exp RP Stmt ELSE Stmt %prec ELSE {$$=newAst("Stmt",7,$1,$2,$3,$4,$5,$6,$7); }
	|WHILE LP Exp RP Stmt {$$=newAst("Stmt",5,$1,$2,$3,$4,$5); }
	;
/*Local Definitions*/
DefList:Def DefList{$$=newAst("DefList",2,$1,$2); }
	| {$$=newAst("DefList",0,-1); }
	;
Def:Specifire DecList SEMI {
		$$=newAst("Def",3,$1,$2,$3); 
	}
	;
DecList:Dec {$$=newAst("DecList",1,$1); }
	|Dec COMMA DecList {$$=newAst("DecList",3,$1,$2,$3); $$->tag=$3->tag;}
	;
Dec:VarDec {
		$$=newAst("Dec",1,$1); 
		// 错误类型7:变量出现重复定义
		if(findvar($1)||findarray($1))  
			printf("Error type 7 at Line %d:Redefined Variable '%s'\n",yylineno,$1->content);
        else if($1->tag==4) 
			newarray(1,$1);
        else 
			newvar(1,$1);
	}
	|VarDec ASSIGNOP Exp {
		$$=newAst("Dec",3,$1,$2,$3); 
		$$->content=$1->content;
		if(findvar($1)||findarray($1))  
			printf("Error type 7 at Line %d:Redefined Variable '%s'\n",yylineno,$1->content);
        else if($1->tag==4) 
			newarray(1,$1);
        else 
			newvar(1,$1);
	}
	;
/*Expressions*/
Exp:Exp ASSIGNOP Exp{
		$$=newAst("Exp",3,$1,$2,$3); 
		// 当有一边变量是未定义时，不进行处理
		if($1->type==NULL || $3->type==NULL){
			// 不进行任何操作
			// 这里不能用return，否则就会推出bison分析过程
		}else{
			// 错误类型2:赋值号两边的表达式类型不匹配
			if(strcmp($1->type,$3->type))
				printf("Error type 2 at Line %d:Type mismatched for assignment.%s,%s\n",yylineno,$1->type,$3->type);
			// 错误类型3:赋值号左边出现一个只有右值的表达式
			if(!checkleft($1))
				printf("Error type 3 at Line %d:The left-hand side of an assignment must be a variable.\n",yylineno);
		}
		
	}
	|Exp AND Exp{$$=newAst("Exp",3,$1,$2,$3); }
	|Exp OR Exp{$$=newAst("Exp",3,$1,$2,$3); }
	|Exp RELOP Exp{$$=newAst("Exp",3,$1,$2,$3); }
	|Exp PLUS Exp{
		$$=newAst("Exp",3,$1,$2,$3);
		// 错误类型6:操作数类型不匹配或操作数类型与操作符不匹配
		if(strcmp($1->type,$3->type)){
			printf("Error type 6 at Line %d:Type mismatched for operands.\n",yylineno);
		}
	}
	|Exp MINUS Exp{
		$$=newAst("Exp",3,$1,$2,$3); 
		// 错误类型6:操作数类型不匹配或操作数类型与操作符不匹配
		if(strcmp($1->type,$3->type))
			printf("Error type 6 at Line %d:Type mismatched for operands.\n",yylineno);
	}
	|Exp STAR Exp{
		$$=newAst("Exp",3,$1,$2,$3); 
		// 错误类型6:操作数类型不匹配或操作数类型与操作符不匹配
		if(strcmp($1->type,$3->type))
			printf("Error type 6 at Line %d:Type mismatched for operands.\n",yylineno);
	}
	|Exp DIV Exp{
		$$=newAst("Exp",3,$1,$2,$3); 
		// 错误类型6:操作数类型不匹配或操作数类型与操作符不匹配
		if(strcmp($1->type,$3->type))
			printf("Error type 6 at Line %d:Type mismatched for operands.\n",yylineno);
	}
	|LP Exp RP{$$=newAst("Exp",3,$1,$2,$3); }
	|MINUS Exp {$$=newAst("Exp",2,$1,$2); }
	|NOT Exp {$$=newAst("Exp",2,$1,$2); }
	|ID LP Args RP {
		$$=newAst("Exp",4,$1,$2,$3,$4); 
		// 错误类型4:对普通变量使用“(...)”或“()”（函数调用）操作符
		if(!findfunc($1) && (findvar($1)||findarray($1)))
			printf("Error type 4 at Line %d:'%s' is not a function.\n",yylineno,$1->content);
		// 错误类型5:函数在调用时未经定义
		else if(!findfunc($1))
			printf("Error type 5 at Line %d:Undefined function %s\n",yylineno,$1->content);
		// 函数实参和形参类型不一致
		else if(checkrtype($1,$3)){
			printf("Error type 13 at Line %d:Function parameter type error.\n",yylineno);
		}else{
			$$->type=typefunc($1);
		}
	}
	|ID LP RP {
		$$=newAst("Exp",3,$1,$2,$3); 
		// 错误类型4:对普通变量使用“(...)”或“()”（函数调用）操作符
		if(!findfunc($1) && (findvar($1)||findarray($1)))
			printf("Error type 4 at Line %d:'%s' is not a function.\n",yylineno,$1->content);
		// 错误类型5:函数在调用时未经定义
		else if(!findfunc($1))
			printf("Error type 5 at Line %d:Undefined function %s\n",yylineno,$1->content);
		else {
			$$->type=typefunc($1);
		}
	}
	|Exp LB Exp RB {$$=newAst("Exp",4,$1,$2,$3,$4); }
	|Exp DOT ID {$$=newAst("Exp",3,$1,$2,$3); }
	|ID {
		$$=newAst("Exp",1,$1); 
		// 错误类型1:变量在使用时未经定义
		if(!findvar($1)&&!findarray($1))
			printf("Error type 1 at Line %d:undefined variable %s\n",yylineno,$1->content);
		else 
			$$->type=typevar($1);
	}
	|INT {$$=newAst("Exp",1,$1); $$->tag=3;$$->value=$1->value;}
	|FLOAT{$$=newAst("Exp",1,$1); $$->tag=3;$$->value=$1->value;}
	;
Args:Exp COMMA Args {$$=newAst("Args",3,$1,$2,$3);}
    |Exp {$$=newAst("Args",1,$1);}
    ;
%%
