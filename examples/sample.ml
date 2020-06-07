open Opium.Std

let response_of_string body = Response.make ~body:(Body.of_string body) ()
let e1 = get "/version" (fun _ -> response_of_string "testing" |> Lwt.return)

let e2 =
  get "/hello/:name" (fun req ->
      let name = param req "name" in
      response_of_string ("hello " ^ name) |> Lwt.return)
;;

let e4 =
  put "/hello/:x/from/:y" (fun req ->
      let x, y = param req "x", param req "y" in
      let msg = Printf.sprintf "Hello %s! from %s." x y in
      response_of_string msg |> Lwt.return)
;;

let splat_route =
  get "/testing/*/:p" (fun req ->
      let p = param req "p" in
      response_of_string
        (Printf.sprintf "__ %s __" p ^ (req |> splat |> String.concat ":"))
      |> Lwt.return)
;;

(* exceptions should be nicely formatted *)
let throws =
  get "/yyy" (fun _ ->
      Logs.warn (fun f -> f "Crashing...");
      failwith "expected failure!")
;;

(* TODO: a static path will not be overriden. bug? *)
let override_static =
  get "/public/_tags" (fun _ -> response_of_string "overriding path" |> Lwt.return)
;;

let app =
  App.empty
  |> e1
  |> e2
  |> e4
  |> throws
  |> middleware (Middleware.static ~local_path:"./" ~uri_prefix:"/public" ())
  |> splat_route
;;

let _ = app |> App.run_command
