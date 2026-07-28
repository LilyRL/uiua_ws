# Experimental!

┌─╴WebServer
  ~State {Map Listener}

  ┌─╴Utils
    SplitByFirst ← (
      # get indexes of matching elements in array
      ⊚⊸=
      # check if the length of the array is 0, aka if there are any matches
      #   if there are no matches: return the string as is
      #   if there is at least one match, we can take the first index and partition the array around it
      ⨬(⊜□≠⊙(⇡⊸⧻)⊢|◌)=0⊸⧻
    )

    ParseRequest ← (
      # split by newlines
      ⊜□⊸≠"\n"
      # remove the first line, e.g: "GET / HTTP/1.1",
      # since that has no colon and need to be parsed seperately
      ⊸⊢
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

    GetFile ← |1 (
      &fras $"www/_"
    )

    ReturnOk ← |1 ($"HTTP/1.1 200 OK\nContent-Length: _\n\n_" ⊸⧻)

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
        □↘1°□ get"Path"
        # get route, if it doesn't exist, try get route 404, else return string "404"
        ⍣(GetFile ⊸get|GetFile ⊸get□"404"◌|"404")
        ⊙◌)
      ˜(&w ReturnOk)
    )

  └─╴

  New ← |1 (
    State map [] [] &tcpl
  )

  Listen ← |1.0 (
    ◌⍢(Utils~AcceptConnection) 1
  )

  # inserts key and value into sitemap
  # key, value, state object
  Serve ← |3 (
    ⍜(⊙⊙State~Map)insert ∩□
  )

  # serves a file as the index
  # file path, state object
  ServeIndex ← |2 (Serve "")

  # serves a file at its path
  # path, state object
  ServeFile ← |2 (
    ⊸∘
    # check if path ends in .html
    =5/+=".html"⬚@ ⊸↙¯5
    ⨬( # if it is not a html file, just serve it normally
      Serve
    | # if it is a html file, we want to serve it from /whatever.html
      # and /whatever (without .html)
      Serve↘¯5 ⟜∘ ⟜Serve
    )
  )

└─╴

# served files must be in www/
WebServer~New "localhost:8000"
WebServer~ServeFile "404.html"
WebServer~ServeIndex "index.html"
WebServer~Listen
