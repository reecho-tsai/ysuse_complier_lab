#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h> // 变长参数函数 头文件

/**********************语法分析**************************/
// 行数
extern int yylineno;
// 文本
extern char *yytext;
// 错误处理
void yyerror(char *msg);

// 抽象语法树
typedef struct treeNode
{
    // 行数
    int line;
    // Token类型
    char *name;
    // 1变量 2函数 3常数 4数组 5结构体
    int tag;
    // 使用孩子数组表示法
    struct treeNode *cld[10];
    int ncld;
    // 语义值
    char *content;
    // 数据类型 int 或 float
    char *type;
    // 变量的值
    float value;
} * Ast, *tnode;

// 构造抽象语法树(节点)
Ast newAst(char *name, int num, ...);

// 先序遍历语法树
void Preorder(Ast ast, int level);

// 所有节点数量
int nodeNum;
// 存放所有节点
tnode nodeList[5000];
int nodeIsChild[5000];
// 设置节点打印状态
void setChildTag(tnode node);

// bison是否有词法语法错误
int hasFault;

/**********************语义分析**************************/
// 分析语法树，建立符号表
void analysis(tnode val);

// 变量符号表的结点
typedef struct var_
{
    char *name;
    char *type;
    // 是否为结构体域
    int inStruc;
    // 所属的结构体编号
    int strucNum;
    struct var_ *next;
} var;
var *varhead, *vartail;
char* curType;
// 建立变量符号
void newvar(int num, ...);
// 变量是否已经定义
int findvar(tnode val);
// 变量类型
char *typevar(tnode val);
// 这样赋值号左边仅能出现ID、Exp LB Exp RB 以及 Exp DOT ID
int checkleft(tnode val);

// 函数符号表的结点
typedef struct func_
{
    int tag; //0表示未定义，1表示定义
    char *name;
    char *type;
    // 是否为结构体域
    int inStruc;
    // 所属的结构体编号
    int strucNum;
    char *rtype; //声明返回值类型
    int va_num;  //记录函数形参个数
    char *va_type[10];
    struct func_ *next;
} func;
func *funchead, *functail;
// 记录函数实参
int va_num;
char *va_type[10];
void getdetype(tnode val);            //定义的参数
void getretype(tnode val);            //实际的参数
void getargs(tnode Args);             //获取实参
int checkrtype(tnode ID, tnode Args); //检查形参与实参是否一致
// 建立函数符号
void newfunc(int num, ...);
// 函数是否已经定义
int findfunc(tnode val);
// 函数类型
char *typefunc(tnode val);
// 函数的形参个数
int numfunc(tnode val);
// 函数实际返回值类型
char *rtype[10];
int rnum;
void getrtype(tnode val);

// 数组符号表的结点
typedef struct array_
{
    char *name;
    char *type;
    // 是否为结构体域
    int inStruc;
    // 所属的结构体编号
    int strucNum;
    struct array_ *next;
} array;
array *arrayhead, *arraytail;
// 建立数组符号
void newarray(int num, ...);
// 查找数组是否已经定义
int findarray(tnode val);
// 数组类型
char *typearray(tnode val);

// 结构体符号表的结点
typedef struct struc_
{
    char *name;
    char *type;
    // 是否为结构体域
    int inStruc;
    // 所属的结构体编号
    int strucNum;
    struct struc_ *next;
} struc;
struc *struchead, *structail;
// 建立结构体符号
void newstruc(int num, ...);
// 查找结构体是否已经定义
int findstruc(tnode val);
// 当前是结构体域
int inStruc;
// 判断结构体域，{ 和 }是否抵消
int LCnum;
// 当前是第几个结构体
int strucNum;

