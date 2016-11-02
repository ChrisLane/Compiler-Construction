%{ open Ast %}
(* Basic Types *)
%token  <int>       INT
%token  <bool>      BOOL
%token  <string>    NAME
(* Operators *)
%token              PLUS MINUS TIMES DIVIDE
%token              LEQ GEQ EQUALTO NOTEQTO
%token              AND OR NOT
(* Expressions *)
%token              TYPE LET WHILE IF ASG ELSE READINT PRINT RETURN DEREF
(* Formatting *)
%token              LPAREN RPAREN SEMICOLON LBRACE RBRACE PARAMSEP
%token              EOF
(* Specific Strings *)
%token  <string>    MAIN

(* Associativity and Precedence *)
%right              ASG
%left               OR
%left               AND
%right              EQUALTO NOTEQTO
%right              PRINT
%left               LEQ GEQ
%left               PLUS MINUS
%left               TIMES DIVIDE
%right              RETURN
%right              DEREF
%right              NOT
%right              LPAREN

(* Start matching types from here *)
%start  <Ast.program>   program
%%


(* Match overall program *)
program:
  | f = fundef*; m = main; EOF      { f@[m] }

(* Match the main function *)
main:
  | n = MAIN; p = funparams; b = bracedbody     { Fundef (n, p, b) }

(* Match a function *)
fundef:
  | n = NAME; p = funparams; b = bracedbody     { Fundef (n, p, b) }

(* Match the function parameters *)
funparams:
  | LPAREN; p = separated_list (PARAMSEP, NAME); RPAREN     { p }

(* Match any number of bodies between braces*)
bracedbody:
  | LBRACE; e = body*; s = set* RBRACE      { make_seq (e@s) }

(* Match an expression in a body *)
body:
  | e = exp SEMICOLON       { e }

(* Match expressions *)
exp:
  | e = params                                                              { e }
  | e = INT                                                                 { Const e }
  | e = BOOL                                                                { Bool e }
  | e = NAME                                                                { Identifier e }
  | e = exp;    p = paramlist                                               { Application (e, p) }
  | e = exp;    o = operator;   f = exp                                     { Operator (o, e, f) }
  | NOT;        e = exp                                                     { Operator (Not, Empty, e) }
  | e = exp;    ASG;            f = exp                                     { Asg (e, f) }
  | IF;         p = params;     e = bracedbody;     ELSE;   f = bracedbody  { If (p, e, f) }
  | WHILE;      p = params;     e = bracedbody                              { While (p, e) }
  | RETURN;     e = exp                                                     { e }
  | DEREF;      e = exp                                                     { Deref e }
  | READINT                                                                 { Readint }
  | PRINT;      e = exp                                                     { Print e }

(* Match variable setting expressions with bodies *)
set:
  | TYPE;   s = NAME; ASG; e = exp; SEMICOLON;  f = body*; g = set*     { New (s, e, make_seq (f@g)) }
  | LET;    s = NAME; ASG; e = exp; f = bracedbody SEMICOLON            { Let (s, e, f) }

(* Match an expression within parentheses *)
params:
  | LPAREN; e = exp; RPAREN     { e }

(* Match many parameters between parentheses *)
paramlist:
  | LPAREN; e = separated_list(PARAMSEP, exp); RPAREN       { make_seq e }

(* Match all operators *)
%inline operator:
  | PLUS    { Plus }
  | MINUS   { Minus }
  | TIMES   { Times }
  | DIVIDE  { Divide }
  | LEQ     { Leq }
  | GEQ     { Geq }
  | EQUALTO { Equal }
  | NOTEQTO { Noteq }
  | AND     { And }
  | OR      { Or }
