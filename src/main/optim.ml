open Ast
open Hashtbl

(* Variable storage *)
let store = create 100

(* Optimise a const operator *)
let optim_operator_const e f = function
  | Plus    -> e + f
  | Minus   -> e - f
  | Times   -> e * f
  | Divide  -> e / f
  | _       -> failwith "Operator must be of type int."

(* Optimise a comparison operator *)
let optim_operator_compare e f = function
  | Leq     -> e <= f
  | Geq     -> e >= f
  | Equal   -> e =  f
  | Noteq   -> e != f
  | _       -> failwith "Operator must be of comparison type."

(* Optimise a boolean operator *)
let optim_operator_bool e f = function
  | And -> e && f
  | Or  -> e || f
  | _   -> failwith "Operator must be of type bool."

(* Optimise an operator *)
let optim_operator op e f = match e, f with
  | Const x, Const y -> (match op with
      | Plus | Minus | Times | Divide   -> Const (optim_operator_const x y op)
      | Leq  | Geq   | Equal | Noteq    -> Bool (optim_operator_compare x y op)
      | _                               -> Operator (op, e, f))
  | Bool x, Bool y -> (match op with
      | And | Or    -> Bool (optim_operator_bool x y op)
      | _           -> Operator (op, e, f))
  | x, Bool y-> (match op with
      | Not -> Bool (not y)
      | _   -> Operator (op, e, f))
  | _ -> Operator (op, e, f)

(* Find a variable in variable storage and return it's value *)
let rec lookup x = function
  | []                          -> Deref (Identifier x)
  | (y, Ref z)::_  when x = y   -> (match find store (string_of_int z) with
      | Unknown -> Deref (Identifier x)
      | e       -> e)
  | (y, z)::_      when x = y   -> z
  | _::ys                       -> lookup x ys

(* Find a variable in variable storage and update it's value *)
let rec update x v = function
  | []                          -> failwith "Could not find a variable to update."
  | (y, Ref z)::ys  when x = y  -> Hashtbl.replace store (string_of_int z) v
  | y::ys                       -> update x v ys

(* References for variable pointers *)
let addr_gbl = ref 0
let newref() = addr_gbl:=!addr_gbl+1; !addr_gbl

(* Optimise an expression *)
let rec optim_exp env = function
  | Empty                   -> Empty
  | Const e                 -> Const e
  | Bool e                  -> Bool e
  | Ref e                   -> Ref e
  | Unknown                 -> Unknown

  | Identifier e            -> lookup e env

  | Deref e                 -> (match optim_exp env e with
      | Ref f -> find store (string_of_int f)
      | f -> f)

  | While (e, f)            -> (match optim_exp env e with
      | Bool false  -> Empty
      | Bool true   -> optim_exp env (Seq (f, While (e, f)))
      | n           -> While (n, optim_exp env f))

  | If (e, f, g)            -> (match optim_exp env e with
      | Bool true     -> optim_exp env f
      | Bool false    -> optim_exp env g
      | n             -> If (n, optim_exp env f, optim_exp env g))

  | Operator (op, e, f)     -> optim_operator op (optim_exp env e) (optim_exp env f)
  | Asg (Identifier e, f)   -> let v = optim_exp env f in (match v with
      | Readint -> update e Unknown env; Asg(Identifier e, v)
      | _       -> update e v env; Asg (Identifier e, v))
  | Seq (e, Empty)          -> optim_exp env e
  | Seq (e, f)              ->
    let v = optim_exp env e in
    let v2 = optim_exp env f in (match v with
        | Empty -> v2
        | _     -> Seq (v, v2))
  | Print e                 -> Print (optim_exp env e)
  | Application (e, f)      -> Application (e, f)
  | Readint                 -> Readint
  | Let (x, e, f)           -> (match optim_exp env e with
      | Const n -> optim_exp ((x, Const n)::env) f
      | Bool n  -> optim_exp ((x, Bool n)::env) f
      | _ -> Let (x, e, f))

  | New (x, e, Seq (f, g))  -> let l = newref() in (match f with
      | Asg (y, h) when Identifier x = y    -> (match optim_exp env h with
          | Const i   ->
            let v2 = add store (string_of_int l) (Const i);
              optim_exp ((x, Ref l)::env) g in
            remove store (string_of_int l);
            New (x, Const i, v2)
          | Bool i    ->
            let v2 = add store (string_of_int l) (Bool i);
              optim_exp ((x, Ref l)::env) g in
            remove store (string_of_int l);
            New (x, Bool i, v2)
          | _         ->
            let v2 = add store (string_of_int l) (optim_exp env e);
              optim_exp ((x, Ref l)::env) (Seq (f, g)) in
            remove store (string_of_int l);
            New (x, optim_exp env e, v2))
      | _   ->
        let v2 = add store (string_of_int l) (optim_exp env e);
          optim_exp ((x, Ref l)::env) (Seq (f, g)) in
        remove store (string_of_int l);
        New (x, optim_exp env e, v2))

  | New (x, e, f)           ->
    let l = newref() in
    let v2 = add store (string_of_int l) (optim_exp env e);
      optim_exp ((x, Ref l)::env) f in
    remove store (string_of_int l);
    New (x, optim_exp env e, v2)


  | e                       -> e

(* Optimise a function *)
let rec optim_program = function
  | [] -> []
  | Fundef ("main", args, body)::ys -> Fundef ("main", args, (optim_exp [] body))::optim_program ys
  | f                               -> f
