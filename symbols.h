#ifndef __SYMBOLS_H__
#define __SYMBOLS_H__ 

#include <string>
#include <unordered_map>
#include <bitset>
#include <vector>
using namespace std;

#include "auxlib.h"
#include "lyutils.h"
#include "astree.h"

int next_block = 1;	//global block counter
using symbol_entry = symbol_table::value_type;


struct symbol{
	attr_bitset attributes;
	symbol_table* fields;
	size_t filenr, linenr, offset;
	size_t blocknr;
	vector<symbol*>* parameters;
};

#endif