%{

#define YYPARSER /* distinguishes Yacc output from other code files */

#include "globals.h"
#include "util.h"
#include "scan.h"
#include "parse.h"

#define YYSTYPE TreeNode *
static char *savedName; /* for use in assignments */
static int savedNumber;
static int savedLineNo;  /* ditto */
static TreeNode *savedTree; /* stores syntax tree for later return */
static int yylex(void);
int yyerror(char *message);

%}

%token IF ELSE WHILE INT VOID RETURN
%token ID NUM
%token ASSIGN EQ NEQ LT LET GT GET PLUS MINUS TIMES OVER COMMA LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE SEMI
%token ERROR

%% /* Grammar for C- */

program     : decl_list { savedTree = $1; }
            ;

decl_list   : decl_list decl
              {
                YYSTYPE t = $1;
                if(t != NULL){
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else
                  $$ = $2;
              }
            | decl { $$ = $1; }
            ;

decl        : var_decl  { $$ = $1; }
            | func_decl { $$ = $1; }
            ;

save_name   : ID
              {
                savedName = copyString(tokenString);
                savedLineNo = lineno;
              }
            ;

save_number : NUM
              {
                savedNumber = atoi(tokenString);
                savedLineNo = lineno;
              }
            ;

var_decl    : type save_name SEMI
              {
                $$ = newDeclNode(VarK);
                $$->child[0] = $1;
                $$->lineno = lineno;
                $$->attr.name = savedName;
              }
            | type save_name LBRACKET save_number RBRACKET SEMI
              {
                $$ = newDeclNode(VectorVarK);
                $$->child[0] = $1;
                $$->lineno = lineno;
                $$->attr.vector.name = savedName;
                $$->attr.vector.size = savedNumber;
              }
            ;

type        : INT
              {
                $$ = newTypeNode(TypeNameK);
                $$->attr.type = INT;
              }
            | VOID
              {
                $$ = newExpNode(TypeNameK);
                $$->attr.type = VOID;
              }
            ;

func_decl   : type save_name
              {
                $$ = newDeclNode(FuncK);
                $$->lineno = lineno;
                $$->attr.name = savedName;
              }
              LPAREN params RPAREN comp_stmt
              {
                $$ = $3;
                $$->child[0] = $1;
                $$->child[1] = $5;
                $$->child[2] = $7;
              }
            ;

params      : params_list { $$ = $1; }
            | VOID
            {
              $$ = newTypeNode(TypeNameK);
              $$->attr.type = VOID;
            }
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

param       : type save_name
              {
                $$ = newParamNode(NonVectorParamK);
                $$->child[0] = $1;
                $$->attr.name = savedName;
              }
            | type save_name LBRACKET RBRACKET
              {
                $$ = newParamNode(VectorParamK);
                $$->child[0] = $1;
                $$->attr.name = savedName;
              }
            | /* empty */ { $$ = NULL; }
            ;

comp_stmt   : LBRACE local_decl stmt_list RBRACE
              {
                $$ = newStmtNode(CompK);
                $$->child[0] = $2;
                $$->child[1] = $3;
              }
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
            | /* empty */ { $$ = NULL; }
            ;

stmt_list   : stmt_list stmt
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
            | /* empty */ { $$ = NULL; }
            ;

stmt        : expr_stmt { $$ = $1; }
            | comp_stmt { $$ = $1; }
            | selc_stmt { $$ = $1; }
            | iter_stmt { $$ = $1; }
            | retr_stmt { $$ = $1; }
            ;

expr_stmt   : expression SEMI { $$ = $1; }
            | SEMI { $$ = NULL; }
            ;

selc_stmt   : IF LPAREN expression RPAREN stmt
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $3;
                $$->child[1] = $5;
                $$->child[2] = NULL;
              }
            | IF LPAREN expression RPAREN stmt ELSE stmt
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $3;
                $$->child[1] = $5;
                $$->child[2] = $7;
              }
            ;

iter_stmt   : WHILE LPAREN expression RPAREN stmt
              {
                $$ = newStmtNode(WhileK);
                $$->child[0] = $3;
                $$->child[1] = $5;
              }
            ;

retr_stmt   : RETURN SEMI
              {
                $$ = newStmtNode(ReturnK);
                $$->child[0] = NULL;
              }
            | RETURN expression SEMI
              {
                $$ = newStmtNode(ReturnK);
                $$->child[0] = $2;
              }
            ;

expression  : var ASSIGN expression
              {
                $$ = newExpNode(AssignK);
                $$->child[0] = $1;
                $$->child[1] = $3;
              }
            | simple_exp { $$ = $1; }
            ;

var         : save_name
              {
                $$ = newExpNode(IdK);
                $$->attr.name = savedName;
              }
            | save_name LBRACKET expression RBRACKET
              {
                $$ = newExpNode(VectorIdK);
                $$->attr.name = savedName;
                $$->child[0] = $3;
              }
            ;

simple_exp  : sum_exp relation sum_exp
              {
                $$ = $2;
                $$->type = Boolean;
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
                $$->type = Integer;
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
                $$->type = Integer;
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
            | NUM
              {
                $$ = newExpNode(ConstK);
                $$->attr.val = atoi(tokenString);
              }
            ;

call_func   : save_name LPAREN RPAREN
              {
                $$ = newExpNode(CallK);
                $$->attr.name = savedName;
                $$->child[0] = NULL;
              }
            | save_name LPAREN arg_list RPAREN
              {
                $$ = newExpNode(CallK);
                $$->attr.name = savedName;
                $$->child[0] = $3;
              }
            ;

arg_list    : arg_list COMMA expression
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


%%

int yyerror(char * message) {
  fprintf(listing, "Syntax error at line %d: %s\n", lineno, message);
  fprintf(listing, "Current token: ");
  printToken(yychar, tokenString);
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

