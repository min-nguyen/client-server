open Lwt

(* Set up client to connect to a server until it terminates *)
let init sockaddr  =
  let sockfd = Util.new_sockfd () in
  Lwt_unix.connect sockfd sockaddr >>= fun () ->
  Lwt_io.printl "Successfully connected." >>= fun () ->
  let (ichan, ochan) = Util.init_channels sockfd in
  Lwt_io.printl "You can write messages to the server now." >>= fun () ->
  Util.handle_connection (ichan, ochan) "Client" ?start_t:None
