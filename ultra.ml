(***********************************************************************)
(*                                                                     *)
(*                          HEVEA                                      *)
(*                                                                     *)
(*  Luc Maranget, projet Moscova, INRIA Rocquencourt                   *)
(*                                                                     *)
(*  Copyright 2001 Institut National de Recherche en Informatique et   *)
(*  Automatique.  Distributed only by permission.                      *)
(*                                                                     *)
(*  $Id: ultra.ml,v 1.6 2001-05-25 17:23:19 maranget Exp $             *)
(***********************************************************************)

open Tree
open Htmltext
open Util

let verbose = ref 0

let same_prop f s =
  try
    let p = Htmltext.get_prop f.nat in
    List.exists (fun s -> p s.nat) s 
  with
  | NoProp -> false

let rec part_factor some blanks i s keep leave = function
  | [] -> keep,leave
  | ((f,_) as x)::rem when there f s ||
    same_prop f s ||
    (blanks && Htmltext.blanksNeutral f)->
      part_factor some blanks i s (x::keep) leave rem
  | (f,j)::rem ->
      part_factor some blanks i s keep
        (some f j (i-1) leave) rem

let there_factor s fs =  List.exists (fun (f,_) -> same_style s f) fs

let rec start_factor i fs start = function
  | [] -> start
  | s::rem when there_factor s fs ->
      start_factor i fs start rem
  | s::rem ->
      start_factor i fs ((s,i)::start) rem

let extend_factors some blanks i s r fs =
  let keep,leave = part_factor some blanks i s [] r fs in
  start_factor i fs keep s,leave


let rec part_factor_neutral some i keep leave = function
  | [] -> keep,leave
  | ((f,_) as x)::rem when Htmltext.blanksNeutral f ->
      part_factor_neutral some i (x::keep) leave rem
  | (f,j)::rem ->
      part_factor_neutral some i keep (some f j (i-1) leave) rem

let extend_factors_neutral some i r fs = part_factor_neutral some i [] r fs
  

let finish_factors some i r fs = part_factor some false i [] [] r fs

let pfactor chan fs =
  List.iter
    (fun ((i,j),f) ->
      Printf.fprintf chan " %d,%d:%s" i j f.txt)
    fs ;
  output_char chan '\n'

let covers (i1:int) (j1:int) i2 j2 =
  (i1 <= i2 && j2 < j1) ||
  (i1 < i2 &&  j2 <= j1)


let rec all_blanks ts i j =
  if i <= j then
    is_blank ts.(i) && all_blanks ts (i+1) j
  else
    true

let rec get_same ts i j f = function
  | [] -> ((i,j),f)
  | ((ii,jj),g)::rem when
       covers i j ii jj &&
       all_blanks ts i (ii-1) &&
       all_blanks ts (jj+1) j -> ((ii,jj),f)
  | _::rem -> get_same ts i j f rem

let get_sames ts fs =
  let rec do_rec r = function
    | [] -> r
    | (((i,j),f) as x)::rem ->
        do_rec
          (if blanksNeutral f then
            get_same ts i j f fs::r
          else
            x::r)
          rem in
  do_rec [] fs


         
let group_font ts fs =
  let fonts,no_fonts =
    List.partition (fun ((i,j),f) -> is_font f.nat) fs in
  get_sames ts fonts@no_fonts

let factorize low high ts =
  if low >= high then []
  else
  let extend_blanks_left i =
    let rec do_rec i =
      if i <= low then low
      else begin
        if is_blank ts.(i-1) then
          do_rec (i-1)
        else
          i
      end in
    do_rec i in

  let correct_prop f i j env =
    try
      let _ = Htmltext.get_prop f.nat in
      let rec find_same  k = match ts.(k) with
        | Node (s,_) when there f s -> k
        | _ -> find_same (k-1) in
      let j = find_same j in
      if j=i || (blanksNeutral f && all_blanks ts i (j-1)) then
        env
      else
        ((i,j),f)::env
    with
    | NoProp -> ((i,j),f)::env in

  let some f i j env =
      if not (Htmltext.blanksNeutral f) then begin
        if j-i > 0 then
          correct_prop f i j env
        else
          env
      end else begin
        let r = ref 0 in
        for k = i to j do
          if not (is_blank ts.(k)) then incr r
        done ;
        if !r > 1 then
          correct_prop f (extend_blanks_left i) j env
        else
          env
      end in
      
  let rec do_rec i r fs =
    if i <= high then begin
      let fs,r = match ts.(i) with
        | Node (s,ts) ->
            extend_factors some (is_blanks ts) i s r fs
        | t ->
            if is_blank t then
              extend_factors_neutral some i r fs
            else
              finish_factors some i r fs in
      do_rec (i+1) r fs
    end else
      let _,r = finish_factors some i r fs in
      r in
  let r = do_rec low [] [] in
  let r = group_font ts r in
  if r <> [] && !verbose > 1 then begin
    Printf.fprintf stderr "Factors in %d %d\n" low high ;
    for i=low to high do
      Pp.tree stderr ts.(i)
    done ;
    prerr_endline "\n*********" ;
    pfactor stderr r
  end ;
  r

