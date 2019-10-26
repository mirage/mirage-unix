(* From lwt/src/unix/lwt_main.ml *)
let rec run t =
  (* Wakeup paused threads now. *)
  Lwt.wakeup_paused ();
  match Lwt.poll t with
  | Some x -> x
  | None ->
    (* Call enter hooks. *)
    Mirage_runtime.run_enter_iter_hooks ();
    (* Do the main loop call. *)
    Lwt_engine.iter (Lwt.paused_count () = 0);
    (* Wakeup paused threads again. *)
    Lwt.wakeup_paused ();
    (* Call leave hooks. *)
    Mirage_runtime.run_leave_iter_hooks ();
    run t

(* If the platform doesn't have SIGPIPE, then Sys.set_signal will
   raise an Invalid_argument exception. If the signal does not exist
   then we don't need to ignore it, so it's safe to continue. *)
let ignore_sigpipe () =
  try Sys.(set_signal sigpipe Signal_ignore) with Invalid_argument _ -> ()

let protect t =
  Lwt.catch
    (fun () -> t)
    (fun e ->
       Logs.err (fun m ->
           m "main: %a\n%s" Fmt.exn e (Printexc.get_backtrace ()));
       Lwt.return_unit)

(* Main runloop, which registers a callback so it can be invoked
   when timeouts expire. Thus, the program may only call this function
   once and once only. *)
let run t =
  ignore_sigpipe ();
  run (protect t)

let () =
  at_exit (fun () ->
      Lwt.abandon_wakeups ();
      run (Mirage_runtime.run_exit_hooks ()))
