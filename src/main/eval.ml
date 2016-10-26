open Ast

(* Hash table for storing values *)
let store1 = Hashtbl.create 100

(* Evaluate operators for integer manipulation (Return Int) *)
let eval_operator_int op e f = match op with
  | Plus    -> e + f
  | Minus   -> e - f
  | Times   -> e * f
  | Divide  -> e / f
  | _       -> failwith "Operator must be of type int."

(* Evaluate operators for comparison (Return Bool) *)
let eval_operator_compare op e f = match op with
  | Leq     -> e <= f
  | Geq     -> e >= f
  | Equal   -> e =  f
  | Noteq   -> e != f
  | _       -> failwith "Operator must be of comparison type."

(* Evaluate operators for booleans (Return Bool) *)
let eval_operator_bool op e f = match op with
  | And     -> e && f
  | Or      -> e || f
  | _       -> failwith "Operator must be of type bool."

(* Choose correct operator evaluation depending on types *)
let eval_operator op e f = match e, f with
  | Int e, Int f -> (match op with
      | Plus | Minus | Times | Divide   -> Int (eval_operator_int op e f)
      | Leq  | Geq   | Equal | Noteq    -> Bool (eval_operator_compare op e f)
      | _                               -> failwith "Operator cannot be applied to integers.")

  | Bool e, Bool f -> (match op with
      | And | Or    -> Bool (eval_operator_bool op e f)
      | _           -> failwith "Operator cannot be applied to booleans.")

  | e, Bool f -> (match op with
      | Not -> Bool (not f)
      | _   -> failwith "Operator must be of type not.")

  | _ -> failwith "Values are of different types. Operator cannot be applied."

(* Find a variable in variable storage and return it's value *)
let rec lookup x env store = match env with
  | []                          -> failwith "Could not find a variable during lookup."
  | (y, Ref z)::ys  when x = y  -> Hashtbl.find store (string_of_int z)
  | (y, z)::ys      when x = y  -> z
  | y::ys                       -> lookup x ys store

(* Find a variable in variable storage and update it's value *)
let rec update x v env store = match env with
  | []                          -> failwith "Could not find a variable to update."
  | (y, Ref z)::ys  when x = y  -> Hashtbl.replace store (string_of_int z) v
  | y::ys                       -> update x v ys store

(* References for variable pointers *)
let addr_gbl = ref 0
let newref() = addr_gbl:=!addr_gbl+1; !addr_gbl

(* Evaluate an expression *)
let rec eval_exp e env store = match e with
  | Empty           -> Unit
  | Const e         -> Int e
  | Identifier e    -> failwith "Identifier must be dereferenced."

  | Deref e -> (match e with
      | Identifier f    -> lookup f env store
      | _               -> failwith "Can only dereference an identifier.")

  | While (e, f) -> (match eval_exp e env store with
      | Bool true   -> ignore (eval_exp f env store); eval_exp (While (e, f)) env store
      | Bool false  -> Unit
      | _           -> failwith "Invalid value for while condition.")

  | If (e, f, g) -> (match eval_exp e env store with
      | Bool true   -> eval_exp f env store
      | Bool false  -> eval_exp g env store
      | _           -> failwith "Invalid value for if condition.")

  | Operator (op, e, f)     -> eval_operator op (eval_exp e env store) (eval_exp f env store)
  | Asg (Identifier x, e)   -> let v = eval_exp e env store in update x v env store; v
  | Seq (e, Empty)          -> eval_exp e env store
  | Seq (e, f)              -> let _ = eval_exp e env store in let v2 = eval_exp f env store in v2

  | Print e -> (match eval_exp e env store with
      | Int e   -> print_endline (string_of_int e); Unit
      | Bool e  -> print_endline (string_of_bool e); Unit
      | Var e   -> print_endline e; Unit
      | _       -> failwith "Printint can only print integers.")

  | Application _   -> failwith "Application evaluation not supported."
  | Readint         -> failwith "Readint evaluation not supported."
  | Let (x, e1, e2) -> let v1 = eval_exp e1 env store in eval_exp e2 ((x, v1)::env) store
  | New (x, e1, e2) ->
    let v1 = eval_exp e1 env store in
    let l = newref() in
    let v2 = Hashtbl.add store (string_of_int l) v1;        eval_exp e2 ((x, Ref l)::env) store in
             Hashtbl.remove store (string_of_int l);        v2
  | _               -> failwith "Cannot evaluate unsupported expression."

(* Evaluate a function *)
let eval_function = function
  | (name, args, body) -> eval_exp body [] store1
