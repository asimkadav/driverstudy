(* Analysis to determine security holes in device drivers including: 
 * Priority inversion
 * DMA
 * Buffer overflow
 * Format string
 * Wear out of system (read/write/mem alloc)
 * Livelocks (waiting in a loop, timer/sleep functions)
 * Memory corruption (array, pointer) 
 *
 * transfer_buffer/schedule are tainted variables
 * 
 * The focus is primarily on drivers of devices that can be connect
 * to a standalone PC or mobile device including ports
 * USB, firewire, serial, parallel, video, dvi etc.  
 *
 * Taint is propogated via return values and procedure arguments (one level of depth)
 *
 *
 * 
*)
open Cil
open Str
open Pretty
open Ptranal
open Callgraph
open Device 
  
module IH = Inthash

let zero64 = (Int64.of_int 0);;
let zero64Uexp = Const(CInt64(zero64,IUInt,None));;

let gen_line_nos: int = 1;;
let gen_call_info: int = 1;;


(* Auxilary helper functions  *)
 (* Printing the name of an lval *)
 let lval_tostring (lv: lval) : string = (Pretty.sprint 100 (d_lval() lv))

(* Converts a typ to a string *)
 let typ_to_string (t: typ) : string =
   begin
     (Pretty.sprint 100 (d_type() t));
   end

(* Converts an instr to a string *)
 let instr_to_string (i: instr) : string =
   begin
     (Pretty.sprint 100 (d_instr() i));
   end

(* Converts an lval to a string *)
 let lval_to_string (lv: lval) : string =
   begin
     (Pretty.sprint 100 (d_lval() lv))
   end

(* Create an expression from an Lval *)
 let expify_lval (l: lval) : exp = Lval(l)

(* Create an expression from a fundec using the variable name *)
 let expify_fundec (g: fundec) : exp = Lval(Var(g.svar),NoOffset)



(* Converts an exp to a string *)
 let exp_to_string (e: exp) : string =
   begin
     (Pretty.sprint 100 (d_exp() e))
   end

(* Converts an offset to a string. *)
let offset_to_string (o: offset) : string =
 begin
        match o with
        | Index(exp,_) -> (exp_to_string exp);
        | NoOffset -> "NoOffset";
        | Field(_,_) -> "Field Offset";
 end


   
(* Converts a statement to a string. *)
 let stmt_to_string (stmt: stmt) : string =
   Pretty.sprint 100 (d_stmt () stmt);;

(* Converts a stmt list to a string.  *)
 let stmt_list_to_string (stmt_list : stmt list) : string =
   let combiner (string : string) (stmt : stmt) =
     match string with
       | "" -> stmt_to_string stmt
       | _ -> string ^ "\n" ^ (stmt_to_string stmt)
   in
     List.fold_left combiner "" stmt_list;;

 (* Converts an exp list to a string.  *)
  let exp_list_to_string (exp_list : exp list) : string =
    let combiner (string : string) (exp : exp) =
      match string with
        | "" -> exp_to_string exp
        | _ -> string ^ "\n" ^ (exp_to_string exp)
      in
        List.fold_left combiner "" exp_list;;

 

(* list_append: Append an element to a list *)
  let list_append (lst : 'a list) (elt: 'a) : 'a list =
  begin
    (List.append lst [elt]);
  end

(* list_rev_append: Append an element to start of a list *)
  let list_rev_append (fst : 'a list) (elt: 'a) : 'a list =
   begin
     (List.rev_append fst [elt]);
   end
                        

let fn_start_end : (string, int) Hashtbl.t = (Hashtbl.create 200);;
(* ioctl function name and parent name *)
let ioctl_fns : (string,string) Hashtbl.t = (Hashtbl.create 15);;

(* init function names and parent name *)
let init_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Error recovery functions *)
let err_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Proc related functions *)
let proc_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* module parameters *)
let modpm_fns : (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* List of cleanup functions *)
let cleanup_fns:(string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Power management functions *)
let pm_fns:(string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Talks to device functions *)
let ttd_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Talks to kernel functions *)
let ttk_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Allocates memory in some form *)
let allocator_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* Configuration functions *)
let config_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* sys/devctl function name and parent name *)
let devctl_fns : (string,string) Hashtbl.t = (Hashtbl.create 15);;

(* Provides core device functionality *)
let core_fns: (string, string) Hashtbl.t = (Hashtbl.create 15);;

(* caller callee pairs *)
let cloc : (string, int) Hashtbl.t = (Hashtbl.create 200);;

(* Seen cnids *)
let seencnids : (int, int) Hashtbl.t = (Hashtbl.create 50);;

(* Seen cnids  -- global *)
let gseencnids : (int, int) Hashtbl.t = (Hashtbl.create 50);;

(* Convert varinfo to lval *)
let lvalify_varinfo (v: varinfo) : lval = (Var(v),NoOffset)   

(*********Auxilary helper functions end ***********)
(* The initial visitor for preprocessing. Fills the dirrty and contaminated hash
 * table in this pre-scan step. *)
class initialVisitor = object (self) 
    inherit nopCilVisitor

 val mutable curr_func : fundec = emptyFunction "temp";
 val mutable block_count = ref 0;
