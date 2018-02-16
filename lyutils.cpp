// $Id: lyutils.cpp,v 1.11 2016-10-06 16:42:53-07 - - $

#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "auxlib.h"
#include "lyutils.h"

bool lexer::interactive = true;
location lexer::lloc = {0, 1, 0};
size_t lexer::last_yyleng = 0;
vector<string> lexer::filenames;
FILE* tokFile;
astree* parser::root = nullptr;

char* removeExtension(char* fileName){
    char *retstr;
    char *lastdot;
    if (fileName == NULL)
         return NULL;
    if ((retstr = (char*)malloc(strlen (fileName) + 1)) == NULL)
        return NULL;
    strcpy (retstr, fileName);
    lastdot = strrchr (retstr, '.');
    if (lastdot != NULL)
        *lastdot = '\0';
    return retstr;
}
void dumpTok(int i){
   if(tokFile == NULL){
      char* file = (char*)lexer::filenames[lexer::lloc.filenr].c_str();
      file = removeExtension(file);
      file = strcat(file,".tok");
      tokFile = fopen(file,"w");
   }
   if(i == 1){
      fprintf (tokFile,
      "# %2zd  \"%s\"\n",
      lexer::lloc.filenr,
      lexer::filename(lexer::lloc.filenr)->c_str());
   }
   if(i==2){
      fprintf(tokFile, "%5zu %2zu.%03zu %4u  %-15s (%s)\n",
      yylval->lloc.filenr,
      yylval->lloc.linenr,
      yylval->lloc.offset,
      yylval->symbol,
      parser::get_tname(yylval->symbol),
      yylval->lexinfo->c_str());
    }
}
const string* lexer::filename (int filenr) {
   return &lexer::filenames.at(filenr);
}

int yylval_token (int symbol){
   yylval = new astree (symbol, lexer::lloc, yytext);
   dumpTok(2);
   return symbol;
}

void lexer::newfilename (const string& filename) {
   lexer::lloc.filenr = lexer::filenames.size();
   lexer::filenames.push_back (filename);
}

void lexer::advance() {
   if (not interactive) {
      if (lexer::lloc.offset == 0) {
         printf (";%2zd.%3zd: ",
                 lexer::lloc.filenr, lexer::lloc.linenr);
      }
      printf ("%s", yytext);
   }
   lexer::lloc.offset += last_yyleng;
   last_yyleng = yyleng;
}

void lexer::newline() {
   ++lexer::lloc.linenr;
   lexer::lloc.offset = 0;
}

void lexer::badchar (unsigned char bad) {
   char buffer[16];
   snprintf (buffer, sizeof buffer,
             isgraph (bad) ? "%c" : "\\%03o", bad);
   errllocprintf (lexer::lloc, "invalid source character (%s)\n",
                  buffer);
}


void lexer::badtoken (char* lexeme) {
   errllocprintf (lexer::lloc, "invalid token (%s)\n", lexeme);
}

void lexer::include() {
   size_t linenr;
   static char filename[0x1000];
   assert (sizeof filename > strlen (yytext));
   int scan_rc = sscanf (yytext, "# %zd \"%[^\"]\"", &linenr, filename);
   if (scan_rc != 2) {
      errprintf ("%s: invalid directive, ignored\n", yytext);
   }else {
      if (yy_flex_debug) {
         fprintf (stderr, "--included # %zd \"%s\"\n",
                  linenr, filename);
      }
      lexer::lloc.linenr = linenr - 1;
      lexer::newfilename (filename);
    }
    dumpTok(1);
}
void closeTok(){
  int tokFile_c = fclose(tokFile);
  if (tokFile_c != 0){
      fprintf(stderr, "Unable to close the file.\n");
      exit(1);
  }
}
void yyerror (const char* message) {
   assert (not lexer::filenames.empty());
   errllocprintf (lexer::lloc, "%s\n", message);
}

