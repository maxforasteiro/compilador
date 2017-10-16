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

program     : stmt_seq
              { savedTree = $1; }
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
            | decl
              { $$ = $1; }
            ;

decl        : var_decl
              { $$ = $1; }
            | func_decl
              { $$ = $1; }
            ;

var_decl    : type ID SEMI
              {
                $$ = $1;
                $$->child[0] = $2;
              }
            | type ID LBRACKET NUM RBRACKET SEMI
              {
                $$ = $1;
                $$->kind.exp = VectorK;
                $$->child[0] = $2;
                $$->attr.length = $4;
              }
            ;

type        : INT
              {
                $$ = newExpNode(IdK);
                $$->type = Integer;
              }
            | VOID
              {
                $$ = newExpNode(IdK);
                $$->type = Void;
              }
            ;

func_decl   : type ID LPAREN params RPAREN comp_decl
              {
                $$ = $1;
                $$->kind.exp = FuncK;
                $$->child[0] = $2;
                $$->child[1] = $4;
                $$->child[2] = $6;
              }
            ;

params      : params_list
              { $$ = $1; }
            | VOID
              {  }
            ;

params_list : params_list COMMA param
              {
                YYSTYPE t = $1;
                if(t != NULL) {
                  while(t->sibling != NULL)
                    t = t->sibling;
                  t->sibling = $2;
                  $$ = $1;
                }
                else
                  $$ = $1;
              }
            | param
              { $$ = $1; }
            ;

param       : type ID
              {
                $$ = $1;
                $$->child[0] = $2;
              }
            | type ID LBRACKET RBRACKET
              {
                $$ = $1;
                $$->kind.exp = VectorK;
                $$->child[0] = $2;
              }
            ;

comp_decl   : LBRACE local_decl state_list RBRACE
            | LBRACE local_decl RBRACE
            | LBRACE state_list RBRACE
            | LBRACE  RBRACE
            ;

local_decl  : local_decl var_decl
            | var_decl
            ;

state_list  : state_list statement
            | statement
            ;

statement   : expr_decl { $$ = $1; }
            | comp_decl { $$ = $1; }
            | selc_decl { $$ = $1; }
            | iter_decl { $$ = $1; }
            | retr_decl { $$ = $1; }
            | error     { $$ = NULL; }
            ;

expr_decl   : expression SEMI
            | SEMI
            ;

selc_decl   : IF LPAREN expression RPAREN statement
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $2;
                $$->child[1] = $4;
              }
            | IF LPAREN expression RPAREN statement ELSE statement
              {
                $$ = newStmtNode(IfK);
                $$->child[0] = $2;
                $$->child[1] = $4;
                $$->child[2] = $6;

              }
            ;

iter_decl   : WHILE LPAREN expression RPAREN statement
              {
                $$ = newStmtNode(WhileK);
                $$->child[0] = $2;
                $$->child[1] = $4;
              }
            ;

retr_decl   : RETURN SEMI
              {
                $$ = NULL;
              }
            | RETURN expression SEMI
              {
                $$ = $1;
              }
            ;

expression  : var ASSIGN expression
            | simple_exp
            ;

var         : ID
            | ID LBRACKET expression RBRACKET
            ;

simple_exp  : sum_exp relation sum_exp
            | sum_exp
            ;

relation    : EQ
            | NEQ
            | LT
            | LET
            | GT
            | GET
            ;

sum_exp     : sum_exp sum term
            | term
            ;

sum         : PLUS
            | MINUS
            ;

term        : term mult fact
            | fact
            ;

mult        : TIMES
            | OVER
            ;

fact        : LPAREN expression RPAREN
            | var
            | call_func
            | NUM
            ;

call_func   : ID LPAREN RPAREN
            | ID LPAREN list_arg RPAREN
            ;

list_arg    : list_arg COMMA expression
            | expression
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

