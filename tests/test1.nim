import std/[unittest, tables]
import ../src/oris

suite "Oris Unit Tests":

  test "Basic Translation":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      welcome: "Welcome to Oris!"
      greeting_user: "Hello, $name! Welcome back."

    check i18n.translate("welcome") == "Welcome to Oris!"
    check i18n.translate("greeting_user", @["Alice"]) == "Hello, Alice! Welcome back."

  test "Pluralization":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      animals do(dogs: int, cats: int):
        result = "$dogs and $cats"
        case dogs:
          of 1: "one dog"
          else: "$dogs dogs"
        case cats:
          of 1: "one cat"
          else: "$cats cats"

    check i18n.translate("animals", [("dogs", 1), ("cats", 2)]) == "one dog and 2 cats"
    check i18n.translate("animals", [("dogs", 3), ("cats", 1)]) == "3 dogs and one cat"

  test "Multi-language Support":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      welcome: "Welcome to Oris!"

    newLanguage i18n, "es":
      welcome: "¡Bienvenido a Oris!"

    check i18n.translate("welcome") == "Welcome to Oris!"
    check i18n.translate("es", "welcome") == "¡Bienvenido a Oris!"

  test "Interpolation":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      welcome_message: "Your Oris instance is now live. You have $count new messages."

    check i18n.translate("welcome_message", @["3"]) == "Your Oris instance is now live. You have 3 new messages."

  test "Serialization and Deserialization":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      welcome: "Welcome to Oris!"
      animals do(dogs: int, cats: int):
        result = "$dogs and $cats"
        case dogs:
          of 1: "one dog"
          else: "$dogs dogs"
        case cats:
          of 1: "one cat"
          else: "$cats cats"

    # Serialize to disk
    i18n.languages["en"].encode("en_test.fbe")

    # Deserialize from disk
    var decodedLang: Language
    decodedLang.decode("en_test.fbe")

    # Verify translations
    check decodedLang.translate("welcome") == "Welcome to Oris!"
    check decodedLang.translate("animals", [("dogs", 1), ("cats", 2)]) == "one dog and 2 cats"
    check decodedLang.translate("animals", [("dogs", 3), ("cats", 1)]) == "3 dogs and one cat"

  test "Fallback for Missing Keys":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      welcome: "Welcome to Oris!"

    check i18n.translate("nonexistent_key") == "nonexistent_key"
    check i18n.translate("es", "nonexistent_key") == "nonexistent_key"

  test "Fallback for Missing Plural Rules":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      animals do(dogs: int, cats: int):
        result = "$dogs and $cats"
        case dogs:
          of 1: "one dog"
          # else: "$dogs dogs"
        case cats:
          of 1: "one cat"
          else: "$cats cats"

    # No "else" rule for dogs or cats
    check i18n.translate("animals", [("dogs", 2), ("cats", 3)]) == "$dogs and 3 cats"

  test "Edge Cases":
    var i18n = newOris(default = "en")

    newLanguage i18n, "en":
      empty: ""
      special_chars: "Hello, $name! Welcome to Oris. $$"

    check i18n.translate("empty") == ""
    check i18n.translate("special_chars", @["Alice"]) == "Hello, Alice! Welcome to Oris. $"  

# test "Runnable example":
#   var i18n = newOris(default = "en")

#   # Define English language
#   newLanguage i18n, "en":
#     welcome: "Welcome to Oris!"
#     welcome_message: "Your Oris instance is now live. You have $count new messages."
#     dashboard_title: "Dashboard"
#     dashboard_description: "This is your Oris dashboard where you can manage your projects, settings, and more."
#     greeting_user: "Hello, $name! Welcome back."
#     animals do(dogs: int, cats: int):
#       result = "$dogs and $cats"
#       case dogs:
#         of 1: "one dog"
#         else: "$dogs dogs"
#       case cats:
#         of 1: "one cat"
#         else: "$cats cats"

#   # Define Spanish language
#   newLanguage i18n, "es":
#     welcome: "¡Bienvenido a Oris!"
#     welcome_message: "Tu instancia de Oris ya está en vivo. Tienes $count nuevos mensajes."
#     dashboard_title: "Panel de Control"
#     dashboard_description: "Este es tu panel de control de Oris donde puedes administrar tus proyectos, configuraciones y más."
#     greeting_user: "¡Hola, $name! Bienvenido de nuevo."
#     animals do(dogs: int, cats: int):
#       result = "$dogs y $cats"
#       case dogs:
#         of 1: "un perro"
#         else: "$dogs perros"
#       case cats:
#         of 1: "un gato"
#         else: "$cats gatos"

#   # Showcase translations in the default language ("en")
#   echo "Default Language (English):"
#   echo i18n.translate("welcome")  # Output: "Welcome to Oris!"
#   echo i18n.translate("welcome_message", ["3"])  # Output: "Your Oris instance is now live. You have 3 new messages."
#   echo i18n.translate("greeting_user", @["Alice"])  # Output: "Hello, Alice! Welcome back."
#   echo i18n.translate("animals", [("dogs", 2), ("cats", 1)])  # Output: "2 dogs and one cat"

#   # Showcase translations in Spanish ("es")
#   echo "-------------------------------"
#   echo "\nSpanish Language:"
#   echo i18n.translate("es", "welcome")  # Output: "¡Bienvenido a Oris!"
#   echo i18n.translate("es", "welcome_message", ["5"])  # Output: "Tu instancia de Oris ya está en vivo. Tienes 5 nuevos mensajes."
#   echo i18n.translate("es", "greeting_user", @["Carlos"])  # Output: "¡Hola, Carlos! Bienvenido de nuevo."
#   echo i18n.translate("es", "animals", [("dogs", 1), ("cats", 3)])  # Output: "un perro y 3 gatos"

#   echo "-------------------------------"
#   # Encode the English language to disk using FastBinaryEncoding (FBE) format
#   echo "\nEncoding English language to disk..."
#   i18n.languages["en"].encode("en.fbe")

#   # Decode the language from disk and verify translations
#   echo "Decoding English language from disk..."
#   var enDecoded: Language
#   enDecoded.decode("en.fbe")

#   # Verify translations from the decoded language
#   echo "\nDecoded Language (English):"
#   echo enDecoded.translate("welcome")  # Output: "Welcome to Oris!"
#   echo enDecoded.translate("welcome_message", ["2"])  # Output: "Your Oris instance is now live. You have 2 new messages."
#   echo enDecoded.translate("animals", [("dogs", 1), ("cats", 2)])  # Output: "one dog and 2 cats"

#   echo "-------------------------------"
#   # Encode the Spanish language to disk
#   echo "\nEncoding Spanish language to disk..."
#   i18n.languages["es"].encode("es.fbe")

#   # Decode the Spanish language from disk and verify translations
#   echo "Decoding Spanish language from disk..."
#   var esDecoded: Language
#   esDecoded.decode("es.fbe")

#   # Verify translations from the decoded Spanish language
#   echo "\nDecoded Language (Spanish):"
#   echo esDecoded.translate("welcome")  # Output: "¡Bienvenido a Oris!"
#   echo esDecoded.translate("welcome_message", ["4"])  # Output: "Tu instancia de Oris ya está en vivo. Tienes 4 nuevos mensajes."
#   echo esDecoded.translate("animals", [("dogs", 3), ("cats", 1)])  # Output: "3 perros y un gato"
