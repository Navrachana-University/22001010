%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <ctype.h>

int temp_counter = 0;
int label_counter = 0;
extern int yylex();
extern FILE *yyin;
extern FILE *yyout;
int yyerror(char *s);

// Create a new temporary variable
char* new_temp() {
    char* name = malloc(10);
    sprintf(name, "t%d", temp_counter++);
    return name;
}

// Create a new label
char* new_label() {
    char* label = malloc(10);
    sprintf(label, "L%d", label_counter++);
    return label;
}

// Emit a TAC instruction
void emit(const char* format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(yyout, format, args);
    fprintf(yyout, "\n");
    va_end(args);
}
%}

%union {
    char* str;       // variable names or numbers
}

// Precedence rules to resolve dangling else
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

// Tokens
%token PRINT SEMI ASSIGN PLUS MINUS TIMES DIVIDE LPAREN RPAREN
%token IF ELSE
%token EQ NE LT GT LE GE
%token <str> NUMBER ID  STRING
%token LBRACE RBRACE

// Non-terminals
%type <str> expression term factor condition
%type <str> statement_block statement
%type <str> statement_list assignment print_statement if_statement

%%

program:
    statement_list {emit("%s", $1); free($1);}
;

statement_list:
    statement {
            $$ = $1;
    }
    | statement_list statement {
        int len = strlen($1) + strlen($2) + 2; 
        $$ = malloc(len); 
        snprintf($$, len, "%s\n%s", $1, $2); 
        free($1); 
        free($2);
    }
;

statement:
      assignment SEMI   {$$ = $1;}
    | print_statement SEMI  { $$ = $1; }
    | if_statement  { $$ = $1; }
;

assignment:
    ID ASSIGN expression {
        char* code = malloc(100);
        if ($3[0] == '"') {
            sprintf(code, "%s = %s", $1, $3);
        } else {
            sprintf(code, "%s = %s", $1, $3);
        }
        $$ = code;
    }
;

print_statement:
    PRINT expression {
        char* code = malloc(100); 
        sprintf(code, "print %s", $2); 
        $$ = code; 
        free($2);
    }
;

if_statement:
    IF LPAREN condition RPAREN statement_block %prec LOWER_THAN_ELSE {
        char *label_end = new_label();
        char* code = malloc(1000);

        sprintf(code, "ifFalse %s goto %s\n%s\n%s:", $3, label_end, $5, label_end);
        
        $$ = code;
        
        free($3); free($5); free(label_end);
    }
  | IF LPAREN condition RPAREN statement_block ELSE statement_block {
        char* label_else = new_label();
        char* label_end = new_label();

        char* code = malloc(1000);

        sprintf(code, "ifFalse %s goto %s\n%s\ngoto %s\n%s:\n%s\n%s:",$3, label_else, $5, label_end, label_else, $7, label_end);

        $$ = code;
        free($3); free($5); free($7);
        free(label_else); free(label_end);
    }
;


statement_block:
    statement {
        $$ = strdup($1);  // ensure it's copied
    }
    | LBRACE statement_list RBRACE  {
        $$ = $2;
    }
;

condition:
      expression EQ expression {
          char* temp = malloc(50);
          sprintf(temp, "%s == %s", $1, $3);
          $$ = temp;
      }
    | expression NE expression {
          char* temp = malloc(50);
          sprintf(temp, "%s != %s", $1, $3);
          $$ = temp;
      }
    | expression LT expression {
          char* temp = malloc(50);
          sprintf(temp, "%s < %s", $1, $3);
          $$ = temp;
      }
    | expression LE expression {
          char* temp = malloc(50);
          sprintf(temp, "%s <= %s", $1, $3);
          $$ = temp;
      }
    | expression GT expression {
          char* temp = malloc(50);
          sprintf(temp, "%s > %s", $1, $3);
          $$ = temp;
      }
    | expression GE expression {
          char* temp = malloc(50);
          sprintf(temp, "%s >= %s", $1, $3);
          $$ = temp;
      }
;

expression:
    term { $$ = $1; }
    | expression PLUS term {
        char* temp = new_temp();
        emit("%s = %s + %s", temp, $1, $3);
        $$ = temp;
      }
    | expression MINUS term {
        char* temp = new_temp();
        emit("%s = %s - %s", temp, $1, $3);
        $$ = temp;
      }
;

term:
    factor { $$ = $1; }
    | term TIMES factor {
        char* temp = new_temp();
        emit("%s = %s * %s", temp, $1, $3);
        $$ = temp;
        free($1); free($3);
      }
    | term DIVIDE factor {
        char* temp = new_temp();
        emit("%s = %s / %s", temp, $1, $3);
        $$ = temp;
        free($1); free($3);
      }
;

factor:
    NUMBER { $$ = $1; }
    | ID    { $$ = $1; }
    | STRING { $$ = $1;}
    | LPAREN expression RPAREN { $$ = $2; }
;

%%

int yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
    exit(1);
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE *input_file = fopen(argv[1], "r");
    if (!input_file) {
        perror("Error opening file");
        return 1;
    }

    FILE *output_file = fopen("output.txt", "w");
    if (!output_file) {
        perror("Error opening output file");
        fclose(input_file);
        return 1;
    }
    yyin = input_file;
    yyout = output_file;
    yyparse();
    fclose(input_file);
    fclose(output_file);
    return 0;
}
