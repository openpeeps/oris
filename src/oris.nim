# A simple i18n library for Nim
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/oris

## Oris is a simple internationalization (i18n) library for Nim. This module implements 
## language management, translation retrieval, and serialization/deserialization of language data
## using [FastBinaryEncoding](https://chronoxor.github.io/FastBinaryEncoding/documents/FBE.html) (FBE) format
## 
## Features:
## - Define multiple languages with translation keys and values
## - Support for pluralization with context-aware rules
## - Serialize and deserialize language data to/from disk using FBE for efficient storage and sharing
## - Runtime switching between languages and retrieval of translations with optional interpolation

import std/[macros, tables, strutils, os]
import pkg/openparser/fbe

type
  PluralRule* = object
    ## A single plural branch: `match = -1` means the `else` branch
    context: string
      # an optional context string to distinguish
      # different plural forms
    match: int
      # the count value to match for this plural form,
      # or -1 for the "else" branch
    text: string
      # the translation text for this plural form
    args: seq[string]

  TranslatableSring* = ref object
    ## Represents a translatable string that can be used in the Oris internationalization library.
    ## It contains the translation text and any arguments that may be needed for interpolation
    text: string
      # The translation text that can be displayed to the user.
    args: seq[string]
      # A translatable string that contains the translation
      # text and any arguments for interpolation
    plurals: seq[PluralRule]
      # A sequence of plural rules for handling different plural forms based on a count

  Language* = ref object
    code*: string
    translations*: TableRef[string, TranslatableSring]
      # A table that maps translation keys to their corresponding `TranslatableString`
      # objects, which contain the translation text and any arguments for interpolation

  Oris* = ref object
    ## The main Oris instance that holds all the languages and translations
    default*: string
      ## The default language code to use for translations when no
      ## specific language is provided
    languages*: TableRef[string, Language]
      # A table that maps language codes to their corresponding
      # Language objects, which contain translations

proc newOris*(default: string): Oris =
  ## Initializes the Oris internationalization library
  result = Oris(default: default, languages: newTable[string, Language]())

proc newTranslatableString*(text: string, args: seq[string] = @[]): TranslatableSring =
  ## Creates a new translatable string with the given text, arguments, and complexity flag
  TranslatableSring(text: text, args: args)

proc newPluralRule*(ctx: string, match: int, text: string, args: seq[string] = @[]): PluralRule =
  ## Creates a new plural rule with the given match value, text, and arguments
  PluralRule(context: ctx, match: match, text: text, args: args)

proc getLanguage*(i18n: Oris, code: string): Language =
  ## Retrieves a language from the Oris instance by its code
  if i18n.languages.hasKey(code):
    return i18n.languages[code]
  else:
    raise newException(ValueError,
      "Language with code '" & code & "' not found in Oris instance.")

proc addLanguage*(i18n: Oris, code: string, translations: TableRef[string, TranslatableSring]) =
  ## Adds a new language to the Oris instance with the given code and translations
  if i18n.languages.hasKey(code):
    raise newException(ValueError,
      "Language with code '" & code & "' already exists in Oris instance.")
  i18n.languages[code] = Language(code: code, translations: translations)

proc translateImpl(translations: TableRef[string, TranslatableSring];
                   key: string; vargs: openArray[string] = []): string =
  # Core translation logic shared by all translate overloads
  if likely(translations.hasKey(key)):
    let translation = translations[key]
    if vargs.len == 0:
      return translation.text
    if translation.args.len == vargs.len:
      var values: seq[string]
      for i in 0 ..< translation.args.len:
        add values, translation.args[i]
        add values, vargs[i]
      return translation.text % values
    return translation.text
  return key

proc translatePlural*(lang: Language; key: string;
                      counts: openArray[(string, int)]): string =
  ## Handles single or multi-context pluralization.
  ## `counts` is e.g. `[("dogs", 2), ("cats", 1)]`
  if unlikely(not lang.translations.hasKey(key)): return key
  let t = lang.translations[key]
  if t.plurals.len == 0: return t.text

  var countMap = initTable[string, int](counts.len)
  for (ctx, n) in counts: countMap[ctx] = n

  var resolved  = initTable[string, string](counts.len)
  var fallbacks = initTable[string, string](counts.len)

  for rule in t.plurals:
    let ctx = rule.context
    if countMap.hasKey(ctx):
      let n = countMap[ctx]
      if rule.match == n:
        resolved[ctx] = rule.text % [ctx, $n]
      elif rule.match == -1:
        fallbacks[ctx] = rule.text % [ctx, $n]

  for ctx, fb in fallbacks:
    if not resolved.hasKey(ctx):
      resolved[ctx] = fb

  # build key-value pairs for the outer template substitution
  var substitutions: seq[string]
  for ctx, text in resolved:
    substitutions.add(ctx)
    substitutions.add(text)

  # Add fallback for unresolved placeholders
  for ctx in countMap.keys:
    if not resolved.hasKey(ctx):
      substitutions.add(ctx)
      substitutions.add("$" & ctx) # mark as unresolved placeholder

  result = t.text % substitutions

