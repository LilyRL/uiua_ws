~ "ansi.ua" ~ Ansi

┌─╴Log
  PrintColoredText ← (&p $"__")
  Debug            ← (PrintColoredText Ansi~HighBlack $"[DEBUG] _")
  Log              ← (PrintColoredText Ansi~Blue $"[LOG]   _")
  Warn             ← (PrintColoredText Ansi~Yellow $"[WARN]  _")
  Error            ← (PrintColoredText Ansi~Red $"[ERROR] _")
└─╴
