open Lwt
open ClientServer

(* ALTERNATIVE VERSION THAT RUNS SERVER AS BACKGROUND THREAD AND CLIENT AS MAIN THREAD *)
module Server  = struct
  (* Handle the same client connection until closed *)
  let rec handle_connection (ichan, ochan)  =
    Lwt_io.read_line_opt ichan >>= fun msg ->
      match msg with
      | Some msg ->
          Lwt_io.printl ("[Client]: " ^ msg) >>= fun () ->
          Lwt_io.write_line ochan ("Message received \"" ^ msg ^ "\"") >>= fun () ->
          handle_connection (ichan, ochan)
      | None ->
          Lwt_io.printl "Client connection closed."

  (* Set up server to listen for and then handle a single client connection *)
  let init sockaddr  =
    let sockfd = Util.new_sockfd () in
    Lwt_unix.bind sockfd sockaddr >>= fun () ->
    Lwt_io.printl "Successfully bound." >>= fun () ->
    Lwt_unix.listen sockfd 10 ;
    let rec serve () =
      Lwt_io.printl "Listening for connection." >>= fun () ->
      Lwt_unix.accept sockfd >>= fun (client_sockfd, _) ->
      Lwt_io.printl "Accepted new connection." >>= fun () ->
      let (ichan, ochan) = Util.init_channels client_sockfd in
      Lwt_io.write_line ochan "Connected." >>= fun () ->
      handle_connection (ichan, ochan) >>= serve
    in
    serve ()
end

module Client = struct
  (* Handle a server connection until closed *)
  let rec handle_connection (ichan, ochan) =
    Lwt_io.read_line_opt ichan >>= fun msg ->
      match msg with
      | Some server_msg ->
          Lwt_io.printl ("[Server]: " ^ server_msg) >>= fun () ->
          Lwt_io.printl "Enter a message: " >>= fun () ->
          Lwt_io.read_line Lwt_io.stdin >>= fun client_msg ->
          Lwt_io.write_line ochan client_msg >>= fun () ->
          handle_connection (ichan, ochan)
      | None ->
          Lwt_io.printl "Server connection closed."

  (* Set up client to connect to and then handle a server connection *)
  let init sockaddr  =
    let sockfd = Util.new_sockfd () in
    Lwt_unix.connect sockfd sockaddr >>= fun () ->
    let (ichan, ochan) = Util.init_channels sockfd in
    handle_connection (ichan, ochan)
end

let () =
  Lwt.async (fun () -> Server.init Util._SOCKET_ADDR);
  Lwt_main.run @@ Client.init Util._SOCKET_ADDR
