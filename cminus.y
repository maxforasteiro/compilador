%{

#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static char * savedName; /* for use in assignments */
static int savedLineNo;  /* ditto */
static TreeNode * savedTree; /* stores syntax tree for later return */
static int yylex(void);
int yyerror(char * message);

%}

%token IF ELSE WHILE INT VOID RETURN
%token ID NUM
%token ASSIGN EQ NEQ LT LET GT GET PLUS MINUS TIMES OVER COMMA LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE SEMI
%token ERROR

%% /* Grammar for C- */

program     : list_decl { savedTree = $1; }
            ;

list_decl   : list_decl decl
              {
                YYSTYPE t = $1;
                if(t != NULL){
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else
                  $$ = $1;
              }
            | decl { $$ = $1; }
            ;

decl        : var_decl { $$ = $1; }
            | func_decl { $$ = $1; }
            ;

var_decl    : type id SEMI
              {
                $$ = $1;
                $$->child[0] = $2;
                $2->nodekind = StmtK;
                $2->kind.stmt = VarK;
              }
            | type id LBRACKET num RBRACKET SEMI
              {
                $$ = $1;
                $$->child[0] = $2;
                $2->nodekind = StmtK;
                $2->kind.stmt = VectorK;
                $2->attr.length = $4->attr.val;
              }
            ;

type        : INT
              {
                $$ = newExpNode(TypeK);
                $$->type = Integer;
                $$->attr.name = "Integer";
              }
            | VOID
              {
                $$ = newExpNode(TypeK);
                $$->type = Void;
                $$->attr.name = "Void";
              }
            ;

func_decl   : type id LPAREN params RPAREN comp_decl
              {
                $$ = $1;
                $$->child[0] = $2;
                $2->nodekind = StmtK;
                $2->kind.stmt = FuncK;
                $2->child[0] = $4;
                $2->child[1] = $6;
              }
            ;

params      : params_list { $$ = $1; }
            | VOID {  }
            ;

params_list : params_list COMMA param
              {
                YYSTYPE t = $1;
                if(t != NULL) {
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $3;
                  $$ = $1;
                }
                else
                  $$ = $3;
              }
            | param { $$ = $1; }
            ;

param       : type id
              {
                $$ = $1;
                $$->child[0] = $2;
              }
            | type id LBRACKET RBRACKET
              {
                $$ = $1;
                $$->child[0] = $2;
                $2->kind.exp = VectorIdK;
              }
            ;

comp_decl   : LBRACE local_decl state_list RBRACE
              {
                YYSTYPE t = $2;
                if(t != NULL) {
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $3;
                  $$ = $2;
                }
                else
                  $$ = $3;
              }
            | LBRACE local_decl RBRACE { $$ = $2; }
            | LBRACE state_list RBRACE { $$ = $2; }
            | LBRACE  RBRACE {  }
            ;

local_decl  : local_decl var_decl
              {
                YYSTYPE t = $1;
                if(t != NULL) {
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else
                  $$ = $2;
              }
            | var_decl { $$ = $1; }
            ;

state_list  : state_list statement
              {
                YYSTYPE t = $1;
                if(t != NULL) {
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else
                  $$ = $2;
              }
            | statement { $$ = $1; }
            ;

statement   : expr_decl { $$ = $1; }
            | comp_decl { $$ = $1; }
            | selc_decl { $$ = $1; }
            | iter_decl { $$ = $1; }
            | retr_decl { $$ = $1; }
            | error     { $$ = NULL; }
            ;

expr_decl   : expression SEMI { $$ = $1; }
            | SEMI {  }
            ;

selc_decl   : IF LPAREN expression RPAREN statement
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $3;
                $$->child[1] = $5;
              }
            | IF LPAREN expression RPAREN statement ELSE statement
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $3;
                $$->child[1] = $5;
                $$->child[2] = $7;
              }
            ;

iter_decl   : WHILE LPAREN expression RPAREN statement
              {
                $$ = newStmtNode(WhileK);
                $$->child[0] = $3;
                $$->child[1] = $5;
              }
            ;

retr_decl   : RETURN SEMI
              {
                $$ = newStmtNode(ReturnK);
              }
            | RETURN expression SEMI
              {
                $$ = newStmtNode(ReturnK);
                $$->child[0] = $2;
              }
            ;

expression  : var ASSIGN expression
              {
                $$ = newStmtNode(AssignK);
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | simple_exp { $$ = $1; }
            ;

var         : id { $$ = $1; }
            | id LBRACKET expression RBRACKET
              {
                $$ = $1;
                $$->kind.exp = VectorIdK;
                $$->child[0] = $3;
              }
            ;

simple_exp  : sum_exp relation sum_exp
              {
                $$ = $2;
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | sum_exp { $$ = $1; }
            ;

relation    : EQ
              {
                $$ = newExpNode(OpK);
                $$->attr.op = EQ;
              }
            | NEQ
              {
                $$ = newExpNode(OpK);
                $$->attr.op = NEQ;
              }
            | LT
              {
                $$ = newExpNode(OpK);
                $$->attr.op = LT;
              }
            | LET
              {
                $$ = newExpNode(OpK);
                $$->attr.op = LET;
              }
            | GT
              {
                $$ = newExpNode(OpK);
                $$->attr.op = GT;
              }
            | GET
              {
                $$ = newExpNode(OpK);
                $$->attr.op = GET;
              }
            ;

sum_exp     : sum_exp sum term
              {
                $$ = $2;
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | term { $$ = $1; }
            ;

sum         : PLUS
              {
                $$ = newExpNode(OpK);
                $$->attr.op = PLUS;
              }
            | MINUS
              {
                $$ = newExpNode(OpK);
                $$->attr.op = MINUS;
              }
            ;

term        : term mult fact
              {
                $$ = $2;
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | fact { $$ = $1; }
            ;

mult        : TIMES
              {
                $$ = newExpNode(OpK);
                $$->attr.op = TIMES;
              }
            | OVER
              {
                $$ = newExpNode(OpK);
                $$->attr.op = OVER;
              }
            ;

fact        : LPAREN expression RPAREN { $$ = $2; }
            | var { $$ = $1; }
            | call_func { $$ = $1; }
            | num { $$ = $1; }
            ;

call_func   : id LPAREN RPAREN
              {
                $$ = $1;
                $$->nodekind = StmtK;
                $$->kind.stmt = CallK;
              }
            | id LPAREN list_arg RPAREN
              {
                $$ = $1;
                $$->nodekind = StmtK;
                $$->kind.stmt = CallK;
                $$->child[0] = $3;
              }
            ;

list_arg    : list_arg COMMA expression
              {
                YYSTYPE t = $1;
                if(t != NULL) {
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $3;
                  $$ = $1;
                }
                else
                  $$ = $3;
              }
            | expression { $$ = $1; }
            ;

id          : ID
              {
                $$ = newExpNode(IdK);
                $$->attr.name = copyString(tokenString);
              }
            ;

num         : NUM
              {
                $$ = newExpNode(ConstK);
                $$->attr.val = atoi(tokenString);
              }
            ;

%%

int yyerror(char * message) {
  fprintf(listing,"Syntax error at line %d: %s\n",lineno,message);
  fprintf(listing,"Current token: ");
  printToken(yychar,tokenString);
  Error = TRUE;
  return 0;
}

/* yylex calls getToken to make Yacc/Bison output
 * compatible with ealier versions of the C- scanner
 */
static int yylex(void) {
  return getToken();
}

TreeNode * parse(void) {
  yyparse();
  return savedTree;
}

