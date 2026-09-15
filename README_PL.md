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
- 🎨 **Przełączane tło listy materiałów (Ciemne lub Jasne)**:
  Możliwość natychmiastowego przełączenia tła listy materiałów między pełną grafitową ciemnością a jasnym tłem dla próbek bezpośrednio 1 kliknięciem z menu (`Rozszerzenia -> Tryb ciemny -> Ciemna lista materiałów`) lub z okna ustawień.
  - **Tryb ciemny**: pełne grafitowe tło z ciemnymi kafelkami i białym, wyraźnym tekstem.
  - **Tryb jasny (swatch canvas)**: czyste białe tło dla wiernego odwzorowania próbek przezroczystych i gładkiego wtapiania ikon folderów.
  - Lista rozwijana kategorii (*Materiały*) oraz cała tacka boczna pozostają w ciemnym stylu z białym tekstem.
- 🪟 **Ciemny pasek tytułu Windows (Immersive Dark Titlebar)**:
  Wykorzystuje natywne Windows Desktop Window Manager API (`DwmSetWindowAttribute`, atrybuty 20/19) do automatycznego przyciemnienia paska okna głównego i okien dialogowych.
- 🧊 **Ciemne tło obszaru roboczego 3D**:
  Przełącza tło modelowania na ciemny grafit (`#1e1e20`) i automatycznie dopasowuje kontrast krawędzi modeli. Przy wyłączeniu trybu ciemnego wtyczka **przywraca oryginalne ustawienia stylu modelu**.
- 🎛️ **Minimalistyczny pasek z pojedynczym przyciskiem**:
  Zawiera pojedynczy przycisk szybkiego włączania/wyłączania jednym kliknięciem (ikona księżyca/słońca). Pełna konfiguracja i opcje są wygodnie dostępne w menu Rozszerzenia.
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

## 🚨 Rozwiązywanie Problemów i Awaryjne Wyłączanie (Crash przy Starcie)

Jeśli SketchUp wyłącza się (crashuje) w trakcie instalacji lub zapętla się przy uruchamianiu programu:

### 1. Awaryjne wyłączenie wtyczki bez uruchamiania SketchUpa
Gdy program crashuje zanim zdążysz otworzyć Menedżera rozszerzeń:
1. Otwórz okno Uruchom (`Win + R`), wklej poniższą ścieżkę i naciśnij Enter:
   ```text
   %APPDATA%\SketchUp\SketchUp 2025\SketchUp\Plugins\
   ```
   *(W razie potrzeby zmień `2025` na swoją wersję, np. `2026`).*
2. Znajdź plik **`sketchup_dark_mode.rb`** i zmień jego nazwę na **`sketchup_dark_mode.rb!`** (lub dodaj `.bak`).
   > **Jak to działa**: Mechanizm startowy SketchUpa ładuje wyłącznie pliki z rozszerzeniem `.rb`. Dodanie wykrzyknika `!` na końcu sprawia, że SketchUp całkowicie ignoruje ten plik przy starcie, co natychmiast przerywa pętlę crashy bez usuwania plików.
3. Uruchom SketchUpa normalnie.

### 2. Wyłączenie autostartu ciemnego motywu w pliku konfiguracyjnym
Jeśli chcesz zachować wtyczkę w programie, ale wyłączyć automatyczne włączanie ciemnego motywu przy starcie SketchUpa:
1. Przejdź do folderu:
   ```text
   %APPDATA%\SketchUp\SketchUp 2025\SketchUp\sketchup_dark_mode_config.json
   ```
2. Otwórz plik `sketchup_dark_mode_config.json` w Notatniku.
3. Zmień wartość `"dark_mode_enabled": true` na `"dark_mode_enabled": false`.
4. Zapisz plik i uruchom SketchUpa. Wtyczka załaduje się w trybie jasnym, bez ingerencji w pamięć Qt i DWM, dopóki sam nie klikniesz przycisku na pasku narzędzi.

### 3. Całkowite odinstalowanie
1. W folderze `Plugins` usuń plik `sketchup_dark_mode.rb` oraz katalog `sketchup_dark_mode`.
2. Opcjonalnie usuń plik `sketchup_dark_mode_config.json`.

---

### 🔍 Dlaczego mogą występować crashe?
- **Wersje przedpremierowe / testowe (np. SketchUp 2026)**:
  Wtyczka łączy się bezpośrednio z funkcjami bibliotek Qt 6 (`Qt6Core.dll`, `Qt6Gui.dll`, `Qt6Widgets.dll`) zweryfikowanymi dla SketchUpa 2024 i 2025. Przyszłe wersje lub wersje beta (np. SketchUp 2026) mogą korzystać z nowszej wersji Qt (np. Qt 6.8+), innego kompilatora MSVC lub zmienionych sygnatur C++, co przy wywołaniu przez bibliotekę Fiddle może powodować błąd dostępu do pamięci (Access Violation).
- **Konflikty z innymi wtyczkami**:
  Rozszerzenia korzystające z Chromium Embedded Framework (CEF) / `HtmlDialog` (np. V-Ray, Enscape, biblioteki modeli) lub tworzące własne natywne okna C++ mogą ulec awarii, gdy globalna funkcja `QApplication::setStyleSheet` lub DWM odświeża okna w trakcie inicjalizacji ich podprocesów.
- **Wyścig podczas ładowania (Race Condition)**:
  Autostart ciemnego motywu tuż po instalacji lub w ułamku sekundy po starcie SketchUpa (gdy inne pluginy i ekran powitalny wciąż się ładują) może wywołać konflikt w silniku renderowania Qt.