proc translatePlural*(i18n: Oris; key: string; counts: openArray[(string, int)]): string =
  ## Translates a pluralizable key using the default language in the Oris instance.
  translatePlural(i18n.languages[i18n.default], key, counts)

proc translatePlural*(i18n: Oris; langCode: string; key: string; counts: openArray[(string, int)]): string =
  ## Translates a pluralizable key using the specified language code in the Oris instance.
  if i18n.languages.hasKey(langCode):
    return translatePlural(i18n.languages[langCode], key, counts)
  return key

proc translate*(lang: Language; key: string): string =
  ## Translates a given key using the specified language.
  ## Returns the translation text if found, otherwise returns the key itself.
  if likely(lang.translations.hasKey(key)):
    return lang.translations[key].text
  return key

proc translate*(lang: Language; key: string; vargs: openArray[string]): string =
  ## Translates a given key using the specified language with interpolation.
  translateImpl(lang.translations, key, vargs)

proc translate*(i18n: Oris; key: string): string =
  ## Translates a given key using the default language in the Oris instance.
  translate(i18n.languages[i18n.default], key)

proc translate*(i18n: Oris; key: string; vargs: openArray[string]): string =
  ## Translates a given key using the default language in the Oris instance with interpolation.
  translateImpl(i18n.languages[i18n.default].translations, key, vargs)

proc translate*(i18n: Oris; langCode: string; key: string): string =
  ## Translates a given key using the specified language code in the Oris instance.
  if i18n.languages.hasKey(langCode):
    return translate(i18n.languages[langCode], key)
  return key

proc translate*(i18n: Oris; langCode: string; key: string; vargs: openArray[string]): string =
  ## Translates a given key using the specified language code in the Oris instance with interpolation.
  if i18n.languages.hasKey(langCode):
    return translateImpl(i18n.languages[langCode].translations, key, vargs)
  return key

macro newLanguage*(lang: untyped, code: static string, translations: untyped) =
  ## Macro for creating a new language with the given ID and translations,
  ## and adds it to the Oris instance provided in the `lang` parameter.
  var text: string
  var langIdent = genSym(nskVar, "newLang")
  var translationRows = newStmtList()

  for row in translations:
    expectKind(row, nnkCall)
    expectKind(row[0], nnkIdent)

    if row[1].kind == nnkDo:
      let body = row[1].last   # the case stmt
      expectKind(body, nnkStmtList)
      var outerTemplate = ""
      var rulesNode = newNimNode(nnkBracket)
      for stmtNode in body:
        case stmtNode.kind
        of nnkAsgn:
          # result = "$dogs and $cats"
          if stmtNode[0].kind == nnkIdent and stmtNode[0].strVal == "result":
            outerTemplate = stmtNode[1].strVal
          else:
            error("Expected `result = \"...\"` as outer template, got: " & repr(stmtNode), stmtNode)
        of nnkCaseStmt:
          let ctx = stmtNode[0].strVal
          for branch in stmtNode:
            case branch.kind
            of nnkOfBranch:
              let matchVal = branch[0].intVal.int
              let text = branch[1][0].strVal
              rulesNode.add(
                newCall(
                  ident"newPluralRule",
                  newLit(ctx),
                  newLit(matchVal),
                  newLit(text),
                  nnkPrefix.newTree(ident"@", newNimNode(nnkBracket))
                )
              )
            of nnkElse:
              let text = branch[0][0].strVal
              rulesNode.add(
                newCall(
                  ident"newPluralRule",
                  newLit(ctx),
                  newLit(-1),
                  newLit(text),
                  nnkPrefix.newTree(ident"@", newNimNode(nnkBracket))
                )
              )
            else: discard
        else: discard
      
      if outerTemplate.len == 0:
        error("Missing `result = \"...\"` outer template in plural block for key: " & row[0].strVal, row)

      let key = newLit(row[0].strVal)
      let tmpl = newLit(outerTemplate)
      translationRows.add quote do:
        `langIdent`.translations[`key`] =
          TranslatableSring(text: `tmpl`, plurals: @`rulesNode`)
      continue
    
    var i = 0
    let input = row[1][0].strVal
    var args = newNimNode(nnkBracket)
    var processed = ""
    var someArg: string
    var collectArg = false

    while i < input.len:
      case input[i]
      of '$':
        # safe bounds check instead of try/except
        if i + 1 < input.len and input[i+1] == '$':
          processed.add("$")
          inc(i)
        else:
          collectArg = true
          processed.add("$")
      of ' ':
        if collectArg and someArg.len > 0:
          args.add(newLit(someArg))
          collectArg = false
          reset(someArg)
        processed.add(" ")
      of 'a'..'z', 'A'..'Z', '0'..'9', '_':
        if collectArg:
          someArg.add(input[i])
        processed.add(input[i])
      else:
        if collectArg and someArg.len > 0:
          args.add(newLit(someArg))
          collectArg = false
          reset(someArg)
        processed.add(input[i])
      inc(i)

    # flush any trailing arg after loop
    if someArg.len > 0:
      args.add(newLit(someArg))

    let key = newLit(row[0].strVal)
    translationRows.add(
      nnkAsgn.newTree(
        nnkBracketExpr.newTree(
          nnkDotExpr.newTree(langIdent, ident"translations"),
          key
        ),
        if args.len > 0:
          newCall(ident"newTranslatableString", newLit(input),
                  nnkPrefix.newTree(ident"@", args))
        else:
          newCall(ident"newTranslatableString", newLit(input))
      )
    )
  result = newStmtList()
  add result, quote do:
    var `langIdent` = Language(code: `code`,
            translations: newTable[string, TranslatableSring]())
    `lang`.languages[`code`] = `langIdent`
    `translationRows`

  when defined(orisDebug):
    echo result.repr

