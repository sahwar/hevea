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

type action =
  | Subst of string
  | CamlCode of (Lexing.lexbuf -> unit)

val pretty_action : action -> unit


type pat = string list * string list

val pretty_pat : pat -> unit


exception Error of string

val display : bool ref
val in_math : bool ref
val alltt : bool ref
val french : bool ref
val optarg : bool ref
val styleloaded : bool ref
val activebrace : bool ref
val html : bool ref
val text : bool ref

val withinLispComment : bool ref
val afterLispCommentNewlines : int ref

val out_file : Out.t
type 'a t

val create : unit -> 'a t
val push : 'a t -> 'a -> unit
val pop : 'a t -> 'a
val top : 'a t -> 'a
val empty : 'a t -> bool
val rev : 'a t -> unit

type 'a r
type closenv
val top_level : unit -> bool
val save_stack : 'a t -> 'a r
val restore_stack : 'a t -> 'a r -> unit

val prerr_args : unit -> unit
val prerr_stack_string : string -> ('a -> string) -> 'a t -> unit
val pretty_lexbuf : Lexing.lexbuf -> unit

val scan_arg : (string -> 'a) -> int -> 'a
val scan_body :
  (action -> 'a) -> action -> string array -> 'a

val stack_lexbuf : Lexing.lexbuf t
val tab_val : int ref

val record_lexbuf : Lexing.lexbuf  -> unit
val previous_lexbuf : unit -> Lexing.lexbuf

val save_lexstate : unit -> unit
val restore_lexstate : unit -> unit
val start_lexstate : unit -> unit
val prelude : bool ref
val flushing : bool ref
val stack_in_math : bool t
val stack_display : bool t
val stack_alltt : bool t

val start_normal: bool ref -> bool ref -> unit
val end_normal : bool ref -> bool ref  -> unit

val save_arg : Lexing.lexbuf -> string
type ok = | No of string | Yes of string
val from_ok : ok -> string
val pretty_ok : ok -> string
val parse_quote_arg_opt : string -> Lexing.lexbuf -> ok
val parse_args_norm : 'a list -> Lexing.lexbuf -> string list
val parse_arg_opt : string -> Lexing.lexbuf -> ok
val parse_args_opt : string list -> Lexing.lexbuf -> ok list
val skip_opt : Lexing.lexbuf -> unit
val check_opt : Lexing.lexbuf -> bool
val save_opt : string -> Lexing.lexbuf -> string
val parse_args :
  string list * 'a list -> Lexing.lexbuf -> ok list * string list
val make_stack : string -> pat -> Lexing.lexbuf -> string array



val scan_this : (Lexing.lexbuf -> 'a ) -> string -> 'a
val scan_this_may_cont :
    (Lexing.lexbuf -> 'a ) -> Lexing.lexbuf ->  string -> 'a

val input_file : int -> (Lexing.lexbuf -> unit) -> string -> unit
