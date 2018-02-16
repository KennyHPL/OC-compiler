%{
// $Id: lexer.l,v 1.9 2014-10-09 18:39:47-07 - - $

#include "lyutils.h"
#include "astree.h"
#include "auxlib.h"
#define YY_USER_ACTION  { lexer::advance(); }


%}

%option 8bit
%option debug
%option nodefault
%option nounput
%option noyywrap
%option verbose
%option warn

LETTER          [a-zA-Z_]
DIGIT           [0-9]
NUMBER          {DIGIT}+
IDENT           {LETTER}({LETTER}|{DIGIT})*
NOT_IDENT       {NUMBER}{IDENT}
CHAR            ('([^\\'\n]|\\[\\'"0nt])')
STRING          (\"([^\\"\n]|\\[\\'"0nt])*\")

%%
"#".*           { lexer::include(); }
[ \t]+          { /* Skip whitespace. */ }
\n              { lexer::newline(); }

"+"             { return yylval_token ('+'); }
"-"             { return yylval_token ('-'); }
"*"             { return yylval_token ('*'); }
"/"             { return yylval_token ('/'); }
"%"             { return yylval_token ('%'); }
"!"             { return yylval_token ('!'); }
"("             { return yylval_token ('('); }
")"             { return yylval_token (')'); }
"{"             { return yylval_token ('{'); }
"}"             { return yylval_token ('}'); }
"["             { return yylval_token ('['); }
"]"             { return yylval_token (']'); }
";"             { return yylval_token (';'); }
"="             { return yylval_token ('='); }
"."             { return yylval_token ('.'); }
","             { return yylval_token (','); }

"=="            { return yylval_token (TOK_EQ); }
"!="            { return yylval_token (TOK_NE); }
"<"             { return yylval_token (TOK_LT); }
"<="            { return yylval_token (TOK_LE); }
">"             { return yylval_token (TOK_GT); }
">="            { return yylval_token (TOK_GE); }
"[]"            { return yylval_token (TOK_ARRAY);  }

"if"            { return yylval_token (TOK_IF);     }
"else"          { return yylval_token (TOK_ELSE);   }
"while"         { return yylval_token (TOK_WHILE);  }
"return"        { return yylval_token (TOK_RETURN); }
"int"           { return yylval_token (TOK_INT);    }
"string"        { return yylval_token (TOK_STRING); }
"struct"        { return yylval_token (TOK_STRUCT); }
"void"          { return yylval_token (TOK_VOID);   }
"new"           { return yylval_token (TOK_NEW);    }
"null"          { return yylval_token (TOK_NULL);   }

{NUMBER}        { return yylval_token (TOK_INTCON);   }
{IDENT}         { return yylval_token (TOK_IDENT);    }
{CHAR}          { return yylval_token (TOK_CHARCON);  }
{STRING}        { return yylval_token (TOK_STRINGCON);}

{NOT_IDENT}     { lexer::badtoken(yytext); }
.               { lexer::badchar(*yytext); }

%%