proc encode*(lang: Language; path: string) =
  ## Serialize a Language instance to disk using openparser/fbe format.
  ## 
  ## This can be used to save language data in a compact binary format for sharing
  ## between applications or for efficient storage.
  var b = initBuffer()
  b.reset()
  # root header version 1
  beginRootStruct(b, 1'u32)

  # code (string)
  writeField(b, 1'u16, proc (bb: var Buffer) = bb.writeString(lang.code))

  # translations: vector of (key, trans) where trans = { text, args }
  writeField(b, 2'u16, proc (bb: var Buffer) =
    # collect table entries into seq of tuples
    var entries = newSeq[tuple[key: string, val: TranslatableSring]](0)
    for k, v in lang.translations:
      entries.add((key: k, val: v))
    
    # write vector of entries
    writeVector[tuple[key: string, val: TranslatableSring]](bb, entries,
      proc (bbb: var Buffer; it: tuple[key: string, val: TranslatableSring]) =
        bbb.writeString(it.key)
        bbb.writeString(it.val.text)
        writeVector[string](bbb, it.val.args,
          proc (b4: var Buffer; s: string) = b4.writeString(s))
        # plurals
        writeVector[PluralRule](bbb, it.val.plurals,
          proc (b4: var Buffer; r: PluralRule) =
            b4.writeString(r.context)
            b4.writeInt32LE(r.match.int32)
            b4.writeString(r.text)
            writeVector[string](b4, r.args,
              proc (b5: var Buffer; s: string) = b5.writeString(s))
        )
    )
  )

  endRootStruct(b)

  # write buffer bytes to file
  let n = b.data.len
  var s = newStringOfCap(n)
  s.setLen(n)
  if n > 0:
    copyMem(cast[ptr uint8](addr s[0]), addr b.data[0], n)
  writeFile(path, s)

proc decode*(lang: var Language, path: string) =
  ## Deserialize a Language instance from disk (written by encode).
  let fileData = readFile(path)
  let n = fileData.len
  var b: Buffer
  b.data = newSeq[uint8](n)
  if n > 0:
    copyMem(addr b.data[0], cast[ptr uint8](addr fileData[0]), n)
  b.pos = 0

  lang = Language(translations: newTable[string, TranslatableSring]())

  discard beginReadRootStruct(b) # version returned but unused for now
  var fid: uint16
  var fsz: int
  while readFieldHeader(b, fid, fsz):
    case fid
    of 1'u16:
      lang.code = readFieldValue[string](b, fsz, proc (bb: var Buffer): string = bb.readString())
    of 2'u16:
      let entries = readFieldValue[seq[tuple[key: string, val: TranslatableSring]]](b, fsz,
        proc (bb: var Buffer): seq[tuple[key: string, val: TranslatableSring]] =
          readVector[tuple[key: string, val: TranslatableSring]](bb,
            proc (bbb: var Buffer): tuple[key: string, val: TranslatableSring] =
              let k    = bbb.readString()
              let text = bbb.readString()
              let args = readVector[string](bbb,
                proc (b4: var Buffer): string = b4.readString())
              let plurals = readVector[PluralRule](bbb,
                proc (b4: var Buffer): PluralRule =
                  let ctx   = b4.readString()
                  let m     = b4.readInt32LE().int
                  let pt    = b4.readString()
                  let pargs = readVector[string](b4,
                    proc (b5: var Buffer): string = b5.readString())
                  PluralRule(context: ctx, match: m, text: pt, args: pargs)  # was missing context: ctx
              )
              (key: k, val: TranslatableSring(text: text, args: args, plurals: plurals))
          )
      )
      for it in entries:
        lang.translations[it.key] = it.val
    else:
      discard
  endReadRootStruct(b)
