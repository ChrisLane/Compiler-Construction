(* Data types *)
type dtype =
  | Int of  int
  | Bool of bool
  | Var of string
  | Unit

(* Operators *)
type opcode =
  | Plus | Minus | Times | Divide
  | Leq | Geq | Equal | Noteq
  | And | Or | Not

(* Expressions *)
type expression =
  | Empty
  | Seq of              expression * expression                 (* e; e *)
  | While of            expression * expression                 (* while e do e *)
  | If of               expression * expression * expression    (* if e do e else e *)
  | Asg of              expression * expression                 (* e := e *)
  | Deref of            expression                              (* !e *)
  | Operator of         opcode * expression * expression        (* e + e *)
  | Application of      expression * expression                 (* e(e) *)
  | Const of            int                                     (* 7 *)
  | Readint                                                     (* read_int () *)
  | Printint of         expression                              (* print_int (e) *)
  | Identifier of       string                                  (* x *)
  | Let of              string * expression * expression        (* let x = e in e *)
  | New of              string * expression * expression        (* new x = e in e *)

(* Function *)
type fundef = string * string list * expression

(* Program *)
type program = fundef list

(* Convert a list to a Seq expression*)
let rec make_seq = function
  | [] -> Empty
  | [x] -> x
  | x :: xs -> Seq (x, make_seq xs)
