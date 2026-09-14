# Dokumentacja Techniczna i Przewodnik dla Następcy (Handover Notes)
## Projekt: SketchUp Dark Mode (SketchupDarkMode)
**Wersja:** 1.0.0  
**Główne repozytorium:** `D:\Projects\sketchup-dark-mode`  
**Katalog wtyczek SketchUp 2025:** `C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins`  
**GitHub:** [https://github.com/jakubix30/sketchup-dark-mode](https://github.com/jakubix30/sketchup-dark-mode)

---

## 1. Architektura i Zasada Działania

Wtyczka modyfikuje interfejs SketchUp 2025 (który jest 64-bitową aplikacją opartą na bibliotece **Qt 6**) na trzech niezależnych poziomach:

```
+-------------------------------------------------------------------------+
|                          SketchUp Dark Mode                             |
+-------------------+--------------------+--------------------------------+
|                   |                    |                                |
| 1. Interfejs Qt 6 | 2. Pasek DWM Win32 | 3. Widok 3D (Viewport)         |
| (qt_styler.rb +   | (dwm_styler.rb)    | (viewport_styler.rb)           |
| dark_theme.qss)   | DWMWA_USE_         | model.rendering_options        |
| Fiddle C ABI      | IMMERSIVE_DARK_    | (Background, Edges, Sky,       |
| QPalette + QSS    | MODE               | Ground)                        |
+-------------------+--------------------+--------------------------------+
```

### 1.1. Moduły wtyczki (`sketchup_dark_mode/`)
- `sketchup_dark_mode.rb` – główny plik rejestrujący rozszerzenie (`SketchupExtension.new`) w SketchUpie.
- `loader.rb` – ładuje wszystkie moduły za pomocą instrukcji `load` (co umożliwia hot-reload kodu Ruby w Konsoli).
- `config.rb` – obsługa konfiguracji JSON zapisywanej w `%APPDATA%\SketchUp\SketchUp 2025\SketchUp\sketchup_dark_mode_config.json`.
- `i18n.rb` – pełna dwujęzyczność (Polski / Angielski) z automatycznym wykrywaniem języka SketchUpa (`Sketchup.get_locale`).
- `qt_styler.rb` – najistotniejszy moduł techniczny; komunikacja z silnikiem Qt 6 przez `Fiddle`.
- `dwm_styler.rb` – ciemny pasek tytułu Windows 10/11 za pomocą Win32 API / `dwmapi.dll`.
- `viewport_styler.rb` – dostosowanie kolorystyki obszaru roboczego 3D (tło, krawędzie, wyłączenie osi/ziemi w dark mode).
- `settings_dialog.rb` – okno konfiguracji parametrów (`UI.inputbox`).
- `main.rb` – integracja paska narzędzi (ikony SVG/PNG, przełącznik stanu, menu, obserwator modeli `AppObserver`).
- `styles/dark_theme.qss` – główny arkusz stylów Qt 6.

---

## 2. Qt 6 przez Ruby Fiddle (Detale Niskopoziomowe)

SketchUp 2025 nie udostępnia oficjalnych powiązań Ruby dla biblioteki Qt 6. Komunikacja odbywa się bezpośrednio przez moduł standardowy `Fiddle` (C ABI) na procesie `sketchup.exe`.

### 2.1. Załadowane biblioteki
Pliki DLL znajdują się w katalogu instalacyjnym SketchUp (`C:\Program Files\SketchUp\SketchUp 2025\`):
- `Qt6Core.dll`
- `Qt6Gui.dll`
- `Qt6Widgets.dll`

### 2.2. Zdemanglowane symbole MSVC x64
Oto tabela symboli, które są bezpiecznie importowane w `qt_styler.rb`:

| C++ Sygnatura | Zdemanglowany symbol MSVC | Biblioteka DLL |
| :--- | :--- | :--- |
| `QCoreApplication::instance()` | `?instance@QCoreApplication@@SAPEAV1@XZ` | `Qt6Core.dll` |
| `QString::QString(const char*)` | `??0QString@@QEAA@PEBD@Z` | `Qt6Core.dll` |
| `QString::~QString()` | `??1QString@@QEAA@XZ` | `Qt6Core.dll` |
| `QApplication::setStyleSheet(const QString&)` | `?setStyleSheet@QApplication@@QEAAXAEBVQString@@@Z` | `Qt6Widgets.dll` |
| `QGuiApplication::palette()` | `?palette@QGuiApplication@@SA?AVQPalette@@XZ` | `Qt6Gui.dll` |
| `QApplication::setPalette(const QPalette&, const char*)` | `?setPalette@QApplication@@SAXAEBVQPalette@@PEBD@Z` | `Qt6Widgets.dll` |
| `QPalette::QPalette()` | `??0QPalette@@QEAA@XZ` | `Qt6Gui.dll` |
| `QPalette::~QPalette()` | `??1QPalette@@QEAA@XZ` | `Qt6Gui.dll` |
| `QPalette::setColor(ColorRole, const QColor&)` | `?setColor@QPalette@@QEAAXW4ColorRole@1@AEBVQColor@@@Z` | `Qt6Gui.dll` |
| `QColor::QColor(const char*)` | `??0QColor@@QEAA@PEBD@Z` | `Qt6Gui.dll` |
| `QApplication::activeWindow()` | `?activeWindow@QApplication@@SAPEAVQWidget@@XZ` | `Qt6Widgets.dll` |
| `QWidget::winId()` | `?winId@QWidget@@QEBA_KXZ` | `Qt6Widgets.dll` |

### 2.3. Bezpieczeństwo pamięci (Złote Zasady Fiddle)
1. **Nigdy nie iteruj wskaźnikami po obiektach potomnych w C++**: Próba trawersowania drzewa `QObject::children()` przez Fiddle w SketchUpie prowadzi do natychmiastowego `BugSplat` (crash procesu), ponieważ pamięć obiektów jest zarządzana wewnętrznie przez wątki SketchUpa.
2. **Alokacja buforów**:
   - Dla `QString` alokujemy bufor 64-bajtowy (`Fiddle::Pointer.malloc(64)`).
   - Dla `QPalette` alokujemy bufor 128-bajtowy (`Fiddle::Pointer.malloc(128)`).
3. **Destruktory w blokach `ensure`**: Każdy zaalokowany i skonstruowany obiekt C++ (`??0QString...`, `??0QPalette...`) MUSI mieć wywołany destruktor (`??1...`) w bloku `ensure`, w przeciwnym razie dochodzi do wycieków pamięci.
4. **Zapis oryginalnej palety**: Na pierwszym starcie wtyczka wywołuje `?palette@QApplication@@SA?AVQPalette@@XZ` i zapisuje 128 bajtów w zmiennej `@orig_palette_mem`. Dzięki temu powrót do trybu jasnego odtwarza paletę systemową Windows co do bita.

---

## 3. Kluczowe Problemy, Wnioski i Rozwiązania (Post-Mortem)

Podczas prac nad wtyczką napotkano kilka bardzo specyficznych problemów z layoutem SketchUpa i zachowaniem silnika Qt:

### Problem 1: Przełączanie trybów powodowało potężny lag i niemalże crash
- **Objaw:** Użytkownik zgłosił: *"jak przelaczam trby crashuje niemalze... ty glupio robisz ze jakby sa twoje dwa css niby jasny i ciemny"*.
- **Przyczyna:** W `clear_stylesheet` wcześniejszy kod wstrzykiwał alternatywny, duży arkusz CSS (`TRAY_UNLIMIT_QSS`), aby zasobnik pozostał odblokowany również w trybie jasnym. Wymiana jednego ciężkiego arkusza QSS na drugi powodowała, że Qt musiał dwukrotnie przeliczać layout całego interfejsu, co zawieszało główny wątek UI na kilka sekund.
- **Rozwiązanie:** W trybie jasnym do `setStyleSheet` przekazujemy pusty ciąg `""` (`c_ptr = Fiddle::Pointer.to_ptr("\0")`) i przywracamy `@orig_palette_mem`. W trybie jasnym **nie ma prawa działać żaden własny CSS**. Przełączanie jest natychmiastowe i bezlagowe.

### Problem 2: Rozpad paska Cienie (Shadows Toolbar)
- **Objaw:** Litery miesięcy (`S L M K M C L S W P L G`) i godziny wchodziły pod suwaki, a tekst stawał się czarny na ciemnym tle.
- **Przyczyny:**
  1. Ustawienie roli `QPalette::WindowText` (0) na czarny kolor `#000000`.
  2. Zdefiniowanie w QSS reguł `QSlider::groove:horizontal` oraz `QSlider::handle:horizontal`. W SketchUpie suwaki cieni posiadają specjalny custom painter rysujący paski gradientu pory dnia i roku. Zmiana wysokości `groove` zmniejszyła ramkę suwaka i zepchnęła litery.
- **Rozwiązanie:**
  1. `WindowText` w palecie musi pozostać jasny (`#d4d4d4`).
  2. Całkowity zakaz modyfikowania `QSlider::groove` i `QSlider::handle` w QSS.
  3. Ustawienie bezpiecznej reguły tekstowej:
     ```css
     QToolBar,
     QToolBar QLabel,
     QToolBar QSlider,
     QToolBar QSlider QLabel {
         color: #e0e0e0 !important;
     }
     ```

### Problem 3: Czcionka na kafelkach w panelu Materiały (`CMaterialListCtrl`)
- **Objaw:** Kafelki materiałów mają biały podkład pod folderami. W ciemnym motywie czcionka była niewyraźna, a w jasnym trybie użytkownik nie życzył sobie żadnych zmian.
- **Rozwiązanie:**
  - W trybie jasnym: zero modyfikacji, standardowy styl systemowy SketchUp.
  - W trybie ciemnym:
    ```css
    CMaterialListCtrl::item,
    ContentBrowserListCtrl::item,
    CBrowserListCtrl::item,
    MaterialListCtrl::item {
        color: #000000 !important;
        font-weight: bold !important;
        font-size: 8pt !important;
        background-color: transparent !important;
        border: none !important;
        padding: 0px !important;
        margin: 0px !important;
    }
    ```
    *Uwaga:* Dodanie `padding-bottom` lub `margin-bottom` kurczy ramkę kafelka i spycha tekst w dół. Ustawienie `border: none; padding: 0; margin: 0;` zapewnia pełną wysokość kafelka i czytelny czarny tekst na białym tle miniaturki.

### Problem 4: Blokada minimalnej szerokości zasobnika domyślnego
- **Objaw:** Zasobnik po prawej stronie zatrzymywał się na sztywnej minimalnej szerokości (np. 5 kolumn miniatur) i nie dawał się zwęzić bardziej.
- **Rozwiązanie:** Wiele zagnieżdżonych kontrolek w `dark_theme.qss` otrzymało `min-width: 0px !important;`. Kluczowe było objęcie nie tylko kontenerów docków, ale także kontrolek wejściowych i widżetów podglądu:
  ```css
  CDockingTray QLabel, CDockingTray QWidget,
  QDockWidget QLabel, QDockWidget QWidget,
  CMaterialBrowserPreview QLabel, CMaterialBrowserPreview QWidget,
  QLineEdit, QComboBox, QSpinBox {
      min-width: 0px !important;
  }
  ```

### Problem 5: Geometria przycisków na pasku narzędzi (Toolbars)
- **Zasada:** W regule `QToolBar` zmieniamy **wyłącznie** `background-color: #252526; border: none;`. Nie wolno dodawać stylów dla `QToolButton` (takich jak własny `padding` czy `border`), ponieważ silnik `QWindowsVistaStyle` SketchUpa przestaje wtedy natywnie skalować ikony 1:1, co rozmywa lub rozciąga przyciski.

---

## 4. GitHub: Tokeny, Credential Manager i Automatyzacja Wydań

Projekt posiada automatyzację tworzenia paczki rozszerzenia i publikacji wydań (Releases) na GitHubie.

### 4.1. Jak działa pobieranie GitHub Tokena (PAT)
W środowisku użytkownika token GitHub **nie jest** na stałe wpisany w żadnym pliku tekstowym (z powodów bezpieczeństwa). Jest bezpiecznie pobierany w locie za pomocą **Git Credential Managera (GCM)** zainstalowanego w systemie Windows:

```powershell
# Mechanizm pobierania tokena z Windows Credential Store:
$inputStr = "protocol=https`nhost=github.com`n"
$credOutput = $inputStr | git credential fill
$token = ""
foreach ($line in $credOutput) {
    if ($line -match "^password=(.+)$") {
        $token = $matches[1]
    }
}
```
Zwrócony `$token` to pełnoprawny GitHub Personal Access Token (lub OAuth token) użytkownika z uprawnieniami do zapisu w repozytorium `jakubix30/sketchup-dark-mode`.

### 4.2. Budowanie paczki `.rbz` (`build_rbz.ps1`)
Plik `.rbz` to w rzeczywistości standardowe archiwum ZIP ze zmienionym rozszerzeniem, zawierające:
1. `sketchup_dark_mode.rb` (loader główny w korzeniu ZIP-a).
2. Katalog `sketchup_dark_mode/` z wszystkimi plikami źródłowymi `.rb`, podkatalogiem `icons/` oraz `styles/dark_theme.qss`.

Uruchomienie w PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\build_rbz.ps1
```

### 4.3. Publikacja Release na GitHubie (`create_release.ps1`)
Skrypt:
1. Pobiera token przez `git credential fill`.
2. Sprawdza REST API GitHuba (`https://api.github.com/repos/jakubix30/sketchup-dark-mode/releases/tags/v1.0.0`).
3. Jeśli release już istnieje – aktualizuje opis i podmienia załącznik `sketchup_dark_mode.rbz`.
4. Jeśli nie istnieje – tworzy nowy release i wgrywa plik `.rbz`.

---

## 5. Środowisko Developerskie & Porady dla Następcy

### 5.1. Lokalizacje plików
- **Katalog źródłowy projektu:** `D:\Projects\sketchup-dark-mode`
- **Katalog wtyczek użytkownika:** `C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins`
- **Plik konfiguracyjny wtyczki:** `C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\sketchup_dark_mode_config.json`

### 5.2. Instalacja wtyczki
Aby wtyczka była w 100% poprawnie zainstalowana w SketchUpie, w katalogu `Plugins` muszą znaleźć się:
- `sketchup_dark_mode.rb`
- katalog `sketchup_dark_mode\` z całą zawartością

Najszybsza reinstalacja z poziomu PowerShell:
```powershell
tar -xf "D:\Projects\sketchup-dark-mode\sketchup_dark_mode.rbz" -C "C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins"
```

### 5.3. Hot-Reloading bez restartu programu
1. Jeśli zmieniono styl QSS w pliku `dark_theme.qss`, w SketchUpie wystarczy kliknąć przycisk **Przeładuj styl CSS** na pasku Dark Mode.
2. Jeśli zmieniono kod Ruby (np. `qt_styler.rb`), w Konsoli Ruby w SketchUpie wpisz:
   ```ruby
   load 'sketchup_dark_mode/loader.rb'
   ```
   Dzięki zastosowaniu funkcji `load` (zamiast `require`) wszystkie definicje modułów i metod zostaną natychmiast nadpisane w bieżącej sesji SketchUpa bez potrzeby ponownego uruchamiania aplikacji.

---

## 6. Ostatnio Zrealizowane Zadania & Architektura Zmian (Completed Tasks)

#### 6.1. Zrealizowane w tej iteracji:
1. **Czcionka folderów w Materiałach w Dark Mode (gruba, czarna na białej karcie z podniesieniem o 2px)**:
   - **Problem:** Etykiety tekstowe folderów w panelu Materiały wyświetlały się jako jasnoszare (#d4d4d4) na białym tle miniaturki, a próby naprawy powodowały konflikty i powielanie reguł.
   - **Rozwiązanie:** 
     - Przywrócono i uściślono architekturę kafelków swatches (commit `6c0a585`):
       ```css
       CMaterialListCtrl::item,
       ContentBrowserListCtrl::item,
       CBrowserListCtrl::item,
       MaterialListCtrl::item,
       QListView::item {
           background-color: #ffffff !important;
           color: #000000 !important;
           font-weight: 800 !important;
           font-size: 8pt !important;
           border: 1px solid #999999 !important;
           border-radius: 4px;
           padding-top: 0px !important;
           padding-left: 0px !important;
           padding-right: 0px !important;
           padding-bottom: 2px !important;
           margin: 0px !important;
       }
       ```
     - Usunięto 330 linii zdublowanego bloku `materials_list_qss` z `main.rb` oraz zduplikowany blok z końca `dark_theme.qss`.
   - **Efekt:** W ciemnym motywie czcionka na kafelku folderu jest głęboko czarna (font-weight 800), wyrazista, podniesiona o 2px i doskonale czytelna na białym tle swatches.

2. **Czysty, 100% standardowy tryb jasny (identyczny jak przy wyłączonym pluginie)**:
   - **Żądanie użytkownika:** *"chciałbym aby jasny był standardowy jakby cały plugin się wyłączał"*.
   - **Przyczyny wcześniejszych zniekształceń:**
     1. W `viewport_styler.rb` istniał blok usuwający `DrawGround` i `DrawHorizon` oraz wstawiający sztuczne tło `218, 216, 212` – blok ten został całkowicie usunięty; `restore_viewport` przywraca w 100% oryginalne niebo, ziemię i horyzont.
     2. W `qt_styler.rb` symbol `?palette@QApplication@@SA?AVQPalette@@XZ` rzucał błąd (brak takiego symbolu w `Qt6Widgets.dll`), przez co oryginalna paleta nigdy nie była zapamiętywana, a przywracano pusty `QPalette()`. Poprawiono symbol na `?palette@QGuiApplication@@SA?AVQPalette@@XZ` z `Qt6Gui.dll` oraz dodano natychmiastowy zapis natywnej palety przy starcie.
     3. W trybie jasnym do `setStyleSheet` przekazywany jest pusty ciąg `\0`, a paleta i rendering options wracają do stanu fabrycznego.
   - **Efekt:** Po wyłączeniu trybu ciemnego SketchUp wygląda w 100% identycznie jak przed instalacją wtyczki – z kompletnym widokiem 3D (ziemia/horyzont) i bez żadnych lagów czy sztucznych czcionek.

### 6.2. Procedura Wdrożeniowa:
1. Budowa paczki:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\build_rbz.ps1
   ```
2. Aktualizacja w katalogu wtyczek SketchUp:
   ```powershell
   tar -xf "D:\Projects\sketchup-dark-mode\sketchup_dark_mode.rbz" -C "C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins"
   ```
3. Commit do git i publikacja wydania GitHub Release:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\create_release.ps1
   ```
