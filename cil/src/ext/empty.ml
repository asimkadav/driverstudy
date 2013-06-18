open Cil
open Str
open Pretty
open Ptranal


(*******************************
* Init
********************************)

(*Toplevel function for our Beefy Analysis *)
let dobeefyanalysis (f:file)  : unit = 	
  begin
     Printf.fprintf stderr "Driver analysis invoked..\n";     
    
  end

(* The feature description for the drivers module *)  
let feature : featureDescr = 
  { fd_name = "drivers";              
    fd_enabled = ref false;
    fd_description = "Device Driver Analysis";
    fd_extraopt = [];
    fd_doit = dobeefyanalysis;
    fd_post_check = true      (*What does this do?? *) 
  } 

