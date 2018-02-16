#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <bitset>

using namespace std;
#include "lyutils.h"
#include "astree.h"
#include "symbols.h"


extern vector<symbol_table*> symbol_stack;
extern symbol_table* types;

vector<symbol_table*> symbol_stack = new vector<symbol_table*>;
symbol_table* types = new symbol_table;
symbol_stack.push_back (new symbol_table);

//===========================Symbol Table===========================//

symbol* new_sym(astree* node) {
    symbol* sym = new symbol();
    sym->attributes = node->attributes;
    sym->fields = nullptr;
    sym->filenr = node->lloc.filenr;
    sym->linenr = node->lloc.linenr;
    sym->offset = node->lloc.offset;
    sym->blocknr = node->blocknr;
    sym->parameters = nullptr;
    return sym;
}

void insert_sym(symbol_table* table, astree* node){
	const symbol* sym = new_sym(node);

	if((table != NULL) && (node != NULL)){
		table->insert(pair<node->lexinfo, sym>);
	}
}
//===========================Symbol Stack===========================//

void enter_block(){
	next_block++;
	symbol_stack.push_back(nullptr);
}

void leave_block(){
	symbol_stack.pop_back();
}

void def_ident(astree* node){
	if(symbol_stack.back() == nullptr){
		symbol_stack.back() = new symbol_table;
	}

}