let same ((i1,j1),_) ((i2,j2),_) = i1=i2 && j1=j2

let covers_cost ((((i1:int),(j1:int)),_),_) (((i2,j2),_),_) =
  covers i1 j1 i2 j2

let biggest fs =
  let rec through r = function
    | [] -> r
    | x::rem ->
        if List.exists (fun y -> covers_cost y x) rem then
          through r rem
        else
          through (x::r) rem in
  through [] (through [] fs)

let conflicts ((i1,j1),_) ((i2,j2),_) =
  (i1 < i2 && i2 <= j1 && j1 < j2) ||
  (i2 < i1 && i1 <= j2 && j2 < j1)


let num_conflicts f fs = 
  List.fold_left
    (fun r g ->
      if conflicts f g then 1+r else r)
    0 fs

let put_conflicts fs =
  List.fold_left
    (fun r g -> (g,num_conflicts g fs)::r)
    [] fs


let rec add f = function
  | [] -> let i,f = f in [i,[f]]
  | x::rem as r ->
      if same f x then
        let _,f = f
        and i,r = x in
        (i,(f::r))::rem
      else if conflicts f x then
        r
      else
        x::add f rem

let get_them fs =
  List.fold_left
    (fun r (f,_) ->  add f r)
    [] fs

let pfactorc chan fs =
  List.iter
    (fun (((i,j),f),c) ->
      Printf.fprintf chan " %d,%d:%s(%d)" i j f.txt c)
    fs ;
  output_char chan '\n'

let slen f =
  (if is_font f.nat then 
    5
  else
    0) + String.length f.txt + String.length f.ctxt

let order_factors (((i1,j1),f1),c1) (((i2,j2),f2),c2) =
  if c1 < c2 then true
  else if c1=c2 then
    slen f1 >= slen f2
  else
    false

let select_factors fs =
  let fs1 = put_conflicts fs in
  let fs2 = biggest fs1 in
  let fs3 = Sort.list order_factors fs2 in
  if !verbose > 1 then begin
    prerr_string "fs1:" ; pfactorc stderr fs1 ;
    prerr_string "fs2:" ; pfactorc stderr fs2 ;
    prerr_string "fs3:" ; pfactorc stderr fs3
  end ;
  Sort.list
    (fun ((_,j1),_) ((i2,_),_) -> j1 <= i2)
    (get_them fs3)


let some_font s = List.exists (fun s -> is_font s.nat) s

let rec font_tree = function
  | Node (s,ts) ->
      some_font s || font_trees ts
  | Blanks _ -> true
  | _ -> false

and font_trees ts = List.for_all font_tree ts

let other_props s =
  let rec other r = function
    | [] -> r
    | s::rem when is_font s.nat ->
        other
          (List.fold_left
             (fun r p -> if p s.nat then r else p::r)
             [] r)
          rem
    | _::rem -> other r rem in
  other font_props s

let rec all_props r ts = match r with
| [] -> []
| _  -> match ts with
  | [] -> r
  | Node (s,_)::rem when some_font s ->
      all_props
        (List.filter
           (fun p -> List.exists (fun s -> is_font s.nat && p s.nat) s)
           r)
        rem
  | Node (_,ts)::rem ->
      all_props (all_props r ts) rem
  | Blanks _::rem ->
      all_props
        (List.filter neutral_prop r)
        rem
  | _ -> assert false

let extract_props ps s =
  List.partition
    (fun s ->
      is_font s.nat &&
      List.exists (fun p -> p s.nat) ps)
    s


