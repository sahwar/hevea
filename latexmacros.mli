(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet PARA, INRIA Rocquencourt                      *)
(*                                                                     *)
(*  Copyright 1998 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(***********************************************************************)
open Lexstate

exception Failed

type saved
val checkpoint : unit -> saved
val hot_start : saved -> unit
val pretty_table : unit -> unit

val register_init : string -> (unit -> unit) -> unit
val exec_init : string -> unit

val open_group : unit -> unit
val close_group : unit -> unit

val exists : string -> bool
val find : string -> Lexstate.pat * Lexstate.action
val pretty_macro : Lexstate.pat -> Lexstate.action -> unit
val def : string -> Lexstate.pat -> Lexstate.action -> unit
val global_def : string -> Lexstate.pat -> Lexstate.action -> unit

(******************)
(* For inside use *)
(******************)

(* raises Failed if already defined *)
val def_init : string -> (Lexing.lexbuf -> unit) -> unit
(* raises Failed if not defined *)
val find_fail : string -> Lexstate.pat * Lexstate.action

(* 
  replace name new,
     Send back the Some (old definition for name) or None

  - if new is Some (def)
        then def replaces the old definition, or a definition is created
  - if new is None, then undefine the last local binding for name.
*)
val replace : string -> (Lexstate.pat * Lexstate.action) option ->
  (Lexstate.pat * Lexstate.action) option



val invisible : string -> bool
val limit : string -> bool
val int : string -> bool
val big : string -> bool
