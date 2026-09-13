# SketchUp Dark Mode (Tryb Ciemny dla SketchUp)

[![SketchUp](https://img.shields.io/badge/SketchUp-2024%20%7C%202025-blue.svg)](https://www.sketchup.com/)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20(x64)-0078D6.svg)](https://microsoft.com/windows)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Language](https://img.shields.io/badge/J%C4%99zyk-Ruby%20%7C%20Qt%206%20QSS-red.svg)](https://www.ruby-lang.org/)

[**English version (Wersja angielska)**](README.md)

Nowoczesne, zaawansowane rozszerzenie dodające pełny, profesjonalny **Tryb Ciemny (Dark Mode)** do programu **Trimble SketchUp 2025 oraz 2024** na systemach Windows 10 i Windows 11 (64-bit).

Wtyczka stylizuje **interfejs Qt 6**, **pasek tytułu Windows (DWM)** oraz **obszar roboczy modelowania 3D**, zachowując w 100% natywne proporcje pasków narzędzi (brak uciętych ikon) i pełną czytelność miniatur materiałów architektonicznych.

![Podgląd SketchUp Dark Mode](docs/screenshot.png)

---

## ✨ Główne Funkcje

- 🌙 **Ciemny motyw interfejsu Qt 6 (QSS + QPalette)**:
  Spójny ciemny styl obejmujący paski narzędzi, menu rozwijane, menu kontekstowe, tacki boczne (**KDDockWidgets**), Konspekt (Outliner), Tagi, Komponenty, Informacje o elemencie i pasek stanu.
- 📐 **Natywna skala pasków narzędzi 1:1 (Brak problemów z UI scale)**:
  Specjalnie zoptymalizowany pod kątem błędu Qt 6 `QStyleSheetStyle`. Przyciski narzędzi zachowują natywne wymiary Windows Vista (24x24 px), dzięki czemu wszystkie ikony narzędzi (zarówno na górnym pasku, jak i po lewej stronie) mieszczą się na ekranie bez żadnego ucinania.
- 🎨 **Przeglądarka materiałów (Swatch Canvas)**:
  W programie SketchUp ikony folderów oraz miniatury próbek materiałów są renderowane przez wewnętrzny silnik C++ bezpośrednio do rastrowej bitmapy na na stałe zakodowanym białym tle (`Qt::white`).
  Nasza wtyczka renderuje kontener listy materiałów jako czysty, biały próbnik (swatch canvas) z mocno pogrubionym, ciemnym tekstem (`#111111`):
  - **100% wierności kolorystycznej**: Próbki kolorów, drewna, kamienia, metalu oraz materiałów przezroczystych (szkło, woda) prezentują się na naturalnym, neutralnym tle.
  - **Brak artefaktów i ucięć**: Miniatury folderów i próbek wtapiają się gładko w tło, a etykiety tekstowe (np. *Podłoże*, *Drewno*, *Asfalt*) znajdują się w całości na białym tle i nie są w połowie ucięte ciemnym tłem.
  - **Ciemny panel sterujący**: Lista rozwijana kategorii (*Materiały*) oraz cała otaczająca tacka pozostają w eleganckim, ciemnym stylu z białym tekstem.
- 🪟 **Ciemny pasek tytułu Windows (Immersive Dark Titlebar)**:
  Wykorzystuje natywne Windows Desktop Window Manager API (`DwmSetWindowAttribute`, atrybuty 20/19) do automatycznego przyciemnienia paska okna głównego i okien dialogowych.
- 🧊 **Ciemne tło obszaru roboczego 3D**:
  Przełącza tło modelowania na ciemny grafit (`#1e1e20`) i automatycznie dopasowuje kontrast krawędzi modeli. Przy wyłączeniu trybu ciemnego wtyczka **przywraca oryginalne ustawienia stylu modelu**.
- 🎛️ **Schludny pasek narzędzi z 2 przyciskami**:
  Zawiera przycisk z ikoną księżyca do włączania/wyłączania jednym kliknięciem oraz przycisk ustawień.
- ⚙️ **Panel Ustawień**:
  Możliwość niezależnego włączania stylizowania UI, paska tytułu, tła 3D oraz automatycznej synchronizacji z motywem Windows.
- ⚡ **Hot-Reload stylów CSS**:
  Możliwość edycji pliku `dark_theme.qss` i natychmiastowego odświeżenia wyglądu bez restartowania SketchUp (`Rozszerzenia -> Tryb ciemny -> Przeładuj styl CSS`).

---

## 📥 Instalacja

### Metoda 1: Gotowy instalator `.rbz` (Zalecana)

1. Pobierz plik [`sketchup_dark_mode.rbz`](sketchup_dark_mode.rbz) z repozytorium (lub zakładki Releases).
2. Otwórz program **SketchUp 2025** (lub 2024).
3. Wybierz z menu górnego: **Rozszerzenia** -> **Menedżer rozszerzeń** (*Extensions* -> *Extension Manager*).
4. Kliknij przycisk **Zainstaluj rozszerzenie** (*Install Extension*) w lewym dolnym rogu.
5. Wskaż pobrany plik `sketchup_dark_mode.rbz`.
6. Pasek narzędzi **Tryb ciemny** pojawi się natychmiast! Kliknij ikonę księżyca, aby włączyć motyw.

### Metoda 2: Instalacja deweloperska (Git Clone)

1. Sklonuj repozytorium do wybranego folderu:
   ```bash
   git clone https://github.com/twoja-nazwa/sketchup-dark-mode.git D:\Projects\sketchup-dark-mode
   ```
2. Utwórz plik ładujący w folderze wtyczek SketchUp:
   `%APPDATA%\SketchUp\SketchUp 2025\SketchUp\Plugins\sketchup_dark_mode.rb`
   O zawartości:
   ```ruby
   load 'D:/Projects/sketchup-dark-mode/sketchup_dark_mode.rb'
   ```
3. Zrestartuj SketchUp lub wpisz w Konsoli Ruby:
   ```ruby
   load 'D:/Projects/sketchup-dark-mode/sketchup_dark_mode/loader.rb'
   ```

---

## 🛠️ Architektura Techniczna

SketchUp 2024 i 2025 przeszły z dawnego MFC na nowoczesną bibliotekę **Qt 6**. Wtyczka integruje się z aplikacją na trzech poziomach:

1. **Ruby Fiddle (`qt_styler.rb`)**:
   Łączy się bezpośrednio z załadowanymi bibliotekami `Qt6Widgets.dll` oraz `Qt6Gui.dll` w pamięci procesu, wywołując oficjalne eksporty Qt: `QApplication::setStyle`, `QApplication::setPalette` oraz `QApplication::setStyleSheet`.
2. **Windows Desktop Window Manager (`dwm_styler.rb`)**:
   Wywołuje funkcję systemową `DwmSetWindowAttribute` z biblioteki `dwmapi.dll` w celu aktywacji ciemnej ramki okna Windows 11/10.
3. **Ruby API Viewport (`viewport_styler.rb`)**:
   Modyfikuje `rendering_options` modelu 3D z zachowaniem poprzednich wartości, zapewniając bezstratne przywrócenie jasnego stylu po wyłączeniu wtyczki.

---

## 📦 Budowanie paczki `.rbz`

Aby samodzielnie zbudować plik dystrybucyjny `.rbz`:
Uruchom dołączony skrypt PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\build_rbz.ps1
```
Skrypt automatycznie spakuje wszystkie pliki źródłowe, ikony oraz style do gotowego archiwum `sketchup_dark_mode.rbz`.

---

## ⚖️ Zgodność z Regulaminem Trimble (TOS Compliance)

- **Zgodność z Trimble Developer Agreement**: Wtyczka w 100% spełnia wymogi regulaminu Trimble SketchUp dla rozszerzeń Ruby API.
- **Brak redystrybucji kodu własnościowego**: Wtyczka nie zawiera żadnych zastrzeżonych plików binarnych (.dll, .exe) Trimble ani Qt — korzysta wyłącznie z bibliotek zainstalowanych na komputerze użytkownika.
- **Brak ingerencji w licencjonowanie**: Rozszerzenie modyfikuje wyłącznie warstwę wizualną interfejsu (CSS i tło). Nie modyfikuje plików wykonywalnych SketchUp i nie omija mechanizmów DRM ani licencji.

---

## 📄 Licencja

Projekt udostępniany jest na warunkach otwartoźródłowej licencji **MIT**. Szczegóły w pliku [LICENSE](LICENSE).
