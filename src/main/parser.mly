%{ open Ast %}

%token  <int>       INT
%token  <string>    NAME

%token              PLUS MINUS TIMES DIVIDE
%token              LEQ GEQ EQUALTO NOTEQTO
%token              AND OR NOT

%token              TYPE LET WHILE IF ASG ELSE READINT PRINTINT RETURN

%token              LPAREN RPAREN SEMICOLON LBRACE RBRACE PARAMSEP

%token              EOF

%right              ASG
%left               OR
%left               AND
%right              EQUALTO NOTEQTO
%right              PRINTINT
%left               LEQ GEQ
%left               PLUS MINUS
%left               TIMES DIVIDE
%right              RETURN
%right              NOT
%right              LPAREN

%start  <Ast.program>   program
%%

program:
  | f = fundef*; EOF    { f };;

fundef:
  | n = NAME; p = funparams; b = bracedbody    { (n, p, b) };;

funparams:
  | LPAREN; p = separated_list (PARAMSEP, NAME); RPAREN     { p };;

bracedbody:
  | LBRACE; e = body*; s = set* RBRACE    { make_seq (e@s)  };;

body:
  | e = exp SEMICOLON { e };;

exp:
  | e = params                                                              { e }
  | e = INT                                                                 { Const e }
  | e = NAME                                                                { Identifier e }
  | e = exp;    p = paramlist                                               { Application (e, p) }
  | e = exp;    o = operator;   f = exp                                     { Operator (o, e, f) }
  | NOT;        e = exp                                                     { Operator (Not, Empty, e) }
  | e = exp;    ASG;            f = exp                                     { Asg (e, f) }
  | IF;         p = params;     e = bracedbody;     ELSE;   f = bracedbody  { If (p, e, f) }
  | WHILE;      p = params;     e = bracedbody                              { While (p, e) }
  | RETURN;     e = exp                                                     { Deref e }
  | READINT;                                                                { Readint }
  | PRINTINT;   e = exp                                                     { Printint e };;

set:
  | TYPE;   s = NAME; ASG; e = exp; SEMICOLON;  f = body*       { New (s, e, make_seq f) }
  | LET;    s = NAME; ASG; e = exp; f = bracedbody              { Let (s, e, f) };;

params:
  | LPAREN; e = exp; RPAREN; { e }

paramlist:
  | LPAREN; e = separated_list(PARAMSEP, exp); RPAREN;  { make_seq e }

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
