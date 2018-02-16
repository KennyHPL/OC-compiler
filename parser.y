%{
// $Id: parser.y,v 1.11 2017-10-11 14:27:30-07 - - $
// Dummy parser for scanner project.

#include <cassert>

#include "lyutils.h"
#include "astree.h"

%}

%debug
%defines
%error-verbose
%token-table
%verbose

%initial-action {
   parser::root = new astree (TOK_ROOT, {0,0,0}, "");
}

%token TOK_VOID TOK_CHAR TOK_INT TOK_STRING
%token TOK_IF TOK_ELSE TOK_WHILE TOK_RETURN TOK_STRUCT
%token TOK_NULL TOK_NEW TOK_ARRAY
%token TOK_EQ TOK_NE TOK_LT TOK_LE TOK_GT TOK_GE
%token TOK_IDENT TOK_INTCON TOK_CHARCON TOK_STRINGCON

%token TOK_BLOCK TOK_CALL TOK_IFELSE TOK_INITDECL
%token TOK_POS TOK_NEG TOK_NEWARRAY TOK_TYPEID TOK_FIELD
%token TOK_ROOT

%token TOK_RETURNVOID TOK_PARAMLIST TOK_PROTOTYPE TOK_DECLID
%token TOK_NEWSTRING TOK_VARDECL TOK_INDEX TOK_FUNCTION 


%right TOK_IF TOK_ELSE TOK_IFELSE
%right '=' 
%left TOK_EQ TOK_NE TOK_LT TOK_LE TOK_GT TOK_GE
%left '+' '-'
%left '*' '/' '%'
%right TOK_POS  TOK_NEG  '!' 
%left '(' ')'
%left '[' ']' TOK_ARRAY '.' TOK_FUNCTION

%nonassoc    TOK_NEW
%start start

%%
start       :program    {parser::root = $1;}
            ;
program     : program structdef { $$ = $1->adopt($2); }
            | program function  { $$ = $1->adopt($2); }
            | program statement { $$ = $1->adopt($2); }
            | program error '}' { $$ = $1; }
            | program error ';' { $$ = $1; }
            |                   { $$ = parser::root; }
            ;
structdef    :structhd '}'
                {$$ = $1;}
structhd    :structhd fielddecl ';'
                {destroy($3);
                 $$ = $1->adopt($2);}
            |TOK_STRUCT TOK_IDENT '{'
                {destroy($3);
                  $2->symbol = TOK_TYPEID;
                 $$ = $1->adopt($2);}
            ;
fielddecl   :basetype TOK_ARRAY TOK_IDENT
                {$3->symbol = TOK_FIELD;
                 $$ = $2->adopt($1,$3);}
            |basetype TOK_IDENT
                { $2->symbol = TOK_FIELD;
                  $$ = $1->adopt($2);}
            ;
basetype    :TOK_VOID   {$$ = $1;}
            |TOK_INT    {$$ = $1;}
            |TOK_STRING {$$ = $1;}
            |TOK_IDENT  {$1->symbol = TOK_TYPEID; $$ = $1;}
            ;
function    :identdecl '(' ')' ';'
                {$2->symbol = TOK_PARAMLIST;
                 destroy($3,$4);
                 $$ = (new astree(TOK_PROTOTYPE,
                       $1->lloc,""))->adopt($1,$2);}
            |identdecl '(' ')' block
                {$2->symbol = TOK_PARAMLIST;
                 destroy($3);
                 $$ = (new astree(TOK_FUNCTION,
                       $1->lloc,""))->adopt($1,$2,$4);}
            |identdecl param ')' ';'
                {destroy($3,$4);
                 $$ = (new astree(TOK_PROTOTYPE,
                       $1->lloc,""))->adopt($1,$2);}
            |identdecl param ')' block
                {destroy($3);
                 $$ = (new astree(TOK_FUNCTION,
                       $1->lloc,""))->adopt($1,$2,$4);}
            ;
param       : param ',' identdecl
                {destroy($2);
                 $$ = $1->adopt($3);}
            |'(' identdecl
                {$$ = $1->adopt_sym($2,TOK_PARAMLIST);}
            ;
block       :blockfield '}'
                {destroy($2);
                 $$ = $1; }
blockfield  :blockfield statement
                {$$ = $1->adopt($2);}
            |'{'
                {$1->symbol = TOK_BLOCK;
                 $$ = $1; }
            ;
identdecl   :basetype TOK_ARRAY TOK_IDENT
                {$3->symbol = TOK_DECLID;
                 $$ = $2->adopt($1,$3);}
            |basetype TOK_IDENT
                {$2->symbol = TOK_DECLID;
                  $$ = $1->adopt($2);}
            ;
