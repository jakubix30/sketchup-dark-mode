# SketchUp Dark Mode (Tryb Ciemny dla SketchUp 2025)

Nowoczesne, zaawansowane rozszerzenie dodające pełnoprawny **Tryb Ciemny (Dark Mode)** do programu **Trimble SketchUp 2025** na systemie Windows 10/11.

---

## 🌟 Główne Możliwości

1. **Interfejs Qt 6 w trybie ciemnym (QSS)**
   - SketchUp 2025 korzysta z biblioteki Qt 6.7 do renderowania interfejsu.
   - Wtyczka nakłada elegancki, spójny arkusz stylów Qt (`dark_theme.qss`) na paski narzędzi, menu rozwijane, menu kontekstowe, tacki boczne (**KDDockWidgets**), drzewa (Outliner/Konspekt), listy materiałów, tagów i komponentów.
2. **Ciemny pasek tytułu Windows (Immersive Dark Mode)**
   - Poprzez natywne API Windows Desktop Window Manager (`DwmSetWindowAttribute`) pasek tytułu okna SketchUp staje się ciemny, dopasowując się do nowoczesnego motywu Windows 11/10.
3. **Ciemny obszar roboczy 3D (Viewport)**
   - Tło obszaru modelowania przełącza się na ciemny grafit (`#1e1e20`).
   - Krawędzie modeli oraz linie konstrukcyjne automatycznie dostosowują swój kontrast, zachowując pełną czytelność podczas modelowania.
   - Po wyłączeniu trybu ciemnego wtyczka **przywraca dokładnie poprzednie ustawienia stylu modelu**.
4. **Pasek narzędzi i integracja z menu**
   - Dodatkowy pasek narzędzi z ikoną księżyca do szybkiego włączania/wyłączania jednym kliknięciem.
   - Wpis w menu: `Rozszerzenia (Extensions) -> Tryb ciemny (Dark Mode)`.
5. **Automatyczna synchronizacja z Windows**
   - Opcja automatycznego włączania trybu ciemnego, gdy system Windows działa w trybie ciemnym.
6. **Hot-Reload stylów CSS**
   - Możliwość edycji pliku `dark_theme.qss` i natychmiastowego odświeżenia wyglądu bez restartowania programu (`Przeładuj styl CSS`).

---

## 📁 Struktura Projektu

```
D:\Projects\sketchup-dark-mode\
├── sketchup_dark_mode.rb                   # Rejestracja rozszerzenia w SketchUp
├── sketchup_dark_mode/
│   ├── loader.rb                           # Ładowanie modułów
│   ├── main.rb                             # Główna logika, menu, pasek narzędzi, obserwator modeli
│   ├── qt_styler.rb                        # Integracja z Qt 6 przez Ruby Fiddle
│   ├── dwm_styler.rb                       # Pasek tytułu Windows (DwmSetWindowAttribute)
│   ├── viewport_styler.rb                  # Zarządzanie kolorystyką obszaru roboczego 3D
│   ├── config.rb                           # Zapis i odczyt konfiguracji (JSON)
│   ├── settings_dialog.rb                  # Okno ustawień
│   ├── styles/
│   │   └── dark_theme.qss                  # Arkusz stylów Qt 6
│   └── icons/                              # Ikony paska narzędzi (SVG + PNG)
└── README.md
```

---

## 🚀 Instalacja i Uruchomienie

Wtyczka została podłączona do katalogu wtyczek SketchUp:
`%APPDATA%\SketchUp\SketchUp 2025\SketchUp\Plugins\sketchup_dark_mode.rb`

Plik ładujący odwołuje się bezpośrednio do katalogu projektowego w `D:\Projects\sketchup-dark-mode`.

### Jak uruchomić wtyczkę:
1. **Jeśli SketchUp jest aktualnie otwarty**:
   - Możesz uruchomić wtyczkę od razu wpisując w Konsoli Ruby (`Rozszerzenia -> Konsola Ruby` lub `Extensions -> Developer -> Ruby Console`):
     ```ruby
     load 'D:/Projects/sketchup-dark-mode/sketchup_dark_mode.rb'
     ```
   - Lub zrestartować program SketchUp.
2. Po uruchomieniu pojawi się pasek narzędzi **Tryb ciemny** oraz nowa pozycja w menu **Rozszerzenia**.
