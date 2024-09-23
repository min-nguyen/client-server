(* Global constant. *)
val _SOCKET_ADDR : Lwt_unix.sockaddr
(* Creates a fresh file descriptor. Not a pure function. *)
val new_sockfd : unit -> Lwt_unix.file_descr
(* Create input and output channel from a socket descriptor *)
val init_channels :  Lwt_unix.file_descr -> Lwt_io.input_channel * Lwt_io.output_channel
(* Message from standard input or remote connection. *)
type msg_ty =
  | StdInMsg of string
  | IChanMsg of string
(* Read from standard input, and read/write to remote connection *)
val handle_connection : ?start_t:float -> Lwt_io.input_channel * Lwt_io.output_channel -> string -> unit Lwt.t
