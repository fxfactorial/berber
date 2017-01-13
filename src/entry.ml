open Cmdliner

let doc_location pkg = Filename.(
    concat
      (concat
         (Podge.Unix.read_process_output "opam config var share"
          |> StringLabels.concat ~sep:"\n")
         "doc")
      pkg
  )

let package_name =
  let doc = "opam package name" in
  Arg.(required &
       pos ~rev:true 0 (some string) None &
       info [] ~doc ~docv:"opam package name")

let view_in_browser =
  let doc = "Whether to open in web browser" in
  Arg.(value & flag & info ["w"; "web-browser"] ~doc)

let modules root = Soup.(
    Filename.concat root "index.html"
    |> read_file
    |> parse
    |> select "td[class=module] > a"
    |> fold (fun accum elem_node ->
        match attribute "href" elem_node with Some s -> s :: accum
                                            | None -> accum
      ) []
  )

let begin_program pkg view_in_browser =
  let pkg_docs_location = doc_location pkg in
  if view_in_browser then
    begin
      let doc_page = Filename.concat pkg_docs_location "index.html" in
      match Podge.Unix.read_process_output "uname" |> String.concat "\n" with
      | "Darwin" ->
        Podge.Unix.read_process_output ("open " ^ doc_page)
        |> ignore
      | "Linux" ->
        Podge.Unix.read_process_output ("xdg-open " ^ doc_page)
        |> ignore
      | os -> prerr_endline ("Don't know how to open a browser on " ^ os)
    end
  else begin
    let modules_parsed =
      (try modules pkg_docs_location
       with _ -> failwith ("Check if " ^ pkg ^ " had docs installed"))
      |> List.map (fun module_link ->
          Filename.concat pkg_docs_location module_link
          |> Soup.read_file
          |> Soup.parse
          (* Some thing smarter? *)
          (* |> Soup.select "* > [class=keyword]" *)
          (* |> Soup.fold (fun accum elem_node -> *)
          (*     match Soup.parent elem_node with *)
          (*       None -> accum *)
          (*     | Some elem_node -> *)
          (* Soup.to_string elem_node |> print_endline; *)
          (*       Soup.texts elem_node :: accum *)
          (*   ) [] *)
          (* |> List.flatten *)
          (* |> String.concat "" |> String.trim *)

          |> Soup.texts |> String.concat " " |> String.trim
        )
    in
    modules_parsed
    |> List.filter (fun s ->
        if s = "\t" || s = "\n" || s = "" then false else true
      )
    |> String.concat ""
    |> fun signatures ->
    let s = Filename.temp_file "berber-docs" "" in
    Soup.write_file (s ^ ".ml") signatures;
    Printf.sprintf "src-hilite-lesspipe.sh %s.ml | less -R" s
    |> Sys.command
    |> ignore

  end

let entry_point = Term.(pure begin_program $ package_name $ view_in_browser)

let top_level_info =
  let doc = "Get Documentation about an OCaml package" in
  let man =
    [`S "DESCRIPTION";
     `P "This tools assumes the docs were made by ocamldoc, or that \
         an index.html exists for share/doc of your opam package";
     `S "MISC";
     `P "This program is written in the OCaml programming language";
     `S "AUTHOR";
     `P "Edgar Aroutiounian"]
  in
  Term.info ~version:"1.0.0" ~doc ~man "berber"

let () =
  Printexc.record_backtrace true;
  match Term.eval (entry_point, top_level_info) with
  | `Ok () -> ()
  | _ -> ()
