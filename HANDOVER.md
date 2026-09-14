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
| `QApplication::palette()` | `?palette@QApplication@@SA?AVQPalette@@XZ` | `Qt6Widgets.dll` |
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

## 6. Otwarte Zadania & Gotowy Prompt dla Następcy (Pending Tasks)

### 6.1. Zgłoszone problemy do rozwiązania:
1. **Czcionka folderów w Materiałach w Dark Mode (jest jasnoszara, a ma być gruba, czarna i lekko wyżej)**:
   - W ciemnym trybie tekst etykiet na białych kafelkach folderów w panelu Materiały (`MaterialsBrowser`) nadal renderuje się jako jasnoszary (`#d4d4d4`).
   - **Przyczyna:** Ogólne reguły `QListView::item { color: #d4d4d4 !important; }` oraz `MaterialsBrowser * { color: #d4d4d4; }` w `dark_theme.qss` nadpisują styl, jeśli nazwa klasy widoku to `QListView` wewnątrz `MaterialsBrowser`.
   - **Wymaganie:** W trybie ciemnym czcionka ma być mocno pogrubiona, czarna (`#000000 !important; font-weight: 800 !important;`) i przesunięta lekko w górę (`padding-bottom: 2px !important;`), aby leżała idealnie na białym tle kafelka. W trybie jasnym czcionka ma pozostać w 100% fabryczna (nienaruszona).

2. **Zmniejszanie zasobnika w trybie jasnym (odblokowanie min-width bez lagów i crashy)**:
   - W trybie ciemnym zmniejszanie zasobnika działa znakomicie (dzięki `min-width: 0px !important`).
   - W trybie jasnym użytkownik również chce móc zsuwać zasobnik, ale wcześniejsza próba z `TRAY_UNLIMIT_QSS` zawieszała program przy przełączaniu trybów, ponieważ selektory uniwersalne `*` wymuszały rekursywne przeliczanie stylów dla wszystkich kontrolek w aplikacji.
   - **Zadanie:** Zaprojektować ultra-lekki, wąski mechanizm odblokowania minimalnej szerokości w trybie jasnym (np. celowany QSS bez gwiazdek `*`, obejmujący wyłącznie główne kontenery docków) z zerowym wpływem na wydajność.

### 6.2. Gotowy Prompt do skopiowania do nowej sesji:
```text
Cześć! Pracujemy nad wtyczką SketchUp Dark Mode dla SketchUp 2025 (repozytorium D:\Projects\sketchup-dark-mode).
Zapoznaj się koniecznie z plikiem HANDOVER.md w repozytorium – opisuje on całą architekturę Fiddle Qt6, bezpieczeństwo pamięci, GitHub token oraz post-mortem poprzednich błędów.

Mamy obecnie do rozwiązania 2 konkretne zadania:
1. CZCIONKA FOLDERÓW W MATERIAŁACH:
   - W trybie ciemnym czcionka etykiet folderów w panelu Materiały (MaterialsBrowser / CMaterialListCtrl) jest obecnie jasnoszara, a musi być GRUBA CZARNA (color: #000000 !important, font-weight: bold / 800) i znajdować się LEKKO WYŻEJ na białym tle kafelka.
   - Sprawdź dlaczego w dark_theme.qss ogólna reguła QListView::item (lub MaterialsBrowser *) nadpisuje kafelki materiałów i podnieś specyficzność selektora dla widoku kafelków materiałów.
   - W trybie jasnym czcionka ma pozostać całkowicie standardowa/nienaruszona (fabryczny styl SketchUpa).

2. ROZMIAR ZASOBNIKA W TRYBIE JASNYM:
   - W trybie ciemnym zmniejszanie zasobnika do minimum działa już świetnie.
   - W trybie jasnym zasobnik ma standardowy sztywny limit szerokości SketchUpa. Chcemy, aby w trybie jasnym również dało się go maksymalnie zmniejszyć.
   - UWAGA: Poprzednia próba wstrzykiwania TRAY_UNLIMIT_QSS crashowała i lagowała aplikację podczas przełączania, ponieważ użyto uniwersalnych selektorów '*' (np. CDockingTray *, QSplitter *), co powodowało potężny reflow Qt.
   - Zaimplementuj ultra-lekki styl dla trybu jasnego bez selektorów '*', celujący wyłącznie w ramki docków (QDockWidget, CDockingTray, KDDockWidgets--DockWidget), tak aby zasobnik dał się zmniejszać, a przełączanie trybów było błyskawiczne i bez najmniejszego zacięcia.

Po naniesieniu poprawek:
- Przebuduj .rbz (build_rbz.ps1)
- Zaktualizuj zainstalowaną wtyczkę w C:\Users\jakub\AppData\Roaming\SketchUp\SketchUp 2025\SketchUp\Plugins
- Zacommituj zmiany i zaktualizuj release na GitHubie (create_release.ps1)
```
