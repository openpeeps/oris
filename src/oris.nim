# A simple i18n library for Nim
#
# (c) 2026 George Lemon | MIT License
#          Made by Humans from OpenPeeps
#          https://github.com/openpeeps/oris

import std/[macros, tables, strutils]

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
      ## The default language code to use for translations when no specific language is provided
    languages: TableRef[string, Language]
      # A table that maps language codes to their corresponding Language objects, which contain translations

proc initOris*(default: string): Oris =
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

proc translate*(i18n: Oris, key: string): string =
  ## Translates a given key using the specified language in the Oris instance
  if likely(i18n.languages[i18n.default].translations.hasKey(key)):
    let translation = i18n.languages[i18n.default].translations[key]
    return translation.text
  return key # if translation is not found

proc translate*(i18n: Oris, key: string, vargs: seq[string]): string =
  ## Translates a given key using the specified language in the Oris instance
  if likely(i18n.languages[i18n.default].translations.hasKey(key)):
    let translation = i18n.languages[i18n.default].translations[key]
    var values: seq[string]
    for i, arg in translation.args:
      add values, arg
      add values, vargs[i]
    if translation.args.len == vargs.len:
      return translation.text % values
    return translation.text
  else:
    return key # if translation is not found

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