let  clean t k = match t with
  | Node ([],ts) -> ts@k
  | _ -> t::k

let rec as_long p = function
  | x::rem when p x ->
      let yes,no = as_long p rem in
      x::yes,no
  | l -> [],l

let rec as_long_end p = function
  | [] -> [],[]
  | x::rem ->
      match as_long_end p rem with
      | [],no when p x -> [],x::no
      | yes,no -> x::yes,no
          

      
let bouts p ts =
  let bef,rem = as_long is_blank ts in
  let inside,aft = as_long_end is_blank rem in
  bef,inside,aft

let check_node t k = match t with
  | Node (s, (Node (si,args)::rem as ts)) when
    some_font s && font_trees ts ->
    begin match all_props (other_props s) ts with
    | [] -> t::k
    | ps ->
        let lift,keep = extract_props ps si in
        Node (lift@s, clean (Node (keep,args)) rem)::k
    end
(*
  | Node (s, ts) when top List.for_all blanksNeutral s ->
      let bef,inside,after = bouts is_blank ts in
      bef@Node (s,inside)::after@k
*)
  | _ -> t::k

let rec as_list i j ts k =
  if i > j then k
  else
    (clean ts.(i)) (as_list (i+1) j ts k)

let remove s = function
  | Node (os,ts) -> node (sub os s) ts
  | t -> t


let is_text = function
  | Text _ -> true
  | _ -> false

and is_text_blank = function
  | Text _ | Blanks _ -> true
  | _ -> false

and is_node = function
  | Node (_::_,_) -> true
  | _ -> false
    
let rec cut_begin p ts l i =
  if i >= l then l,[]
  else
    if p ts.(i) then
      let j,l = cut_begin p ts l (i+1) in
      j,ts.(i)::l
    else
      i,[]

let cut_end p ts l =
  let rec do_rec r i =
    if i < 0 then i,r
    else
      if p ts.(i) then
        do_rec (ts.(i)::r) (i-1)
      else
        i,r in
  do_rec [] (l-1)

let is_other s = match s.nat with
| Other -> true
| _ -> false

let rec deeper i j ts k =
  let rec again r i =
    if i > j then r
    else match ts.(i) with    
    | Node ([],args) ->
        let b1 =  List.exists is_node args in
        again (b1 || r) (i+1)
    | Node (s,args) when List.exists is_other s ->
        let r = again r (i+1) in
        if not r then
          ts.(i) <- Node (s,opt true (Array.of_list args) []) ;
        r
    | t -> again r (i+1) in
  if again false i then begin
    let ts = as_list i j ts [] in    
    let rs = opt true  (Array.of_list ts) k in
    rs
  end else
    as_list i j ts k
          
    
and trees i j ts k =
  if i > j then  k
  else
    match factorize i j ts with
    | [] -> deeper i j ts k
    | fs ->
        let rec zyva cur fs k = match fs with
        | [] -> deeper cur j ts k
        | ((ii,jj),gs)::rem ->
            for k=ii to jj do
              ts.(k) <- remove gs ts.(k)
            done ;
            deeper cur (ii-1) ts
              (check_node (node gs (trees ii jj ts []))
                 (zyva (jj+1) rem k)) in
        let fs = select_factors fs in
        if !verbose > 1 then begin
          prerr_endline "selected" ;
          List.iter
            (fun ((i,j),fs) ->
              Printf.fprintf stderr " %d,%d:" i j ;
              List.iter
                (fun f -> output_string stderr (" "^f.txt))
                fs)
            fs ;
          prerr_endline ""
        end ;
        zyva i fs k

and opt_onodes = function
  |  ONode (s,c,args) -> begin match opt false (Array.of_list args) [] with
      | [Node (x,args)] ->
          Node (x,[ONode (s,c,args)])
      | t ->
          ONode (s,c,t)
  end
  | Node (s,args) -> Node (s,List.map opt_onodes args)
  | t -> t

and opt top ts k =
  let l = Array.length ts in  
  for i = 0 to l-1 do
    ts.(i) <- opt_onodes ts.(i)
  done ;
  let p = if top then is_text_blank else is_text in
  let start,pre = cut_begin p ts l 0 in
  if start >= l then pre@k
  else
    let fin,post  = cut_end p ts l in
    pre@trees start fin ts (post@k)

let main ts =
  opt true (Array.of_list (Explode.trees ts)) []

