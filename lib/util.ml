open Lwt
open Lwt_io

open Kleisli
module LwtKleisli : Kleisli with type 'a m = 'a Lwt.t = struct
  open Lwt
  type 'a m = 'a Lwt.t
  let (^>=>) f g x = f x >>= g
end

let _SOCKET_ADDR
  = Unix.ADDR_INET (Unix.inet_addr_of_string "127.0.0.1", 9000)

(* Creates a fresh file descriptor. Not a pure function. *)
let new_sockfd () =
    Lwt_unix.socket Lwt_unix.PF_INET      (* IPv4 address*)
                    Lwt_unix.SOCK_STREAM  (* stream-based communication *)
                    0                     (* use a TCP protocol *)

(* Create input and output channel from a socket descriptor *)
let init_channels sockfd =
  let ichan = of_fd ~mode:Input sockfd in
  let ochan = of_fd ~mode:Output sockfd in
  (ichan, ochan)

(* Message from standard input or remote connection. *)
type msg_ty =
  | StdInMsg of string
  | IChanMsg of string

(* Forward function composition *)
let (^>>>) f g x = g (f x)

(* Read from standard input, and read/write to remote connection *)
let rec handle_connection ?(start_t = Unix.gettimeofday ()) (ichan, ochan) name  =
  let open LwtKleisli in
  (* Wait for data from the stdin or ichan. Process into a message type. *)
  pick [ stdin  |> read_line_opt ^>=> Option.map (fun s -> StdInMsg s) ^>>> return ;
          ichan |> read_line_opt ^>=> Option.map (fun s -> IChanMsg s) ^>>> return ;
        ]
  >>= function
    (* Message from standard input. *)
    | Some (StdInMsg stdin_msg) ->
        let start_t' = Unix.gettimeofday () in
        write_line ochan ("[From " ^ name ^ "]: " ^ stdin_msg) >>= fun () ->
        handle_connection (ichan, ochan) name ~start_t:start_t'
    (* Message from remote connection. *)
    | Some (IChanMsg ichan_msg) ->
        (match ichan_msg with
          (* Simply an acknowledgement that a previously sent message was successful *)
        | "ACK"  ->
            let roundtrip_time = Unix.gettimeofday() -. start_t in
            printl ("<Received acknowledgement>. Roundtrip time: " ^ string_of_float roundtrip_time ^ "s")
          (* Arbitrary message *)
        | _     ->
            printl ichan_msg >>= fun () ->
            write_line ochan "ACK") >>= fun () ->
        handle_connection (ichan, ochan) name ~start_t:start_t
    (*  *)
    | None ->
        printl "Remote connection closed."
