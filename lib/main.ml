open Lwt.Infix

let enter_hooks = Lwt_dllist.create ()

let rec call_hooks hooks  =
  match Lwt_dllist.take_opt_l hooks with
  | None -> Lwt.return_unit
  | Some f ->
    (* Run the hooks in parallel *)
    let _ =
      Lwt.catch f
        (fun exn ->
           (* call_hooks enter_hooks is executed joined with installing the logs
              reporter, use printf here (otherwise the message may be lost). *)
           Printf.printf "call_hooks: exn %s\n%!" (Printexc.to_string exn);
           Lwt.return_unit)
    in
    call_hooks hooks

(* Main runloop, which registers a callback so it can be invoked
   when timeouts expire. Thus, the program may only call this function
   once and once only. *)
let run t =
  (* If the platform doesn't have SIGPIPE, then Sys.set_signal will
     raise an Invalid_argument exception. If the signal does not exist
     then we don't need to ignore it, so it's safe to continue. *)
  (try Sys.(set_signal sigpipe Signal_ignore) with Invalid_argument _ -> ());
  let t = call_hooks enter_hooks <&> t in
  Lwt_main.run (
    Lwt.catch
      (fun () -> t)
      (fun e ->
         Logs.err (fun m -> m "main: %s\n%s" (Printexc.to_string e)
                      (Printexc.get_backtrace ()));
         Lwt.return_unit))

let at_exit f = Lwt_main.at_exit f
let at_enter f = ignore (Lwt_dllist.add_l f enter_hooks)
let at_exit_iter f = ignore (Lwt_main.Leave_iter_hooks.add_first f)
let at_enter_iter f = ignore (Lwt_main.Enter_iter_hooks.add_first f)
