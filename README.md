<p align="center">
  <img src="https://github.com/openpeeps/oris/blob/main/.github/oris.png" width="120px"><br>
  A simple i18n library for Nim
</p>

<p align="center">
  <code>nimble install oris</code>
</p>

<p align="center">
  <a href="https://openpeeps.github.com/oris">API reference</a><br>
  <img src="https://github.com/openpeeps/oris/workflows/test/badge.svg" alt="Github Actions">  <img src="https://github.com/openpeeps/oris/workflows/docs/badge.svg" alt="Github Actions">
</p>

## 😍 Key Features
- [x] Simple, macro-based interface
- [x] Switch between languages at runtime
- [x] Support for pluralization
- [x] Support for interpolation of variables in translations
- [x] Encode/Decode language data to/from disk using FastBinaryEncoding (FBE)

## Examples
This example shows how to define multiple languages, retrieve translations with interpolation, and serialize/deserialize language data using [FastBinaryEncoding](https://github.com/chronoxor/FastBinaryEncoding) (FBE) format via [pkg/openparser](https://github.com/openpeeps/openparser).

```nim
import pkg/oris

var i18n = newOris(default = "en")

# Define English language
newLanguage i18n, "en":
  welcome: "Welcome to Oris!"
  welcome_message: "Your Oris instance is now live. You have $count new messages."
  dashboard_title: "Dashboard"
  dashboard_description: "This is your Oris dashboard where you can manage your projects, settings, and more."
  greeting_user: "Hello, $name! Welcome back."
  animals do(dogs: int, cats: int):
    result = "$dogs and $cats"
    case dogs:
      of 1: "one dog"
      else: "$dogs dogs"
    case cats:
      of 1: "one cat"
      else: "$cats cats"

# Define Spanish language
newLanguage i18n, "es":
  welcome: "¡Bienvenido a Oris!"
  welcome_message: "Tu instancia de Oris ya está en vivo. Tienes $count nuevos mensajes."
  dashboard_title: "Panel de Control"
  dashboard_description: "Este es tu panel de control de Oris donde puedes administrar tus proyectos, configuraciones y más."
  greeting_user: "¡Hola, $name! Bienvenido de nuevo."
  animals do(dogs: int, cats: int):
    result = "$dogs y $cats"
    case dogs:
      of 1: "un perro"
      else: "$dogs perros"
    case cats:
      of 1: "un gato"
      else: "$cats gatos"

# Showcase translations in the default language ("en")
echo i18n.translate("welcome")
  # "Welcome to Oris!"

echo i18n.translate("welcome_message", ["3"])
  # "Your Oris instance is now live. You have 3 new messages."

echo i18n.translate("greeting_user", @["Alice"])
  # "Hello, Alice! Welcome back."

echo i18n.translate("animals", [("dogs", 2), ("cats", 1)])
  # "2 dogs and one cat"

# Showcase translations in Spanish ("es")
echo i18n.translate("es", "welcome")
  # "¡Bienvenido a Oris!"

echo i18n.translate("es", "welcome_message", ["5"])
  # "Tu instancia de Oris ya está en vivo. Tienes 5 nuevos mensajes."

echo i18n.translate("es", "greeting_user", @["Carlos"])
  # "¡Hola, Carlos! Bienvenido de nuevo."

echo i18n.translate("es", "animals", [("dogs", 1), ("cats", 3)])
  # "un perro y 3 gatos"
```

### Encode and Decode language data
Encode language data to disk using FBE format and decode it back to verify that translations are preserved correctly

```nim
# Encode the English language to disk using FastBinaryEncoding (FBE) format
i18n.languages["en"].encode("en.fbe")

# Decode the language from disk and verify translations
var enDecoded: Language
enDecoded.decode("en.fbe")

# Verify translations from the decoded language
echo enDecoded.translate("welcome")
  # "Welcome to Oris!"

echo enDecoded.translate("welcome_message", ["2"])
  # "Your Oris instance is now live. You have 2 new messages."

echo enDecoded.translate("animals", [("dogs", 1), ("cats", 2)])
  # "one dog and 2 cats"

# Encode the Spanish language to disk
i18n.languages["es"].encode("es.fbe")

# Decode the Spanish language from disk and verify translations
var esDecoded: Language
esDecoded.decode("es.fbe")

# Verify translations from the decoded Spanish language
echo esDecoded.translate("welcome")
  # "¡Bienvenido a Oris!"

echo esDecoded.translate("welcome_message", ["4"])
  # "Tu instancia de Oris ya está en vivo. Tienes 4 nuevos mensajes."

echo esDecoded.translate("animals", [("dogs", 3), ("cats", 1)])
  # "3 perros y un gato"
```

### Other serialization formats
You can use `pkg/openparser/json`(with/without `pkg/openparser/bson`), `pkg/jsony`, `pkg/flatty` to encode/decode `Language` data to/from JSON, JSONY, or binary formats as well.


### Inspiration
Inspired by other i18n libraries from Nim community:
- https://github.com/moigagoo/loco
- https://github.com/heinthanth/ni18n

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/oris/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/oris/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright &copy; 2026 OpenPeeps & Contributors &mdash; All rights reserved.
