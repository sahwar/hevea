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

open Lexing

let header = "$Id: out.ml,v 1.17 2000-06-05 08:07:30 maranget Exp $" 
let verbose = ref 0
;;

type buff = {
  mutable buff : string;
  mutable bp : int;
  mutable len : int
}
;;

type t = Buff of buff | Chan of out_channel | Null
;;


let create_buff () = Buff {buff = String.create 128 ; bp = 0 ; len = 128}
and create_chan chan = Chan chan
and create_null () = Null
and is_null  = function
  | Null -> true
  | _ -> false

and is_empty = function
  | Buff {bp=0} -> true
  | _ -> false
;;

let reset = function
  Buff b -> b.bp <- 0
| _      -> raise (Misc.Fatal "Out.reset")
;;

let realloc out =
  let new_len = 2 * out.len in
  let new_b = String.create new_len in
  String.blit out.buff 0 new_b 0 out.bp ;
  out.buff <- new_b ;
  out.len  <-  new_len
;;

let rec put out s = match out with
  (Buff out) as b ->
    let l = String.length s in
    if out.bp + l < out.len then begin
      String.unsafe_blit s 0 out.buff out.bp l ;
      out.bp <- out.bp + l
    end else begin
      realloc out ;
      put b s
    end
| Chan chan -> output_string chan s
| Null -> ()
;;

let rec blit out lexbuf = match out with
  (Buff out) as b ->
    let l = lexbuf.lex_curr_pos - lexbuf.lex_start_pos in
    if out.bp + l < out.len then begin
      String.blit lexbuf.lex_buffer lexbuf.lex_start_pos
        out.buff out.bp l ;
      out.bp <- out.bp + l
    end else begin
      realloc out ;
      blit b lexbuf
    end
| Chan chan -> output_string chan (lexeme lexbuf)
| Null -> ()
;;

let rec put_char out c = match out with
  Buff out as b ->
    if out.bp + 1 < out.len then begin
      String.unsafe_set out.buff out.bp c ;
      out.bp <- out.bp + 1
    end else begin
      realloc out ;
      put_char b c
    end
| Chan chan -> Pervasives.output_char chan c
| Null -> ()
;;

let flush = function
  Chan chan -> flush chan
| _         -> ()
;;

let iter f = function
  | Buff {buff=buff ; bp=bp} ->
      for i = 0 to bp-1 do
        f (buff.[i])
      done
  | Null -> ()
  | _ -> Misc.fatal "Out.iter"

let to_string out = match out with
  Buff out ->
    let r = String.sub out.buff 0 out.bp in
    out.bp <- 0 ; r
| _ -> raise (Misc.Fatal "Out.to_string")
;;

let to_chan chan out = match out with
  Buff out ->
    output chan out.buff 0 out.bp ;
    out.bp <- 0
| _  -> raise (Misc.Fatal "to_chan")
;;

let debug chan out = match out with
  Buff out ->
   output_char chan '*' ;
   output chan out.buff 0 out.bp ;
   output_char chan '*'
| Chan _   ->
   output_string chan "*CHAN*"
| Null ->
   output_string chan "*NULL*"
;;

let hidden_copy from to_buf i l = match to_buf with
  Chan chan -> output chan from.buff i l
| Buff out   ->
    while out.bp + l >= out.len do
      realloc out
    done ;
    String.unsafe_blit from.buff i out.buff out.bp l ;
    out.bp <- out.bp + l
| Null -> ()
;;

let copy from_buff to_buff = match from_buff with
  Buff from -> hidden_copy from to_buff 0 from.bp
| _         -> raise (Misc.Fatal "Out.copy")

let copy_fun f  from_buff to_buff = match from_buff with
  Buff from ->
    put to_buff (f (String.sub from.buff 0 from.bp))
| _         -> raise (Misc.Fatal "Out.copy_fun")

let copy_no_tag from_buff to_buff =
  if !verbose > 2 then begin
    prerr_string "copy no tag from_buff";
    debug stderr from_buff ;
    prerr_endline ""
  end ;
  match from_buff with
    Buff from -> begin
      try
        let i = String.index from.buff '>' in
        let j = 
	  if from.bp=0 then i+1
	  else String.rindex_from from.buff (from.bp-1) '<' in
        hidden_copy from to_buff (i+1) (j-i-1) ;
        if !verbose > 2 then begin
          prerr_string "copy no tag to_buff";
          debug stderr to_buff ;
          prerr_endline ""            
        end
      with Not_found ->  raise (Misc.Fatal "Out.copy_no_tag, no tag found")
    end
  | _         -> raise (Misc.Fatal "Out.copy_no_tag")
;;

let close = function
| Chan c -> close_out c
| _ -> ()
;;

let is_space = function
  | ' ' | '\n' -> true
  | _ -> false

let unskip = function
| Buff b ->
    while b.bp > 0 && is_space b.buff.[b.bp-1] do
      b.bp <- b.bp - 1
    done
| _      -> ()
