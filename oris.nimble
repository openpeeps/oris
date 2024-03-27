# Package

version       = "0.1.0"
author        = "George Lemon"
description   = "Streamlined YAML to multilingual translation library"
license       = "MIT"
srcDir        = "src"
# bin           = @["lingo"]
# binDir        = "bin"

# Dependencies

requires "nim >= 2.0.2"
requires "flatty"
requires "nyml"
requires "watchout"


task dev, "dev":
  exec "nim c -o:./bin/oris src/oris.nim"