open Lexer
open Printf
open Lexing
exception Error

let parse_with_error lexbuf =
  try Parser.program Lexer.read lexbuf with
  | SyntaxError msg ->  let _ = Printf.eprintf "%s%!" msg in raise Error
  | Parser.Error    ->  
    let pos = Lexing.lexeme_start_p lexbuf in
    let col = pos.pos_cnum - pos.pos_bol in
    let _ = Printf.eprintf "Syntax error at line %d and column %d: %s.\n%!"
        pos.pos_lnum col (Lexing.lexeme lexbuf) in
    raise Error;;

let parse_file filename = open_in filename
                          |> Lexing.from_channel
                          |> parse_with_error
                          |> List.map Ast.function_string
                          |> String.concat " "
                          |> print_string
                          |> print_newline;;
