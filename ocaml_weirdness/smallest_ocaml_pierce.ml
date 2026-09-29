fun x0 ->
  let exception E in
  (let exception E in x0)
    (fun x1 ->
      match
        match raise E with
        | None -> None
        | Some x2 ->
            Some (
              match None with
              | None -> x1
              | Some x3 -> x0 x2)
      with
      | None -> raise E
      | Some x2 -> raise E)