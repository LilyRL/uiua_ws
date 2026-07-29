# Experimental!

~ "log.ua" ~ Log

┌─╴WebServer
  ~State {Map FileTypeMap Listener}

  ┌─╴Utils
    ~Route {Type InnerData}
    RouteTypeServeFile ← 0
    RouteTypeDynamic   ← 1
    ~ServeFileRoute {Path MimeType}
    ~DynamicRoute {Code MimeType}

    FileTypeMap ← (
      map {"html" "htm" "js" "json"} {"text/html" "text/html" "application/javascript" "application/json"}
    )

    SplitByFirst ← (
      # get indexes of matching elements in array
      ⊚⊸=
      # check if the length of the array is 0, aka if there are any matches
      #   if there are no matches: return the string as is
      #   if there is at least one match, we can take the first index and partition the array around it
      ⨬(⊜□≠⊙(⇡⊸⧻)⊢|◌)=0⊸⧻
    )

    SplitByLast ← (
      # get indexes of matching elements in array
      ⊚⊸=
      # check if the length of the array is 0, aka if there are any matches
      #   if there are no matches: return the string as is
      #   if there is at least one match, we can take the first index and partition the array around it
      ⨬(⊜□≠⊙(⇡⊸⧻)⊣|◌)=0⊸⧻
    )

    # get mime type from: file name, state
    RecogniseFileType ← |2.2 (⬚"text/plain"get⊣SplitByLast @. ⊙⊸State~FileTypeMap)

    # create a serve file route
    Sfr ← (
      Route RouteTypeServeFile ServeFileRoute
    )

    Dr ← (
      Route RouteTypeDynamic DynamicRoute
    )

    # this is super hacky, but uiua has no way to eval code at runtime or create function pointers
    Eval ← |1 (
      &runc {"uiua" "eval" ∘}
      ◌◌
      ↘¯3
      ⍜⊜∘≡⋅@\n ⊸⦷ "\\n"
    )

    # code, arguement
    EvalWithArguement ← |2 (
      Eval $"_ (_);⊙◌" ⊙repr
    )

    RemoveQuotesIfPresent ← |1 (
      ⍥(↘1) =@" ⊸⊢
      ⍥(↘¯1) =@" ⊸⊣
    )

    ParseRequest ← (
      # split by newlines
      ⊜□⊸≠"\n"
      # remove the first line, e.g: "GET / HTTP/1.1",
      # since that has no colon and need to be parsed seperately
      ⊸⊢
      Log~Log⊸∘
      ⊙(↘1)
      # split by colon
      ⊙≡(
        SplitByFirst @: °□
        # trim the first and last character from the value, as it will start with ' ' and end with \r
        ⍜⊣(□ ↘¯1↘1 °□)
        □
      )
      ⊙(↘¯1)
      # convert the list of keys and values into a map
      ⊙(map⊢₂⍉≡°□)

      # begin parsing the first line. split by spaces
      ⊜□⊸≠@ ↘¯1°□

      # insert the 3 components of the first line into the map
      ⊙(insert "Verb") ⟜(⊡ 0)
      ⊙(insert "Path") ⟜(⊡ 1)
      insert "Protocol" ⊡ 2
    )

    # files are served from the /www directory
    GetFile ← |1 (
      &fras $"www/_"
    )

    # wrap text in a HTTP OK message
    # media-type, body
    ReturnOk ← |2 (˜$"HTTP/1.1 200 OK\nContent-Length: _\nContent-Type: _\n\n_" ⊙⊸⧻)

    # get text content of route
    # route, request
    HandleRoute ← |2 (
      ⊸Route~Type°□
      # 0: ServeFileRoute
      ⨬(Route~InnerData
        ⊸ServeFileRoute~MimeType
        ⊙ServeFileRoute~Path
        ⊙GetFile
        ReturnOk
        ⊙◌
      | Route~InnerData
        ⊸DynamicRoute~MimeType
        ⊙(RemoveQuotesIfPresent EvalWithArguement DynamicRoute~Code)
        ReturnOk
      | ⍤ "Invalid route type")
    )

    AcceptConnection ← |1 (
      &tcpa ⊸State~Listener
      ⟜(&rs 4096)
      # dip this section, because we won't use the tcp connection until later
      ⊙(ParseRequest
        # we only support GET requests for now
        °"GET"°□⊸get "Verb"
        # push map onto stack
        ⊙(⊸State~Map)
        # get path of request
        □↘1°□ ⊸get"Path"
        # get route, if it doesn't exist, try get route 404, else return string "404"
        # path, req, map
        # req, path, map
        # dip by get -- req, route, map
        # bw route, req, map

        # reorient from path, req, map -> req, path, map
        ⊃⋅∘∘
        ⍣(˜HandleRoute⊙⊸get
        | ˜HandleRoute⊙(get□"404")◌
        | ReturnOk "text/plain" "404: Page not found")
        ⊙◌)
      ˜(⊸&w)
      &cl
    )

    FindReplace ← ()

  └─╴

  New ← |1 (
    State map [] [] Utils~FileTypeMap &tcpl
  )

  Listen ← |1.0 (
    ◌⍢(Utils~AcceptConnection) 1
  )

  # inserts key and value into sitemap
  # key, value, state object
  Serve ← |3 (
    ⍜(⊙⊙State~Map)insert ∩□
  )

  # serves a file at its path
  # path, state object
  ServeFile ← |2 (
    ⟜Utils~RecogniseFileType
    ⊸∘
    # check if path ends in .html
    =5/+=".html"⬚@ ⊸↙¯5
    ⨬( # if it is not a html file, just serve it normally
      Serve ⊙(Utils~Sfr)
    | # if it is a html file, we want to serve it from /whatever.html
      # and /whatever (without .html)
      Serve ↘¯5 ⊙⊙◌◠Serve ⊙Utils~Sfr
    )
  )

  # serves a file at a custom path
  # site path, file path, state object
  ServeFileAt ← (
    ⊙⟜Utils~RecogniseFileType
    ⊙Utils~Sfr
    Serve
  )

  # serves a file as the index
  # file path, state object
  ServeIndex ← |2 (ServeFileAt "")

  ServeDir ← |2 (
    # get a list of all the files in the directory
    # remove leading /
    &fld $"www/_"
    # serve all of the files
    ∧(
      °□
      # check if it is a file,
      # if it is: serve it,
      # if it isnt: serve all the files inside it
      ⨬(ServeDir|ServeFile) ⊙(↘4) ⊸&fif
    )
  )

  DynamicRoute! ←^ (
    °□⊢
    # escape quotes
    ⍜⊜∘≡⋅"\\\\\"" ⊸⦷ "\\\""
    ⍜⊜∘≡⋅"\\\"" ⊸⦷ "\""
    $"˜WebServer~Serve WebServer~Utils~Dr \"_\""
  )
└─╴

# served files must be in www/
WebServer~New "localhost:8000"
WebServer~ServeDir ""
WebServer~ServeIndex "index.html"
WebServer~DynamicRoute!(⌊×100⚂) "text/plain" "rand"
WebServer~DynamicRoute!(°[°$"_-_-_ _:_:_"] ⍚(⬚@0↙¯⊙°⋕) [4 2 2 2 2 2] datetime now) "text/plain" "time"
WebServer~DynamicRoute!($"{\"randomNumber\": _}" ⚂) "application/json" "rand_json"
WebServer~DynamicRoute!(&fras ⊡⊡⌊×⚂⊸⧻⊚⊸≡₀(=5/+=".html"⬚@ ↙¯5°□) &fld "www/") "text/html" "rand_page"
WebServer~Listen