/**********************中间代码**************************/
// 中间代码数据结构
typedef struct _OperandStru // 操作数
{
    enum
    {
        VARIABLE, // 变量 x
        TEMPVAR,  // 临时变量 t1
        LABLE,    // 标签 lable1
        CONSTANT, // 常数 #1
        ADDRESS,  // 取地址 &x
        VALUE,    // 读取地址的值 *x
        FUNC,     // 函数
    } kind;
    union {
        int tempvar; // 临时变量
        int lable;   // 标签
        int value;   // 常数的值
        char *name;  // 语义值，变量名称、函数名称
    } operand;
    int value;
} OperandStru, *Operand;
typedef struct _InterCodeStru // 中间代码
{
    // 代码类型
    enum
    {
        _LABLE,    // 定义标号
        _FUNCTION, // 定义函数
        _ASSIGN,   // =
        _ADD,      // +
        _SUB,      // -
        _MUL,      // *
        _DIV,      // /
        _GOTO,     // 无条件跳转
        _IFGOTO,   // 判断跳转
        _RETURN,   // 函数返回
        _ARG,      // 传实参
        _CALL,     // 函数调用
        _PARAM,    // 函数参数声明
        _READ,     // 从控制台读取x
        _WRITE,    // 向控制台打印x
        _NULL      // 空的
    } kind;
    // 操作数
    union {
        struct
        { // 赋值 取地址 函数调用等
            Operand left, right;
        } assign;
        struct
        { // 双目运算 + = * /
            Operand result, op1, op2;
        } binop;
        struct
        { // GOTO 和 IF...GOTO
            Operand lable, op1, op2;
            char *relop;
        } jump;
        // 函数声明、参数声明、标签、传实参、函数返回、读取x、打印x
        Operand var;
    } operands;
    struct _InterCodeStru *prev, *next;
} InterCodeStru, *InterCode;
// 函数参数列表
typedef struct _ArgListStru
{
    int num;
    Operand list[10];
} ArgListStru, *ArgList;

InterCode CodesHead, CodesTail; // 全局变量，线性IR双链表的首尾

// 临时变量t1和标签lable1
int tempvar[100];
Operand temp_Operands[100];
int lables[100];
Operand new_tempvar();
Operand new_lable();
void init_tempvar_lable();
// 当Exp的翻译模式为INT、ID、MINUS Exp时，可以获取已经申明过的操作数
Operand get_Operand(tnode Exp);
// 查看是否已经声明过同一个常数值的操作数
Operand find_Const(int value);

// 初始化双链表
void init_InterCode();
// 创建一个新的操作数
Operand new_Operand();
// 创建一个新的变量
Operand new_Variable(char *name);
// 创建一个新的常量
Operand new_Const(float value);
// 创建一条新的中间代码
InterCode new_Code();
// 创建一条lable声明的中间代码
InterCode new_lable_Code(Operand lable);
// 创建一条跳转语句的中间代码
InterCode new_goto_Code(Operand lable);
// 创建一条赋值的中间代码
InterCode new_assign_Code(Operand left, Operand right);
// 打印一条中间代码
void print_Code(InterCode code);
// 打印一个操作数
void print_Operand(Operand op);
// 打印一段中间代码
void print_Codes(InterCode codes);
// 获取链表的尾部
InterCode get_Tail(InterCode codes);
// 在链表末尾加上另一条链表
InterCode add_Codes(int num, ...);

// 整体程序的翻译模式
InterCode translate_Program(tnode Program);
InterCode translate_ExtDefList(tnode ExtDefList);
InterCode translate_ExtDef(tnode ExtDef);

// 变量、函数声明的翻译模式
InterCode translate_FunDec(tnode FunDec);
InterCode translate_VarList(tnode VarList);
InterCode translate_ParamDec(tnode ParamDec);

// 作用域的翻译模式
InterCode translate_CompSt(tnode ComSt);
// 语句列表的翻译模式
InterCode translate_StmtList(tnode);
// 语句的翻译模式
InterCode translate_Stmt(tnode Stmt);

// 变量声明、初始化的翻译模式
InterCode translate_DefList(tnode DefList);
InterCode translate_Def(tnode Def);
InterCode translate_DecList(tnode DecList);
InterCode translate_Dec(tnode Dec);

// 基本表达式的翻译模式
InterCode translate_Exp(tnode Exp, Operand place);
// 条件表达式的翻译模式
InterCode translate_Cond(tnode Exp, Operand lable_true, Operand lable_false);
// 函数参数的翻译模式
InterCode translate_Args(tnode Args, ArgList arg_list);

/**********************目标代码**************************/
// 整数转字符串
char* Int2String(int num,char *str);
// 20个寄存器所存储的内容
Operand regs[20];
int reg_num;
// 分配寄存器
char* allocate_reg(Operand op);
// 根据中间代码生成mips代码
void generate_MIPS_Codes(InterCode codes);
void generate_MIPS_Code(InterCode code);