statement   :block         { $$ = $1; }
            |vardecl       { $$ = $1; }
            |while         { $$ = $1; }
            |ifelse        { $$ = $1; }
            |return        { $$ = $1; }
            |expr ';'      { destroy($2); $$ = $1; }
            |';'           { $$ = $1; }
            ;
vardecl     :identdecl '=' expr ';'  
                { destroy($4);
                  $2->symbol = TOK_VARDECL;
                  $$ = $2->adopt($1,$3); }
            ;
while       :TOK_WHILE '(' expr ')' statement
                { destroy($2,$4);
                  $$ = $1->adopt($3, $5); }
            ;
ifelse      :TOK_IF '(' expr ')' statement TOK_ELSE statement
                {destroy($2, $4); destroy($6);
                 $1->symbol = TOK_IFELSE;
                 $$ = $1->adopt($3, $5, $7);}
            |TOK_IF '(' expr ')' statement %prec TOK_IF
                {destroy($2, $4);
                 $$ = $1->adopt($3, $5);}
            ;
return      :TOK_RETURN ';'
                { $1->symbol = TOK_RETURNVOID;
                  $$ = $1; }
            |TOK_RETURN expr ';'
                { destroy($3);
                  $$ = $1->adopt($2); }
expr        :binop         { $$ = $1; }
            |unop          { $$ = $1; }
            |allocator     { $$ = $1; }
            |call          { $$ = $1; }
            |'(' expr ')'  { destroy($1, $3); $$ = $2; }
            |variable      { $$ = $1; }
            |constant      { $$ = $1; }
            ;
binop       : expr '+' expr           { $$ = $2->adopt($1, $3); }
            | expr '-' expr           { $$ = $2->adopt($1, $3); }
            | expr '*' expr           { $$ = $2->adopt($1, $3); }
            | expr '/' expr           { $$ = $2->adopt($1, $3); }
            | expr '%' expr           { $$ = $2->adopt($1, $3); }
            | expr '=' expr           { $$ = $2->adopt($1, $3); }
            | expr TOK_EQ expr        { $$ = $2->adopt($1, $3); }
            | expr TOK_NE expr        { $$ = $2->adopt($1, $3); }
            | expr TOK_LT expr        { $$ = $2->adopt($1, $3); }
            | expr TOK_LE expr        { $$ = $2->adopt($1, $3); }
            | expr TOK_GT expr        { $$ = $2->adopt($1, $3); }
            | expr TOK_GE expr        { $$ = $2->adopt($1, $3); }
            ;
unop        : '+' expr                { $$ = $1->adopt_sym($2,TOK_POS);}
            | '-' expr                { $$ = $1->adopt_sym($2,TOK_NEG);}
            | '!' expr                { $$ = $1->adopt($2); }
            ;
allocator   :TOK_NEW TOK_IDENT '(' ')'
                { destroy($3,$4);
                  $2->symbol = TOK_TYPEID;
                  $$ = $1->adopt($2); }
            |TOK_NEW basetype '[' expr ']'
                { destroy($3, $5);
                  $1->symbol = TOK_NEWARRAY;
                  $$ = $1->adopt($2, $4); }      
            |TOK_NEW TOK_STRING '(' expr ')'
                { destroy($2,$3); destroy($5);
                  $$ = $1->adopt_sym($4, TOK_NEWSTRING); }
            ;
call        :TOK_IDENT '(' ')'       
                { destroy($3);
                  $$ = $2->adopt_sym($1,TOK_CALL); }
            |args ')'                
                { destroy($2); $$ = $1; }
            ;
args        :TOK_IDENT '(' expr      
                { $2->symbol = TOK_CALL;
                  $$ = $2->adopt($1, $3); }
            |args ',' expr           
                { destroy($2); $$ = $1->adopt($3); }
            ;
variable    :TOK_IDENT
                { $$ = $1; }
            |expr '[' expr ']'       
                { destroy($4);
                  $2->symbol = TOK_INDEX;
                  $$ = $2->adopt($1, $3); }
            |expr '.' TOK_IDENT      
                { $3->symbol = TOK_FIELD; 
                    $$ = $2->adopt($1, $3);}
            ; 
constant    : TOK_INTCON              { $$ = $1; }
            | TOK_CHARCON             { $$ = $1; }
            | TOK_STRINGCON           { $$ = $1; }
            | TOK_NULL                { $$ = $1; } 
            ;
%%



const char *parser::get_tname (int symbol) {
   return yytname [YYTRANSLATE (symbol)];
}


bool is_defined_token (int symbol) {
   return YYTRANSLATE (symbol) > YYUNDEFTOK;
}

/*
static void* yycalloc (size_t size) {
   void* result = calloc (1, size);
   assert (result != nullptr);
   return result;
}
*/