---

## 🛠️ Architektura Techniczna

SketchUp 2024 i 2025 przeszły z dawnego MFC na nowoczesną bibliotekę **Qt 6**. Wtyczka integruje się z aplikacją na trzech poziomach:

1. **Ruby Fiddle (`qt_styler.rb`)**:
   Łączy się bezpośrednio z załadowanymi bibliotekami `Qt6Widgets.dll` oraz `Qt6Gui.dll` w pamięci procesu, wywołując oficjalne eksporty Qt: `QApplication::setStyle`, `QApplication::setPalette` oraz `QApplication::setStyleSheet`.
2. **Windows Desktop Window Manager (`dwm_styler.rb`)**:
   Wywołuje funkcję systemową `DwmSetWindowAttribute` z biblioteki `dwmapi.dll` w celu aktywacji ciemnej ramki okna Windows 11/10.
3. **Ruby API Viewport (`viewport_styler.rb`)**:
   Modyfikuje `rendering_options` modelu 3D z zachowaniem poprzednich wartości, zapewniając bezstratne przywrócenie jasnego stylu po wyłączeniu wtyczki.

## 🎨 Dokumentacja i Poradnik QSS

Kompletny podręcznik architektury Qt 6 w SketchUp 2024 / 2025, katalog selektorów, rozwiązań kluczowych problemów (Toolbar inflation bug, min-width zasobnika, dymki QToolTip, ikony SVG) oraz tworzenia własnych motywów:
- 📖 [Kompletny Poradnik i Ściągawka QSS (Polski)](QSS_DOCS_PL.md)
- 📖 [Complete QSS Guide & Selector Reference (English)](QSS_DOCS.md)

---

## 📦 Budowanie paczki `.rbz`

Aby samodzielnie zbudować plik dystrybucyjny `.rbz`:
Uruchom dołączony skrypt PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\build_rbz.ps1
```
Skrypt automatycznie spakuje wszystkie pliki źródłowe, ikony oraz style do gotowego archiwum `sketchup_dark_mode.rbz`.

---

## 🔍 Znane Ograniczenia i Plany na Przyszłość (Roadmap)

Chociaż wtyczka zapewnia spójny i dopracowany ciemny motyw, pewne wewnętrzne mechanizmy silnika SketchUpa stanowią znane wyzwania techniczne:

1. **Ikony i etykiety folderów w panelu Materiały (Wkompilowane białe tło renderowania)**:
   - W zasobniku Materiałów miniatury folderów kategorii posiadają białe tło wyrenderowane bezpośrednio na powierzchni bitmapy przez wewnętrzną procedurę C++ SketchUpa (`CMaterialBrowserPage` / `CMaterialBrowserPreview`).
   - Ponieważ jest to bezpośrednio rysowany kafelek (owner-draw bitmap), a nie standardowy widget Qt, reguły CSS `background-color` czy zmiany marginesów `padding` nie są w stanie usunąć tego białego fragmentu ani przesunąć tekstu bez zniekształcania miniatur.
   - *Plany*: Badanie możliwości przechwycenia bitmapy w pamięci lub podmiany renderera kafelków w przyszłych wersjach.

2. **Minimalna szerokość zasobnika po przełączeniu z trybu ciemnego na jasny**:
   - Po powrocie z trybu ciemnego na jasny w trakcie tej samej sesji minimalna szerokość zasobnika bocznego (`min-width`) może pozostać nieznacznie większa niż fabryczna, dopóki SketchUp nie zostanie uruchomiony ponownie.
   - *Przyczyna*: Silnik Qt 6 (`QStyleSheetStyle`) oblicza i keszuje ograniczenia `minimumSizeHint()` dla złożonych kontenerów (`CDockingTray`, `CPanelContentSplitter`). Nawet po wyczyszczeniu arkusza stylów (`setStyleSheet("")`), wewnętrzny kesz układu Qt pamięta wyliczoną minimalną szerokość.
   - *Rozwiązanie*: Ponowne uruchomienie SketchUpa natychmiast przywraca oryginalne, fabryczne wymiary zasobnika.

---

## ⚠️ Oświadczenie Prawne i Zastrzeżenia (Disclaimer)

- **Niezależny projekt społecznościowy**: Niniejsze rozszerzenie jest niezależnym projektem open-source o charakterze badawczo-edukacyjnym (interoperability research). Nie jest w żaden sposób powiązane, autoryzowane, certyfikowane ani wspierane przez firmę Trimble Inc.
- **Znaki towarowe**: Nazwy „SketchUp” oraz „Trimble” są zastrzeżonymi znakami towarowymi firmy Trimble Inc. i zostały użyte wyłącznie w celach informacyjnych, aby wskazać kompatybilność oprogramowania.
- **Brak modyfikacji plików na dysku**: Wtyczka nie modyfikuje, nie patchuje ani nie narusza plików wykonywalnych (`SketchUp.exe`) ani bibliotek DLL na dysku komputera. Wszystkie style są nakładane dynamicznie w pamięci RAM w trakcie działania programu.
- **Brak gwarancji**: Oprogramowanie jest udostępniane na licencji MIT „takie, jakie jest” (AS IS), bez jakichkolwiek gwarancji. Użytkownik instaluje i korzysta z rozszerzenia na własną odpowiedzialność.

---

## 📄 Licencja

Projekt udostępniany jest na warunkach otwartoźródłowej licencji **MIT**. Szczegóły w pliku [LICENSE](LICENSE).