(* Temporary list on a per-function basis to check variables that point to bad
 * functions.
 *)
 (* Finds all the call lvals (variables) in a CIL instruction. *)
   method find_lvals_instr (i: instr) : lval list =
   begin
    match i with
        | Call(lval_option,exp, exp_list,  _) ->
          begin
            match lval_option with
            | Some (lval) -> lval :: [];
            | _   -> [];
          end
        | Set (lval, exp, _) ->
                lval::[];
        | _ -> [];
   end

   method find_lvals_exp (e: exp) : lval list =
   begin
    (match e with
        | Const(c) ->
                []; (* Constant *)
        | Lval(l) -> (* Lvalue *)
                l::[];
        | SizeOf(s) ->
            []; (* SizeOf(type) *)
        | SizeOfE(e) ->
            (* (self#analyze_exp e);  (* SizeOf(expression) *) *)
             [];
        | SizeOfStr(s) ->
            []; (* SizeOfStr, as in sizeof ("strlit") *)
        | AlignOf(t) ->
            []; (* Corresponds to the GCC __alignof__ *)
        | AlignOfE(e) ->
            (* (self#analyze_exp e);*)
             [];
        | UnOp(op, e, t) ->          
                (self#find_lvals_exp e); (* Unary operator, includes type of
                result *)
        | BinOp(b, e1, e2, t) ->
            (* Binary operator, includes type of result *)
            (List.append (self#find_lvals_exp e1) (self#find_lvals_exp e2));
        | CastE(t, e) ->
            (self#find_lvals_exp e); (* Cast *)
        | AddrOf(l) ->
            l::[]; (* Address of (lval) *)
         | StartOf(l) ->
            l::[]; (* Conversion from array to a pointer to the beginning of the
            array *)
        );
   end        

  (* Visits every "instruction" *)
  method vinst (i: instr) : instr list visitAction =
    begin
      DoChildren;
    end

  (* Visits every "statement" *)
  method vstmt (s: stmt) : stmt visitAction =
    begin
      DoChildren;
    end

  method vblock (b: block) : block visitAction =
    begin
      block_count := !block_count + 1;
      DoChildren;
    end

     (* Visits every function *)
     method vfunc (f: fundec) : fundec visitAction =
     begin
        curr_func <- f; (*Store the value of current func before getting into
                        deeper visitor analysis. *)

        DoChildren;
     end

     method top_level (f:file) :unit =
     begin
     (* Start the visiting *)
     visitCilFileSameGlobals (self :> cilVisitor) f;
     end
end


(* The second pass of the driver security code pass *)
class driverVisitor = object (self) (* self is equivalent to this in Java/C++ *)
    inherit nopCilVisitor  
    val mutable curr_func : fundec = emptyFunction "temp"; 
    val mutable last_fun_stmt = ref 0;
    val mutable first_fun_stmt = ref 0;
    val mutable pci_chipsets = ref 1;
    val mutable fn_len_data = ref "";
    val mutable call_info_data = ref "";                             
    val mutable ioctl_fns_string = ref "";
(*     val mutable call_depth = ref 0;                                   *)

 (* Finds all the call lvals (variables) in a CIL instruction. *)
   method find_lvals_instr (i: instr) : lval list =
   begin
    match i with
        | Call(lval_option,exp, exp_list,  _) ->
          begin
            match lval_option with
            | Some (lval) -> lval :: [];
            | _   -> [];
          end
        | Set (lval, exp, _) ->
                lval::[];
        | _ -> [];
   end

   (* Finds all the lvals (string) in the a CIL expression (hopefully). 
   *  Do we need to add Const here ?? FIXME 
   *  *)
   method find_lvals_exp (e:exp ) : string list = 
   begin
     match e with 
       | Lval(lh,_)  ->  
               (match lh with
               | Var (vinfo) ->
                       vinfo.vname ::[];
               | Mem(ex) -> self#find_lvals_exp ex;
               );
       | AddrOf(lv_inner) ->
               let (lh, _) = lv_inner in
               (match lh with
               | Var (vinfo)-> 
                    vinfo.vname :: [];
               | Mem(ex) -> self#find_lvals_exp ex;              
               );
        | BinOp (b, e1, e2, typ) ->
                (self#find_lvals_exp e1)@(self#find_lvals_exp e2);
        | UnOp (op, e, typ) ->
                (self#find_lvals_exp e);
        | CastE (typ, e) ->
                (self#find_lvals_exp e);
        | SizeOfE (e) ->
                (self#find_lvals_exp e); 
        | AlignOfE(e) ->
                (self#find_lvals_exp e);
   
       | _ -> [];
   end
     

 (* Finds all the lvals (string) in a CIL expression (hopefully). 
   * Also return lvals found in offset of lval in expression.
   *  *)
   method find_lvals_exp_with_offset (e:exp ) : string list =
   begin
     match e with
       | Lval(lh,o)  ->
               (match lh with
               | Var (vinfo) ->
                       vinfo.vname ::(self#find_lvals_offset o);
               | Mem(ex) -> (self#find_lvals_offset o);
               );
       | AddrOf(lv_inner) -> 
               let (lh, o) = lv_inner in
               (match lh with
               | Var (vinfo)->
                    vinfo.vname :: (self#find_lvals_offset o);
               | Mem(ex) -> (self#find_lvals_offset o);
               );
        | BinOp (b, e1, e2, typ) -> (
                 let str_list = ref [] in
                 str_list := (self#find_lvals_exp e1)@(self#find_lvals_exp e2);  
		!str_list;	
		);
        | UnOp (op, e, typ) ->
                (self#find_lvals_exp e);
        | CastE (typ, e) ->
                (self#find_lvals_exp e);
        | SizeOfE (e) ->
                (self#find_lvals_exp e);
        | AlignOfE(e) ->
                (self#find_lvals_exp e);
	| StartOf(lv_inner) ->
               let (lh, o) = lv_inner in
               (match lh with
               | Var (vinfo)->
                    vinfo.vname :: (self#find_lvals_offset o);
               | Mem(ex) -> (self#find_lvals_offset o);
               );
        | _ -> [];
   end

  (* Finds all lvals (string) in an offset. *)
  method find_lvals_offset (o: offset) : string list =
  begin
      match o with
      | Index(e,o2) -> (self#find_lvals_exp_with_offset e) @ (self#find_lvals_offset o2);
      | _ -> [];
  end
  
  method varprocess(v :varinfo)(iinfo:initinfo) :unit = 
  begin
    match v.vtype with
    | TArray(TComp(c,_), Some(Const(CInt64(i,_,_))),_) ->
				if (String.compare c.cname "pci_device_id" = 0) then 	
				   pci_chipsets := (Int64.to_int i); 
				   Printf.fprintf stderr "%s %d \n" c.cname (Int64.to_int i);

				if (String.compare c.cname "usb_device_id" = 0) then 	
				   pci_chipsets := (Int64.to_int i); 
				   Printf.fprintf stderr "%s %d \n" c.cname (Int64.to_int i);
      | TComp(c,_)-> (
          Printf.fprintf stderr "\n\n|----------\n%s\n------------|\n" c.cname;
          if (String.compare c.cname "pci_device_id" = 0) then (
            Printf.fprintf stderr "pdi: %s.\n" v.vname;
            match v.vtype with
              | TArray(_,Some(Const(CInt64(i,_,_))),_) -> Printf.fprintf stderr "size:%d \n" (Int64.to_int i);
              | _ -> ();

          );

          (* Search in init*) 
          if (String.compare c.cname "pci_driver" = 0) || (String.compare c.cname "usb_driver" = 0) ||
            (String.compare c.cname "scsi_driver" = 0) || (String.compare c.cname "acpi_driver" = 0) ||
            (String.compare c.cname "platform_driver" = 0) || (String.compare c.cname "rio" = 0) ||
            (String.compare c.cname "umc_driver" = 0) || (String.compare c.cname "uart_driver" = 0) ||
            (String.compare c.cname "amba_driver" = 0) || (String.compare c.cname "isa_driver" = 0) ||
            (String.compare c.cname "sysdev_driver" = 0) || (String.compare c.cname "ps3_system_bus_driver" = 0) ||
            (String.compare c.cname "of_platform_driver" = 0) || (String.compare c.cname "xenbus_driver" = 0) ||
            (String.compare c.cname "sdio_driver" = 0)  || (String.compare c.cname "pcmcia_driver" = 0) ||
            (String.compare c.cname  "agp_bridge_driver" = 0) || (String.compare c.cname "tty_driver" = 0) || 
            (String.compare c.cname "vio_driver" = 0) || (String.compare c.cname "pnp_driver" = 0) ||  
            (String.compare c.cname "cx_drv" = 0) || (String.compare c.cname "console" = 0) || 
            (String.compare c.cname "device_driver" = 0) || (String.compare c.cname "fw_driver" = 0) || 
            (String.compare c.cname "i2c_driver" = 0) || (String.compare c.cname "spi_driver" = 0)  ||
            (String.compare c.cname "hid_driver" = 0) || (String.compare c.cname "ide_driver" = 0) || 
            (String.compare c.cname "hpsb_protocol_driver" = 0) || (String.compare c.cname "parisc_driver" = 0) ||
            (String.compare c.cname "locomo_driver" = 0) || (String.compare c.cname "maple_driver" = 0) ||
            (String.compare c.cname "adb_driver" = 0) || (String.compare c.cname "cx8802_driver" = 0) || 
            (String.compare c.cname "saa7146_extension" = 0) || (String.compare "mca_driver" = 0) || 
            (String.compare c.cname "zorro_driver" = 0) || (String.compare "ecard_driver" = 0) || 
            (String.compare c.cname "usb_configuration" = 0) || (String.compare "saa7146_extension" = 0) ||


             
            then (
            match iinfo.init with Some (CompoundInit(t,oilist)) -> (
              for i = 0 to (List.length oilist) -1 do 
                let (curr_o,curr_i) =  (List.nth oilist i) in 
                  match curr_o with (Field(finfo,o)) ->(

                    let match_regexp = regexp (".*"^"shutdown"^".*") in
                    let match_regexp2 = regexp (".*"^"remove"^".*") in
                    let match_regexp3 = regexp(".*"^"disconnect"^".*") in
                      if (Str.string_match match_regexp finfo.fname 0) = true || (Str.string_match match_regexp2 finfo.fname 0) = true 
                       || (Str.string_match match_regexp3 finfo.fname 0) = true then (
                        Printf.fprintf stderr ">>>>>>>>>cleanup fn is (%s)" finfo.fname;
                        match curr_i with (SingleInit(init_exp)) -> (
                          (* Printf.fprintf stderr "%s.\n" (exp_to_string
                           * init_exp); *)
                          match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                            Hashtbl.add cleanup_fns vinfo.vname c.cname;
                            Printf.fprintf stderr "%s" vinfo.vname
                          );
                            |_ -> ();
                        );
                          |_ -> ();
                      );


                      let match_regexp = regexp (".*"^"probe"^".*") in
                        if (Str.string_match match_regexp finfo.fname 0) = true  then (
                          Printf.fprintf stderr ">>>>>>>>>init fn is %s" finfo.fname;
                          match curr_i with (SingleInit(init_exp)) -> (
                            (* Printf.fprintf stderr "%s.\n" (exp_to_string
                             * init_exp); *)
                            match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                              Hashtbl.add init_fns vinfo.vname c.cname;
                              Printf.fprintf stderr "%s" vinfo.vname
                            );
                              |_ -> ();
                          );
                            |_ -> ();
                        ); 


                     
                        let match_regexp = regexp (".*"^"suspend"^".*") in
                        let match_regexp2 = regexp (".*"^"resume"^".*") in
                          if (Str.string_match match_regexp finfo.fname 0) = true 
                            || (Str.string_match match_regexp2 finfo.fname 0) = true then (
                               Printf.fprintf stderr ">>>>>>>>>pm fn is %s" finfo.fname;
                               match curr_i with (SingleInit(init_exp)) -> (
                                 (* Printf.fprintf stderr "%s.\n" (exp_to_string
                                  * init_exp); *)
                                 match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                   Hashtbl.add pm_fns vinfo.vname c.cname;
                                   Printf.fprintf stderr "%s\n" vinfo.vname
                                 );
                                   |_ -> ();
                               );
                                 |_ ->();
                             );


                          let match_regexp = regexp (".*"^"err_handler"^".*") in
                            if (Str.string_match match_regexp finfo.fname 0) = true 
                              then (
                                 Printf.fprintf stderr ">>>>>>>>>err fn is %s:" finfo.fname;
                                 match curr_i with (SingleInit(init_exp)) -> (
                                   (* Printf.fprintf stderr "%s.\n" (exp_to_string
                                    * init_exp); *)
                                   match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                     Hashtbl.add err_fns vinfo.vname c.cname;
                                     Printf.fprintf stderr "%s\n" vinfo.vname;
                                   );
                                     |_ -> ();
                                 );
                                   |_ ->();
                               );




                  );
                    |_ -> ();
              done;
            );
              |_ -> ();
          );                    


          (* Search for error handler fn *) 
          if (String.compare c.cname "pci_error_handlers" = 0) then (
            Printf.fprintf stderr "pci_error_handler  %s\n" v.vname;
            Hashtbl.add err_fns v.vname c.cname;
            match iinfo.init with Some (CompoundInit(t,oilist)) -> (
              for i = 0 to (List.length oilist) -1 do 
                let (curr_o,curr_i) =  (List.nth oilist i) in 
                  match curr_o with (Field(finfo,o)) ->(

                    Printf.fprintf stderr ">>>>>>>>>err fn is (%s)" finfo.fname;
                    match curr_i with (SingleInit(init_exp)) -> (
                      match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                        Hashtbl.add err_fns vinfo.vname c.cname;
                        Printf.fprintf stderr "%s" vinfo.vname
                      );
                        |_ -> ();
                    );
                      |_ -> ();

                  );
                    |_ -> ();
              done;
            );
             |_ -> ();                                              
          );



          (* Search for power management fn *) 
          if (String.compare c.cname "dev_pm_ops" = 0) then (
            Printf.fprintf stderr "dev_pm_ops  %s\n" v.vname;
            Hashtbl.add err_fns v.vname c.cname;
            match iinfo.init with Some (CompoundInit(t,oilist)) -> (
              for i = 0 to (List.length oilist) -1 do 
                let (curr_o,curr_i) =  (List.nth oilist i) in 
                  match curr_o with (Field(finfo,o)) ->(

                    Printf.fprintf stderr ">>>>>>>>>pm fn is (%s)" finfo.fname;
                    match curr_i with (SingleInit(init_exp)) -> (
                      match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                        Hashtbl.add pm_fns vinfo.vname c.cname;
                        Printf.fprintf stderr "%s" vinfo.vname
                      );
                        |_ -> ();
                    );
                      |_ -> ();

                  );
                    |_ -> ();
              done;
            );
            |_ -> ();                                                                    
          );

          (* Search for ioctl ops *)
          if (String.compare c.cname "block_device_operations" = 0) || (String.compare c.cname "net_device_ops" = 0)
            || (String.compare c.cname "ethtool_ops" = 0)  
            || (String.compare c.cname "fb_ops" = 0) || (String.compare c.cname "file_operations" = 0)  ||
             (String.compare c.cname "tty_operations" = 0) || (String.compare c.cname "snd_pcm_ops" = 0) ||
             (String.compare c.cname "cdrom_device_ops" = 0) || (String.compare c.cname "ide_disk_ops" = 0) ||  
             (String.compare c.cname "loop_func_table" = 0) || ( String.compare c.cname "pccard_resource_ops" = 0) ||
             (String.compare c.cname "atmdev_ops" = 0)  || (String.compare c.cname "snd_emux_operators" = 0) ||
             (String.compare c.cname "proto_ops" = 0) || (String.compare c.cname "scsi_host_template" = 0) ||
             (String.compare c.cname "pccard_operations" = 0) || (String.compare c.cname "ata_port_operations" = 0) ||
             (String.compare c.cname "thermal_zone_device_ops" = 0) || (String.compare c.cname "atmphy_ops" = 0) ||
             (String.compare c.cname "atm_tcp_ops" = 0 ) ||  (String.compare c.cname "backlight_ops" = 0)   || 
             (String.compare c.cname "c2port_ops" = 0) || (String.compare c.cname "dca_ops" = 0) || 
             (String.compare c.cname "dma_map_ops" = 0) || (String.compare c.cname "fb_ops" = 0) ||
             (String.compare c.cname "fb_tile_ops" = 0) || (String.compare c.cname "mpc8xx_pcmcia_ops" = 0) ||
             (String.compare c.cname "hdlcdrv_ops" = 0) || (String.compare c.cname "ide_port_ops" = 0) ||
             (String.compare c.cname "ide_dma_ops" = 0) || (String.compare c.cname "ide_tp_ops" = 0) ||
             (String.compare c.cname "iommu_ops" = 0 ) || (String.compare c.cname "lcd_ops" = 0) ||
             (String.compare c.cname "mdiobb_ops" = 0) || (String.compare c.cname "proto_ops" = 0) ||
             (String.compare c.cname "nsc_gpio_ops" = 0) || (String.compare c.cname "pci_ops" = 0) ||
             (String.compare c.cname "hotplug_slot_ops" = 0) || (String.compare c.cname "ppp_channel_ops" = 0) ||
             (String.compare c.cname "rio_ops" = 0) || (String.compare c.cname "rio_route_ops" = 0) ||
             (String.compare c.cname "rtc_class_ops" = 0) || (String.compare c.cname "uart_ops" = 0) ||
             (String.compare c.cname "thermal_cooling_device_ops" = 0) || (String.compare c.cname "tty_ldisc_ops" = 0) ||
             (String.compare c.cname "virtqueue_ops" = 0) || (String.compare c.cname "virtio_config_ops" = 0) || 
             (String.compare c.cname "plat_vlynq_ops" = 0) || (String.compare c.cname " wm97xx_mach_ops" = 0) || 
              (String.compare c.cname "radeon_asic" = 0) || (String.compare c.cname "b43_phy_operations" =0) ||
             (String.compare c.cname "oxygen_model" = 0) || (String.compare c.cname "mii_phy_ops" = 0)  ||
             (String.compare c.cname "vio_driver_ops" = 0) then (
               Printf.fprintf stderr "bd variable is: %s.\n" v.vname;
               match iinfo.init with Some (CompoundInit(t,oilist)) -> (
                 for i = 0 to (List.length oilist) -1 do
                   let (curr_o,curr_i) =  (List.nth oilist i) in
                     match curr_o with (Field(finfo,o)) ->(

                       let match_regexp = regexp (".*"^"ioctl"^".*") in
                         if (Str.string_match match_regexp finfo.fname 0) = true  then (
                           Printf.fprintf stderr "assign fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             (* Printf.fprintf stderr "%s.\n" (exp_to_string
                              * init_exp); *)
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add ioctl_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );


                       let match_regexp = regexp (".*"^"open"^".*") in 
                       let match_regexp2 = regexp (".*"^"detect"^".*") in
                       let match_regexp3 = regexp (".*"^"init"^".*") in
                       let match_regexp4 = regexp (".*"^"install"^".*") in
                       let match_regexp5 = regexp (".*"^"detect"^".*") in
                       let match_regexp6 = regexp (".*"^"alloc"^".*") in
                         if (Str.string_match match_regexp finfo.fname 0) = true ||
                          (Str.string_match match_regexp2 finfo.fname 0) = true ||
                         (Str.string_match match_regexp3 finfo.fname 0) = true ||
                          (Str.string_match match_regexp4 finfo.fname 0) = true ||
                          (Str.string_match match_regexp5 finfo.fname 0) = true ||
                           (Str.string_match match_regexp6 finfo.fname 0) = true    then (
                           Printf.fprintf stderr "open fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             (* Printf.fprintf stderr "%s.\n" (exp_to_string
                              * init_exp); *)
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add init_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );


                       let match_regexp = regexp (".*"^"close"^".*") in
                       let match_regexp2 = regexp (".*"^"stop"^".*") in
                       let match_regexp3 = regexp (".*"^"release"^".*") in
                       let match_regexp4 = regexp (".*"^"uninit"^".*") in
                       let match_regexp5 = regexp (".*"^"cleanup"^".*") in
                       let match_regexp6 = regexp (".*"^"free"^".*") in
                       let match_regexp7 = regexp (".*"^"destroy"^".*") in
                       let match_regexp8 = regexp (".*"^"suspend"^".*") in
                         if (Str.string_match match_regexp finfo.fname 0) = true ||
                        (Str.string_match match_regexp2 finfo.fname 0) = true  ||
                        (Str.string_match match_regexp3 finfo.fname 0) = true ||
                        (Str.string_match match_regexp4 finfo.fname 0) = true ||
                        (Str.string_match match_regexp5 finfo.fname 0) = true ||
                        (Str.string_match match_regexp6 finfo.fname 0) = true ||
                        (Str.string_match match_regexp7 finfo.fname 0) = true ||
                        (Str.string_match match_regexp8 finfo.fname 0) = true then (
                           Printf.fprintf stderr "close fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             (* Printf.fprintf stderr "%s.\n" (exp_to_string
                              * init_exp); *)
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add cleanup_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );

                         

                       let match_regexp = regexp (".*"^"select"^".*") in
                       let match_regexp2 = regexp (".*"^"check"^".*") in
                       let match_regexp3 = regexp (".*"^"change"^".*") in (* was change_mtu *)
                       let match_regexp4 = regexp (".*"^"status"^".*") in
                       let match_regexp5 = regexp (".*"^"params"^".*") in (* was set_rx_mode *)
                       let match_regexp6 = regexp (".*"^"enable"^".*") in
                       let match_regexp7 = regexp (".*"^"disable"^".*") in
                       let match_regexp8 = regexp (".*"^"config"^".*") in
                       let match_regexp9 = regexp (".*"^"get"^".*") in
                       let match_regexp10 = regexp (".*"^"set"^".*") in (* implicitly includes reset *)
                       let match_regexp11 = regexp (".*"^"configure"^".*") in
                       let match_regexp12 = regexp (".*"^"info"^".*") in
                       let match_regexp13= regexp (".*"^"show"^".*") in
                       let match_regexp14 = regexp (".*"^"check"^".*") in
                       let match_regexp15 = regexp (".*"^"supported"^".*"^"|"^".*"^"hw_ctrl"^".*"^"|"^".*"^"on"^".*"^"|"^".*"^"off"^".*") in
                 
                         if (Str.string_match match_regexp finfo.fname 0) = true || (Str.string_match match_regexp2 finfo.fname 0) = true ||
                        (Str.string_match match_regexp3 finfo.fname 0) = true || (Str.string_match match_regexp4 finfo.fname 0) = true ||
                        (Str.string_match match_regexp5 finfo.fname 0) = true || (Str.string_match match_regexp6 finfo.fname 0) = true ||
                      (Str.string_match match_regexp7 finfo.fname 0) = true || (Str.string_match match_regexp8 finfo.fname 0) = true ||
                          (Str.string_match match_regexp9 finfo.fname 0) = true || (String.compare c.cname "ethtool_ops" = 0) ||
                         (Str.string_match match_regexp10 finfo.fname 0) = true || (Str.string_match match_regexp11 finfo.fname 0) = true ||
                         (Str.string_match match_regexp12 finfo.fname 0) = true ||  (Str.string_match match_regexp13 finfo.fname 0) = true ||
                         (Str.string_match match_regexp14 finfo.fname 0) = true || (Str.string_match match_regexp15 finfo.fname 0)    then (
                           Printf.fprintf stderr "\n++++++config fname is %s" finfo.fname;
                           match curr_i with (SingleInit(init_exp)) -> (
                             match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                               Hashtbl.add config_fns vinfo.vname c.cname;
                               Printf.fprintf stderr "%s" vinfo.vname
                           );
                             |_ -> ();
                           );
                             |_ -> ();
                         );


                               let match_regexp = regexp (".*"^"proc"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) = true  then (

                                   Printf.fprintf stderr "proc fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add proc_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                            
                                 ); 




                               (* Generate devctl information *)  
                               let match_regexp = regexp (".*"^"devctl"^".*") in
                               let match_regexp2 = regexp (".*"^"sysctl"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp2 finfo.fname 0) = true then (

                                   Printf.fprintf stderr "devctl fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add devctl_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                             
                                 );



                                 

                               (* Generate devctl information *)  
                               let match_regexp = regexp (".*"^"read"^".*") in
                               let match_regexp2 = regexp (".*"^"write"^".*") in
                               let match_regexp3 = regexp (".*"^"xmit"^".*") in
                               let match_regexp4 = regexp (".*"^"changed"^".*") in
                               let match_regexp5 = regexp (".*"^"timeout"^".*") in
                               let match_regexp6 = regexp (".*"^"flush"^".*") in
                               let match_regexp7 = regexp (".*"^"start"^".*") in
                               let match_regexp8 = regexp (".*"^"throttle"^".*") in
                               let match_regexp9 = regexp (".*"^"prepare"^".*") in
                               let match_regexp10 = regexp (".*"^"trigger"^".*") in
                               let match_regexp11 = regexp (".*"^"ack"^".*"^"|"^".*"^"reset"^".*"^"|"^".*"^"update"^".*"^"|"^".*"^"load"^".*") in
                               let match_regexp12 = regexp (".*"^"rx"^".*"^"|"^".*"^"tx"^".*"^"|"^".*"^"kick"^".*"^"|"^".*"^"valid"^".*") in
                               let match_regexp13 = regexp (".*"^"mem"^".*"^"|"^".*"^"qc"^".*"^"|"^".*"^"freeze"^".*"^"|"^".*"^"thaw"^".*") in
                               let match_regexp14 = regexp (".*"^"load"^".*"^"|"^".*"^"notify"^".*"^"|"^".*"^"bind"^".*"^"|"^".*"^"interrupt"^".*") in
                               let match_regexp15 = regexp (".*"^"access"^".*"^"|"^".*"^"sync"^".*"^"|"^".*"^"exec"^".*"^"|"^".*"^"data"^".*") in
                               let match_regexp16 = regexp (".*"^"io"^".*"^"|"^".*"^"map"^".*"^"|"^".*"^"silence"^".*"^"|"^".*"^"copy"^".*") in
                               let match_regexp17 = regexp (".*"^"fb_cursor"^".*"^"|"^".*"^"fb_image"^".*"^"|"^".*"^"fb_tile"^".*"^"|"^".*"^"filter"^".*") in
                               let match_regexp18 = regexp (".*"^"connect"^".*"^"|"^".*"^"socket"^".*"^"|"^".*"^"send"^".*"^"|"^".*"^"rec"^".*") in
                               let match_regexp19 = regexp (".*"^"fb_blank"^".*"^"|"^".*"^"fb_pan"^".*"^"|"^".*"^"fb_fill"^".*"^"|"^".*"^"fb_copy"^".*") in
                               let match_regexp20 = regexp (".*"^"sysex"^".*"^"|"^".*"^"reset"^".*"^"|"^".*"^"command"^".*"^"|"^".*"^"scan"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp2 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp3 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp4 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp5 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp6 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp7 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp8 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp9 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp10 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp11 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp12 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp13 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp14 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp15 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp16 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp17 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp18 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp19 finfo.fname 0) = true  ||
                                  (Str.string_match match_regexp20 finfo.fname 0) = true  
                                 
                                 
                                 
                                 then (

                                   Printf.fprintf stderr "core fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add core_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                            
                                  ); 



                               (* Generate error handline information *)  
                               let match_regexp = regexp (".*"^"eh"^".*"^"handler"^".*") in
                               let match_regexp2 = regexp (".*"^"error"^".*") in
                                 if (Str.string_match match_regexp finfo.fname 0) = true ||
                                  (Str.string_match match_regexp2 finfo.fname 0) = true  then (

                                   Printf.fprintf stderr "errr fname is %s" finfo.fname;
                                   match curr_i with (SingleInit(init_exp)) -> (
                                     match init_exp with (AddrOf(Var(vinfo),offset)) -> (
                                       Hashtbl.add err_fns vinfo.vname c.cname;
                                       Printf.fprintf stderr "%s" vinfo.vname
                                     );
                                       |_ -> ();
                                   );
                                     |_ -> ();                                             
                                  );
                                 
                                 
                             );
                               |_ -> ();
                         done;           
                       ); 
                         | _ -> ();
                                (* Hashtbl.add ioctl_fns finfo.fname
                                 * "block_device_operations"; *)
                     );

		     if (String.compare c.cname "pci_driver" = 0) then	(
			Printf.fprintf stderr "%s.\n" v.vname;
		     for i = 0 to (List.length c.cfields) - 1 do
          		let curr_cf = (List.nth c.cfields i) in
          		Printf.fprintf stderr "f:%s\n" curr_cf.fname;
			if (String.compare curr_cf.fname "id_table" = 0) then	(
			 Printf.fprintf stderr "id_table found \n";
			match curr_cf.ftype with
              		   | TArray(_,Some(Const(CInt64(i,_,_))),_) -> Printf.fprintf stderr "%d \n" (Int64.to_int i);
              		   | _ -> ();   
			);
		     done;

		     );
		);
    | _ -> (); 
  end
  
  (* Process globals *)
   method initial_filter (glob: global) : unit =
   begin
     let varinitinfo : initinfo = { init = None; } in
     match glob with
       | GType(t, _) ->  (); (* t.tname;  *)
       | GCompTag(c, _) -> (); (* c.cname; *)
       | GCompTagDecl(c, _) -> (); (* c.cname;*)
       | GEnumTag(e, _) -> (); (* Printf.fprintf stderr "en:%s.\n" e.ename;  *)
       | GEnumTagDecl(e, _) -> (); (* Printf.fprintf stderr "en:%s.\n" e.ename; *)
       | GVarDecl(v, _) ->  self#varprocess v varinitinfo; (* v.vname;   *)
       | GVar(v, i, _) -> self#varprocess v i; Printf.fprintf stderr "vname:%s.\n" v.vname;
       | GFun(f, _) -> (); (* f.svar.vname; *)
       | GAsm(s, _) ->  (); (*s; *)
       | GPragma(a, _) -> (); (* "attribute";*)
       | GText (t) -> (); (* t; *)
   end
  
   (*Visits every instruction -> Second pass *)
   method vinst (ins: instr) : instr list visitAction =
   begin
     DoChildren;
   end

   (* Visits every "statement" ( Last Pass) *)
   method vstmt (s: stmt) : stmt visitAction =
   begin
        if (!currentLoc.line > 0) then
        last_fun_stmt := !currentLoc.line;
	DoChildren;
   end

   (* Visits every block  Pass 2*)
   method vblock (b: block) : block visitAction =
   begin
      DoChildren;
   end

  method retlength (b:string):int =
    begin
      try
        Hashtbl.find fn_start_end b;
      with Not_found ->  0;
    end
  
  method retcloc (b:string) : int =
    begin
      try
        Hashtbl.find cloc b;
      with Not_found -> 0;
    end
  
  method is_ioctl (b:string) : int =
   begin   
      try
        Hashtbl.find ioctl_fns b;
        1;
      with Not_found -> 0;
   end

  method is_init (b:string) : int =
   begin   
      try
        Hashtbl.find init_fns b;
        1;
      with Not_found -> 0;
   end
 
  method is_cleanup (b:string) : int =
    begin
      try
        Hashtbl.find cleanup_fns b;
        1;
      with Not_found ->0;
    end
  
  method is_pm (b:string) : int =
   begin
    try
     Hashtbl.find pm_fns b;
     1;
    with Not_found -> 0;
   end
 
  method is_modpm (b:string) : int =
   begin
    try
     Hashtbl.find modpm_fns b;
     1;
    with Not_found -> 0;
   end
 
  method devctl_hash (b:string) : int =
    begin
      try     
        Hashtbl.find devctl_fns b;
        1;
      with Not_found ->  0;

    end
      
     
  method is_devctl (b:string) : int =
    begin
      let ret_val = ref 0 in
      let match_regexp = regexp(".*"^"sysctl"^".*") in
        ret_val := !ret_val + self#devctl_hash b;
        if (Str.string_match match_regexp b 0) = true then
          ret_val:= 1; 
        !ret_val;                     
    end

  method proc_hash (b:string) : int =
   begin
    try
     Hashtbl.find proc_fns b;
     1;
    with Not_found -> 0;
   end
  
  method is_proc (b:string) : int =
    begin
      let ret_val = ref 0 in
      let match_regexp = regexp(".*"^"proc"^".*") in
        ret_val := !ret_val + self#proc_hash b;
        if (Str.string_match match_regexp b 0) = true then
          ret_val:= 1; 
        !ret_val;                     
    end



  method core_hash (b:string) : int =
   begin
    try
     Hashtbl.find core_fns b;
     1;
    with Not_found -> 0;
   end
  
  method is_core (b:string) : int =
    begin
      let ret_val = ref 0 in
      let match_regexp = regexp(".*"^"interrupt"^".*") in
        ret_val := !ret_val + self#core_hash b;
        if (Str.string_match match_regexp b 0) = true then
          ret_val:= 1; 
        !ret_val;                     
   end 

  method ttd (b:string): int =
    begin
      try
        Hashtbl.find ttd_fns b;
        1;
      with Not_found -> 0;
    end

  method ttk (b:string): int =
    begin
      try
       Hashtbl.find ttk_fns b;
      1;
      with Not_found -> 0;
    end

  method is_allocator (b:string): int =
   begin
    try
     Hashtbl.find allocator_fns b;
    1;
    with Not_found -> 0;
   end 
     
  method is_err (b:string) :int =
   begin
     try
       Hashtbl.find err_fns b;
       1;
     with Not_found -> 0;
   end
 
  method is_config (b:string):int =
   begin
    try
     Hashtbl.find config_fns b;
    1;
    with Not_found -> 0;
   end 
     
  method has_recovery : int =
   begin  
     Hashtbl.length err_fns; 
   end

  method seencnid(a:int): int =
   begin
     try Hashtbl.find seencnids a;
         (* Printf.fprintf stderr "seen %d.\n" a;*)
         1;
     with Not_found -> 0;
   end   

  method gseencnid(a:int): int =
   begin
     try Hashtbl.find gseencnids a;
         (* Printf.fprintf stderr "seen %d.\n" a;*)
         1;
     with Not_found -> 0;
   end   

  method traversecallers (a:callnode)(call_depth: int) :int = 
    begin
      if (call_depth < 10000) then (
      if (IH.length a.cnCallers > 0) then  (
        (* call_depth <- succ call_depth; *)
        Hashtbl.add seencnids a.cnid 1;
        let node_len = ref 0 in
        let callees =  [] in 
        let recurseCg  _ (cl:callnode):unit =
            if ((self#seencnid cl.cnid) != 1) then ( (* if  (a.cnid !=
                                                                 cl.cnid) then ( *)

         (* Propogate tags *)
              let fn_name = (nodeName a.cnInfo) in
              let cl_name = (nodeName cl.cnInfo) in

                (* Propogate tags for ttd and ttk in upward direction *)

                if (self#ttd fn_name = 1) then
                  Hashtbl.add ttd_fns cl_name fn_name;

                if (self#ttk fn_name = 1) then
                  Hashtbl.add ttk_fns cl_name fn_name;
                
           node_len := !node_len + (self#traversecallers cl (call_depth + 1)); 
           );
        in
          IH.iter recurseCg a.cnCallers;

          Hashtbl.add gseencnids a.cnid 1; 
          (* Printf.fprintf stderr "Addding %d + %d.\n" !node_len *)
          (self#retlength(nodeName a.cnInfo));
          !node_len + self#retlength(nodeName a.cnInfo); 
      )
       else 0; 
      )
      else  0;                                   
    end

  method retcumlength (a:callnode)(call_depth: int) :int = 
    begin
      if (call_depth < 10000) then (
      if (IH.length a.cnCallees > 0) then  (
        (* call_depth <- succ call_depth; *)
        Hashtbl.add seencnids a.cnid 1;
        let node_len = ref 0 in
        let callees =  [] in 
        let recurseCg  _ (cl:callnode):unit =
            if ((self#seencnid cl.cnid) != 1) then ( (* if  (a.cnid !=
                                                                 cl.cnid) then ( *)

         (* Propogate tags *)
              let fn_name = (nodeName a.cnInfo) in
              let cl_name = (nodeName cl.cnInfo) in

                if ((self#gseencnid a.cnid) != 1) then  ( 
                  call_info_data := !call_info_data^Printf.sprintf " %s %s"fn_name cl_name;
                );

                                                           
                if (self#is_init fn_name = 1) then
                  Hashtbl.add init_fns cl_name fn_name;

                if (self#is_ioctl fn_name = 1) then
                  Hashtbl.add ioctl_fns cl_name fn_name;             

                if (self#is_cleanup fn_name = 1) then
                  Hashtbl.add cleanup_fns cl_name fn_name;

                if (self#is_pm fn_name = 1) then
                  Hashtbl.add pm_fns cl_name fn_name;

                if (self#is_err fn_name = 1) then
                  Hashtbl.add err_fns cl_name fn_name;

                if (self#is_config fn_name =1) then
                  Hashtbl.add config_fns cl_name fn_name;
                
                if (self#is_modpm fn_name =1) then
                  Hashtbl.add modpm_fns cl_name fn_name;
                
                if (self#is_proc fn_name =1) then
                  Hashtbl.add proc_fns cl_name fn_name;

                if (self#is_devctl fn_name = 1) then
                  Hashtbl.add devctl_fns cl_name fn_name;

                if (self#is_core fn_name = 1) then
                  Hashtbl.add core_fns cl_name fn_name;

                if (self#is_allocator fn_name = 1) then
                  Hashtbl.add allocator_fns cl_name fn_name;
        
                (* Propogate tags for ttd and ttk in upward direction *)

                if (self#ttd cl_name = 1) then
                  Hashtbl.add ttd_fns fn_name cl_name;

                if (self#ttk cl_name = 1) then
                  Hashtbl.add ttk_fns fn_name cl_name;
                
           node_len := !node_len + (self#retcumlength cl (call_depth + 1)); 
          (* node_len := self#retlength(nodeName cl.cnInfo); *)
           (* Printf.fprintf stderr ">>(depth %d)seen fn: %s node_len is  %d.\n" call_depth (nodeName
            cl.cnInfo) !node_len;*) 
           );
        in
          IH.iter recurseCg a.cnCallees;

          Hashtbl.add gseencnids a.cnid 1; 
          (* Printf.fprintf stderr "Addding %d + %d.\n" !node_len *)
          (self#retlength(nodeName a.cnInfo));
          !node_len + self#retlength(nodeName a.cnInfo); 
      )
       else (self#retlength(nodeName a.cnInfo)); 
      )
      else  0;                                   
    end

  method printcumlen (b:string)(a:callnode):unit =
    begin
        (* Printf.fprintf stderr ">>>>>>>FN(%s) : \n" b; *)
        let fn_cloc = ref 0 in
           (* call_depth :=0; *)
           fn_cloc := (self#retcumlength a 0); 
        Hashtbl.add cloc b !fn_cloc;
        Hashtbl.clear seencnids;
         (* Printf.fprintf stderr "%s length is %d.\n\n" b !fn_cloc; 

        let fn_dloc = ref 0 in
           fn_dloc := (self#traversecallers a 0);
        Hashtbl.clear seencnids;
       *) 
    end
     
   method printfnlen (b:string)(a:int): unit =
   begin
      let is_devctl = ref 0 in  
      begin
(*
        try
          let ret_str = Hashtbl.find  devctl_fns (b) in
         begin 
		is_devctl := 1;
                fn_len_data := !fn_len_data^Printf.sprintf "%s %d %d %d " b a !is_ioctl !is_devctl;
		Printf.fprintf stderr "Found %s.\n >>%s\n\n\n" b !fn_len_data;
         end
         with Not_found -> ();

 *)
                           
        fn_len_data := !fn_len_data^Printf.sprintf "%s %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d " b a
         (self#is_ioctl b) (self#is_init b) (self#retcloc b)  (self#is_cleanup b) (self#is_pm b) (self#is_err b) (self#is_config b) (self#is_proc b) (self#is_modpm b) (self#is_devctl b) (self#ttd b) (self#ttk b) (self#is_allocator b) (self#is_core b);  
     end
   end

  method addtottd (b:string) : unit =
    begin
      Hashtbl.add ttd_fns b "";
    end

  method addtoalloc (b:string) : unit =
   begin
    Hashtbl.add allocator_fns b "";
   end 

  method addtottk (b:string): unit =
    begin
      Hashtbl.add ttk_fns b "";
    end

     
   (* Visits every function  Pass 2*)
   method vfunc (f: fundec) : fundec visitAction =
   begin
     (* Build CFG for every function.*) 
     (Cil.prepareCFG f);
     (Cil.computeCFGInfo f false);  (* false = per-function stmt numbering,
                                             true = global stmt numbering *)

      (* Printf.fprintf stderr "\n Saw function  %s  Descending  end %d start %d
       \n " curr_func.svar.vname !last_fun_stmt !first_fun_stmt;  *)
     if !last_fun_stmt > 0 then (
        let fn_len = ref 0 in
          (* Printf.fprintf stderr "\n%s:size %d %d =%d:\n"  curr_func.svar.vname !last_fun_stmt !first_fun_stmt (!last_fun_stmt - !first_fun_stmt); *)
          fn_len := (!last_fun_stmt - !first_fun_stmt) + 2;
          Hashtbl.add fn_start_end curr_func.svar.vname !fn_len; 
     );

     curr_func <- f; (*Store the value of current func before getting into
                       deeper visitor analysis. *)
     first_fun_stmt := !currentLoc.line;

     DoChildren;
   end
    
    method top_level (f:file) :unit =
      begin

        (* Do some points-to analysis  No idea wat this does*)
        Ptranal.no_sub := false;
        Ptranal.analyze_mono := true;
        Ptranal.smart_aliases := false;
        Ptranal.analyze_file f; (* Performs actual points-to analysis *)
        Ptranal.compute_results false; (* Just prints the  points-to-graph to screen *)
       
        for i = 0 to (List.length f.globals) - 1 do
          let curr_g = (List.nth f.globals i) in
          self#initial_filter curr_g;
	 done;
        
        (* Start the visiting *)
        visitCilFileSameGlobals (self :> cilVisitor) f; 

        Printf.fprintf stderr "---------------DRIVER STUDY----------------------\n";
        (* Calculate the function length for the last fn *)
        let fn_len = ref 0 in
          fn_len := (!last_fun_stmt - !first_fun_stmt) + 2;
          Hashtbl.add fn_start_end curr_func.svar.vname !fn_len;
        
        (* At this point all function lengths are calculated *)
 
        Hashtbl.add init_fns "init_module" "module_init";
        Hashtbl.add cleanup_fns "cleanup_module" "module_exit";
        List.iter self#addtottd device_fns;
        List.iter self#addtoalloc alloc_fns;          
        List.iter self#addtottk kernel_fns;  
        
        let cg = computeGraph f in  
        Hashtbl.iter self#printcumlen cg; 
        
        Hashtbl.iter self#printfnlen fn_start_end;
	(* Hashtbl.iter self#printioctlfns ioctl_fns;  *)

       
        Printf.printf "len %d ids %d hr %d fns %s\n" (!last_fun_stmt + 1) !pci_chipsets self#has_recovery !fn_len_data; 
        Printf.fprintf stderr "len:%d ids %d hr %d fns %s\n" (!last_fun_stmt + 1) !pci_chipsets self#has_recovery !fn_len_data;
        
      (* 
        if (gen_call_info = 1) then     (
          Printf.fprintf stderr "fns %s\n" !call_info_data;
          Printf.printf "fns %s\n" !call_info_data;
        );
       *)
        
        (* Print all function name-length pairs   
        Hashtbl.iter self#printfnlen fn_start_end;
        *)
        Printf.printf "\n";

    end 
end    
    

(*******************************
* Init
********************************)

(*Toplevel function for our Beefy Analysis *)
let dobeefyanalysis (f:file)  : unit = 	
  begin
      (* Printf.printf "#### Execution time: %f\n" (Sys.time()));
      *)
     
      let initVisitor : initialVisitor = new initialVisitor in
      initVisitor#top_level f;
     
     
      let driVisitor : driverVisitor = new driverVisitor in
      driVisitor#top_level f;
    
  end

(* The feature description for the drivers module *)  
let feature : featureDescr = 
  { fd_name = "drivers";              
    fd_enabled = ref false;
    fd_description = "Device Driver Security Analysis";
    fd_extraopt = [];
    fd_doit = dobeefyanalysis;
    fd_post_check = true      (*What does this do?? *) 
  } 

  
