<p align="center">
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
```

### ❤ Contributions & Support
- 🐛 Found a bug? [Create a new Issue](https://github.com/openpeeps/oris/issues)
- 👋 Wanna help? [Fork it!](https://github.com/openpeeps/oris/fork)
- 😎 [Get €20 in cloud credits from Hetzner](https://hetzner.cloud/?ref=Hm0mYGM9NxZ4)

### 🎩 License
MIT license. [Made by Humans from OpenPeeps](https://github.com/openpeeps).<br>
Copyright &copy; 2026 OpenPeeps & Contributors &mdash; All rights reserved.
