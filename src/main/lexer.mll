{
open Parser
exception SyntaxError of string
}

let int = ['0'-'9'] ['0'-'9']*
let var = ['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z']*
let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

rule read = parse
  | white   { read lexbuf }
  | newline { Lexing.new_line lexbuf; read lexbuf }
  | int     { INT (int_of_string (Lexing.lexeme lexbuf)) }

  | '+'     { PLUS }
  | '-'     { MINUS }
  | '*'     { TIMES }
  | '/'     { DIVIDE }

  | "<="    { LEQ }
  | ">="    { GEQ }
  | '='     { EQUAL }
  | "!="    { NOTEQ }
  | "&&"    { AND }
  | "||"    { OR }
  | '!'     { NOT }

  | '('     { LPAREN }
  | ')'     { RPAREN }
  | ';'     { SEMICOLON }

  | "while"         { WHILE }
  | "if"            { IF }
  | "printint"      { PRINTINT }
  | "let"           { LET }
  | "new"           { NEW }

  | eof     { EOF }
  | _       { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }
