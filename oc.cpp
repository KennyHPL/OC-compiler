/*
kepluu@ucsc.edu
CMPS104a
Assignment 2
*/

#include <string>
#include <vector>
using namespace std;
#include <assert.h>
#include <errno.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wait.h>
#include <unistd.h>

#include "astree.h"
#include "auxlib.h"
#include "lyutils.h"
#include "string_set.h"
#include "symbols.h"

const string CPP ="/usr/bin/cpp -nostdinc";
string command;
constexpr size_t LINESIZE = 1024;

// Chomp the last character from a buffer 
//if it is delim.
void chomp (char* string, char delim) {
   size_t len = strlen (string);
   if (len == 0) return;
   char* nlpos = string + len - 1;
   if (*nlpos == delim) *nlpos = '\0';
}

//Put the file through cpp and returns the pipe
void cpp(string fileName, string flag_D){
    command = CPP + " " + fileName;
    if (!flag_D.empty()){command += "-D" + flag_D;}

    yyin = popen(command.c_str(),"r");
    lexer::newfilename(command);
}
//Runs yylex()
void runYYLEX(){
    yyparse();
}
//Tokenizes the stream from the pipe and 
//inputs it into the string_set
void internTokens(FILE* pipe, char* fileName){
    int linenum = 1;
    char inputname[LINESIZE];
    strcpy(inputname,fileName);
    for(;;){
        char buffer[LINESIZE];
        char* fgets_rc = fgets(buffer, LINESIZE, pipe);
        if(fgets_rc == nullptr) break;
        chomp(buffer, '\n');
        //Ignores directives in the file
        int sscanf_rc = sscanf(buffer,"# %d \"%[^\"]\"",
                &linenum,inputname);
        if(sscanf_rc == 2){
            continue;
        }
        char* savepos = nullptr;
        char* bufptr  = buffer;
        //Interns the tokens into the string_set
        for(int tokenct = 1;;++tokenct){
            char* token = strtok_r(bufptr," \t\n",&savepos);
            bufptr = nullptr;
            if(token == nullptr) break;
            string_set::intern(token);
        }
    ++linenum;
    }
}

void strDump(char* fileName){
    FILE* strOut= fopen(fileName,"w");
    string_set::dump(strOut);
    int strOut_c = fclose(strOut);
    if (strOut_c != 0){
            fprintf(stderr, "Unable to close the file.\n");
            exit(1);
    }
}
void astDump(char* fileName){
    FILE* astOut= fopen(fileName,"w");
    astree::print(astOut,parser::root);
    int astOut_c = fclose(astOut);
    if (astOut_c != 0){
            fprintf(stderr, "Unable to close the file.\n");
            exit(1);
    }
}
void cpp_pclose() {
   int pclose_rc = pclose (yyin);
   eprint_status (command.c_str(), pclose_rc);
   if (pclose_rc != 0) exec::exit_status = EXIT_FAILURE;
}
int main(int argc, char** argv){
    //Set the flags
    int o;
    yy_flex_debug = 0;
    yydebug = 0;
    string flag_D;
    //char* flag_AT;
    exec::execname = (string)basename(argv[argc-1]);
  
   //Checks for what flags have been entered
    while((o = getopt(argc,argv,"lyD:@:")) != -1){
        switch(o){
            case 'l':
                yy_flex_debug = 1;
                break;
            case 'y':
                yydebug = 1;
                break;
            case '@':
                set_debugflags(optarg);
                break;
            case 'D':
                flag_D = optarg;
                break;
            case '?':
                fprintf(stderr, 
                    "Usage: oc [-ly] [@flag] [-Dstring] program.oc\n");
                exit(1);
                break;
        }
    }

    /*Finds the base name of the file and checks if the file entered is 
    a .oc file*/
    char* directory = argv[argc-1];
    char* fileName = basename(directory);
    if(strstr(fileName,".oc") == NULL){
        fprintf(stderr, "%s is not a .oc file\n",fileName );
        exit(1);
    }

    //Opens the program to be compiled and checks if it exists
    FILE* program = fopen(directory, "r");
    if (program == NULL){
        fprintf(stderr, "File not found \"%s\"\n",fileName);
        exit(1);
    }

    //Prepares the pipe and runs the file through cpp
    cpp(directory,flag_D);
    runYYLEX();
    internTokens(yyin,directory);
    cpp_pclose();
    //Removes the extension from the fileName and adds desired 
    //extension
    fileName = removeExtension(fileName);
    fileName = strcat(fileName,".str");
    //Dumps into fileName.str
    strDump(fileName);
    //Dumps AST into .ast file
    fileName = removeExtension(fileName);
    fileName = strcat(fileName,".ast");
    astDump(fileName);

    closeTok();
    int program_c = fclose(program);
    if (program_c != 0){
        printf("Unable to close file \n");
    }
    return 0;
}
