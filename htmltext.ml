(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet Moscova, INRIA Rocquencourt                   *)
(*                                                                     *)
(*  Copyright 2001 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(*  $Id: htmltext.ml,v 1.6 2001-05-29 09:23:32 maranget Exp $          *)
(***********************************************************************)
open Emisc
open Lexeme

type tsize = Int of int | Big | Small

type nat =
  | Style of tag
  | Size of tsize
  | Color of string
  | Face of string
  | Other

type t_style = {nat : nat ; txt : string ; ctxt : string}
type style = t_style list

let rec do_cost seen_font r1 r2 = function
  | [] -> r1,r2
  | {nat=(Size (Int _)|Color _|Face _)}::rem ->
      do_cost true (if seen_font then r1 else 1+r1) (1+r2) rem
  | _::rem -> do_cost seen_font (1+r1) r2 rem

let cost ss = do_cost false 0 0 ss

exception No

let add_size d = match !basefont + d with
| 1|2|3|4|5|6|7 as x -> x
| _ -> raise No

let size_val = function
  | "+1" -> add_size 1
  | "+2" -> add_size 2
  | "+3" -> add_size 3
  | "+4" -> add_size 4
  | "+5" -> add_size 5
  | "+6" -> add_size 6
  | "-1" -> add_size (-1)
  | "-2" -> add_size (-2)
  | "-3" -> add_size (-3)
  | "-4" -> add_size (-4)
  | "-5" -> add_size (-5)
  | "-6" -> add_size (-6)
  | "1" -> 1
  | "2" -> 2
  | "3" -> 3
  | "4" -> 4
  | "5" -> 5
  | "6" -> 6
  | "7" -> 7
  | _   -> raise No


let same_style s1 s2 = match s1.nat, s2.nat with
| Style t1, Style t2 -> t1=t2
| Other, Other -> s1.txt = s2.txt
| Size s1, Size s2 -> s1=s2
| Color c1, Color c2 -> c1=c2
| Face f1, Face f2 -> f1=f2
| _,_ -> false

let is_color = function
  | Color _ -> true
  | _ -> false

and is_size = function
  | Size _ -> true
  | _ -> false

and is_face = function
  | Face _ -> true
  | _ -> false

exception NoProp

let get_prop = function
  | Size _ -> is_size
  | Face _ -> is_face
  | Color _ -> is_color
  | _       -> raise NoProp

let neutral_prop p = p (Color "")

let is_font = function
  | Size (Int _) | Face _ | Color _ -> true
  | _ -> false

let font_props = [is_size ; is_face ; is_color]

exception Same 

let rec rem_prop p = function
  | s::rem ->
      if p s.nat then rem
      else
        let rem = rem_prop p rem in
        s::rem
  | [] -> raise Same

let rec rem_style s = function
  | os::rem ->
      if same_style s os then rem
      else
        let rem = rem_style s rem in
        os::rem
  | [] -> raise Same

let there s env =  List.exists (fun t -> same_style s t) env

type env = t_style list

exception Split of t_style * env

let add s env =
  let new_env =
    try
      let p = get_prop s.nat in
      try
        s::rem_prop p env
      with
      |  Same ->
          s::env
    with
    | NoProp ->
        try
          s::rem_style s env
        with
        | Same ->
            s::env in
  match s.nat with
  | Other ->
      begin match new_env with
      | _::env -> raise (Split (s,env))
      | _ -> assert false
      end
  | _ -> new_env


  

let add_fontattr txt ctxt a env =
  let nat = match a with
  | SIZE s  -> Size (Int (size_val s))
  | COLOR s -> Color s
  | FACE s  -> Face s
  | OTHER   -> raise No in
  add {nat=nat ; txt=txt ; ctxt=ctxt} env

let  add_fontattrs txt ctxt attrs env = match attrs with
| []  -> env
| _   ->
    let rec do_rec = function
      | [] -> env
      | (a,atxt)::rem ->
          add_fontattr
            atxt
            ctxt
            a
            (do_rec rem) in
    try do_rec attrs with
    | No -> add {nat=Other ; txt=txt ; ctxt=ctxt} env
        

let add_style
    {Lexeme.tag=tag ; Lexeme.attrs=attrs ; Lexeme.txt=txt ; Lexeme.ctxt=ctxt}
    env
    =
  match tag with
  | FONT -> add_fontattrs txt ctxt attrs env
  | A    -> assert false
  | BIG ->
      if attrs=[] then
        add {nat=Size Big ; txt=txt ; ctxt=ctxt} env
      else
        add {nat=Other ; txt=txt ; ctxt=ctxt} env
  | SMALL ->
      if attrs=[] then
        add {nat=Size Small ; txt=txt ; ctxt=ctxt} env
      else
        add {nat=Other ; txt=txt ; ctxt=ctxt} env
  | _ ->
      if attrs=[] then
        add {nat=Style tag ; txt=txt ; ctxt=ctxt} env
      else
        add {nat=Other ; txt=txt ; ctxt=ctxt} env
      
let blanksNeutral s = match s.nat with
| Size _ | Style (TT|CODE|SUB|SUP) | Other -> false
| _ -> true
