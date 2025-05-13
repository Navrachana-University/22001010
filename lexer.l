%{
#include "parser.tab.h"
#include <stdlib.h>
#include <string.h>
%}
%%
[ \t\n]     ; // Ignore whitespace

"imprimer"     { return PRINT; }
"si"           { return IF; }
"sinon"        { return ELSE; }

"=="           { return EQ; }
"!="           { return NE; }
"<"            { return LT; }
">"            { return GT; }
"<="           { return LE; }
">="           { return GE; }
"="            { return ASSIGN; }
";"            { return SEMI; }
"+"            { return PLUS; }
"-"            { return MINUS; }
"*"            { return TIMES; }
"/"            { return DIVIDE; }
"("            { return LPAREN; }
")"            { return RPAREN; }
"{"            { return LBRACE; }
"}"            { return RBRACE; }

\"[^\"]*\"      { yylval.str = strdup(yytext); return STRING; }

[0-9]+         { yylval.str = strdup(yytext); return NUMBER; }

([a-zA-ZéèêàçùâîôëïüÉÈÊÀÇÙÂÎÔËÏÜ_][a-zA-Z0-9éèêàçùâîôëïüÉÈÊÀÇÙÂÎÔËÏÜ_]*)  {
                yylval.str = strdup(yytext);
                return ID;
              }

.              { printf("Invalid token: %s\n", yytext); }
%%
int yywrap(){return 1;}