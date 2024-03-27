# Streamlined YAML to multilingual translation library
#
# (c) 2024 George Lemon | LGPL License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/oris

import std/[critbits, strutils, os, sequtils, with]
import experimental/diff
import pkg/nyml

type
  Language = ref object
    id, src: string
    sheets: CritBitTree[nyml.Document]
    files: seq[string]

  OrisContext* = object
    lang: Language
    manager: Oris

  Oris = ref object
    main: string
    langs: CritBitTree[Language]

  OrisError* = object of CatchableError

proc parseSheets(o: Oris, id, path: string) =
  var lang = Language(id: id, src: path)
  for fpath in walkPattern(path / "*"):
    let fp = fpath.splitFile
    if fp.ext in [".yaml", ".yml"]:
      add lang.files, fpath
      lang.sheets[fp.name] = yaml(readFile(fpath)).toJson
  o.langs[id] = lang

proc initOris*(src, default: string): Oris =
  ## Initialize an instance of `Oris`
  result = Oris(main: default)
  for path in walkDirs(src / "*"):
    let
      id = path.extractFilename
      path = path.absolutePath
    result.parseSheets(id, path)

proc newContext*(o: Oris, id: string = ""): OrisContext =
  ## Create a new OrisContext
  let id = if id.len == 0: o.main else: id
  if likely(o.langs.hasKey(id)):
    result.lang = o.langs[id]
    result.manager = o
  else:
    raise newException(OrisError, "Unknown language id `" & id & "`")

proc switch*(ctx: var OrisContext, id: string) =
  ## This is kinda useless, but you can change
  ## the language in the same context
  if likely(ctx.manager.langs.hasKey(id)):
    ctx.lang = ctx.manager.langs[id]
  else:
    raise newException(OrisError, "Unknown language id `" & id & "`")

proc toString(x: JsonNode): string =
  if likely(x != nil):
    return 
      case x.kind
      of JInt:
        $(x.getInt)
      of JFloat:
        $(x.getFloat)
      of JString:
        x.getStr
      of JBool:
        $(x.getBool)
      of JNull:
        "null"
      else: "" 
  result = "null"

proc l*(ctx: OrisContext, key: string, v: varargs[string]): string =
  ## Use `ctx` OrisContext to get translation by `key`
  let k = key.split(".")
  if likely(ctx.lang.sheets.hasKey(k[0])):
    let x: JsonNode = ctx.lang.sheets[k[0]].get(k[1..^1].join(".")) 
    let v = v.toSeq
    if v.len != 0:
      return x.toString() % v
    return x.toString()
