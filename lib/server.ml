open Lwt

(* Set up server to recursively listen for a new client to handle *)
let init sockaddr  =
  let sockfd = Util.new_sockfd () in
  Lwt_unix.bind sockfd sockaddr >>= fun () ->
  Lwt_io.printl "Successfully bound." >>= fun () ->
  Lwt_unix.listen sockfd 10;

  let rec serve () =
    Lwt_io.printl "Listening for connection." >>= fun () ->
    Lwt_unix.accept sockfd >>= fun (client_sockfd, _) ->
    Lwt_io.printl "Accepted new connection." >>= fun () ->
    let (ichan, ochan) = Util.init_channels client_sockfd in
    Lwt_io.printl "You can write messages to the client now." >>= fun () ->
      Util.handle_connection (ichan, ochan) "Server"  >>= serve
  in
  serve ()
