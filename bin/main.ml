open Lwt
open ClientServer

let () =
  let rec run () =
    Stdlib.print_endline "Enter \"client\" or \"server\"";
    match Stdlib.read_line () with
    | "client" -> Lwt_main.run (Client.init Util._SOCKET_ADDR)
    | "server" -> Lwt_main.run (Server.init Util._SOCKET_ADDR)
    | cmd      -> print_endline ("Unknown command \"" ^ cmd ^ "\"");
                  run ()
  in
  run ()