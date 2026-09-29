
type 'a rouge= Jaune of ('a rouge -> 'a)
let zcomb f =
  (fun (Jaune x) -> f (fun v -> x (Jaune x) v)) 
    (Jaune (fun (Jaune x) -> f (fun v -> x (Jaune x) v)))

let fib = zcomb (fun f n -> if n <= 1 then 1 else f (n - 1) + f (n - 2)) 
