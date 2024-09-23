module type Kleisli = sig
  type 'a m
  (* Forward monadic function composition *)
  val (^>=>) : ('a -> 'b m) -> ('b -> 'c m) -> ('a -> 'c m)
end
