# A simple i18n library for Nim
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/oris

## Oris is a simple internationalization (i18n) library for Nim. This module implements 
## language management, translation retrieval, and serialization/deserialization of language data
## using [FastBinaryEncoding](https://chronoxor.github.io/FastBinaryEncoding/documents/FBE.html) (FBE) format

import std/[macros, tables, strutils, os]
import pkg/openparser/fbe

type
  TranslatableSring* = ref object
    ## Represents a translatable string that can be used in the Oris internationalization library.
    ## It contains the translation text and any arguments that may be needed for interpolation
    text: string
      # The translation text that can be displayed to the user.
    args: seq[string]
      # A translatable string that contains the translation
      # text and any arguments for interpolation

  Language* = ref object
    code: string
    translations: TableRef[string, TranslatableSring]
      # A table that maps translation keys to their corresponding `TranslatableString`
      # objects, which contain the translation text and any arguments for interpolation

  Oris* = ref object
    ## The main Oris instance that holds all the languages and translations
    default*: string
      ## The default language code to use for translations when no
      ## specific language is provided
    languages: TableRef[string, Language]
      # A table that maps language codes to their corresponding
      # Language objects, which contain translations
      

proc newOris*(default: string): Oris =
  ## Initializes the Oris internationalization library
  result = Oris(default: default, languages: newTable[string, Language]())

proc newTranslatableString*(text: string, args: seq[string] = @[]): TranslatableSring =
  ## Creates a new translatable string with the given text, arguments, and complexity flag
  TranslatableSring(text: text, args: args)

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
    expectKind(row[1], nnkStmtList)
    expectKind(row[1][0], nnkStrLit)
    
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

    translationRows.add(
      nnkStmtList.newTree(
        nnkAsgn.newTree(
          nnkBracketExpr.newTree(
            nnkDotExpr.newTree(
              langIdent,
              ident"translations"
            ),
            newLit(row[0].strVal)
          ),
          if args.len > 0:
            newCall(
              ident("newTranslatableString"),
              newLit(input),
              nnkPrefix.newTree(ident"@", args)
            )
          else:
            newCall(ident("newTranslatableString"), newLit(input))
        )
      )
    )
  result = newStmtList()
  add result, quote do:
    var `langIdent` = Language(code: `code`,
            translations: newTable[string, TranslatableSring]())
    `lang`.languages[`code`] = `langIdent`
    `translationRows`

proc encode*(lang: Language; path: string) =
  ## Serialize a Language instance to disk using openparser.fbe buffer layout.
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
        # args as vector<string>
        writeVector[string](bbb, it.val.args, proc (bbbb: var Buffer; s: string) = bbbb.writeString(s))
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
              let k = bbb.readString()
              let text = bbb.readString()
              let args = readVector[string](bbb, proc (bbbb: var Buffer): string = bbbb.readString())
              (key: k, val: newTranslatableString(text, args))
          )
      )
      for it in entries:
        lang.translations[it.key] = it.val
    else:
      discard
  endReadRootStruct(b)

when isMainModule:
  # init Oris instance with default language "en"
  var i18n = newOris(default = "en")

  # define a language
  newLanguage i18n, "en":
    welcome: "Welcome to Sunday!"
    welcome_message: "Your Sunday instance is now live. You have $count new messages."
    overview_title: "Overview"
    overview_description: "This is your Sunday dashboard where you can manage your website, plugins, themes, and more."
    hello_user: "Hello, $name! Welcome back to your dashboard."
    new_messages: "You have $count new messages."

  # defune a new language
  newLanguage i18n, "es":
    welcome: "¡Bienvenido a Sunday!"
    welcome_message: "Tu instancia de Sunday ya está en vivo. Tienes $count nuevos mensajes."
    overview_title: "Visión general"
    overview_description: "Este es tu panel de control de Sunday donde puedes administrar tu sitio web, plugins, temas y más."
    hello_user: "¡Hola, $name! Bienvenido de nuevo a tu panel de control."
    new_messages: "Tienes $count nuevos mensajes."


  # verify translation from Oris instance using default language
  echo i18n.translate("welcome_message", ["3"])   # Output: "Welcome to Sunday!"
  echo i18n.translate("hello_user", @["George"])  # Output: "Hello, George! Welcome back to your dashboard."

  # verify translation from specific language
  echo ""
  echo i18n.translate("es", "welcome_message", ["5"])   # Output: "¡Bienvenido a Sunday!"
  echo i18n.translate("es", "hello_user", @["George"])  # Output: "¡Hola, George! Bienvenido de nuevo a tu panel de control."

  # encode specific language to disk using FastBinaryEncoding (FBE) format
  echo ""
  i18n.languages["en"].encode("en.fbe")

  # decode language from disk and verify translation works
  var en2: Language
  en2.decode("en.fbe")

  # verify translation from decoded language
  echo en2.translate("welcome")    # Output: "Welcome to Sunday!"
