# RUB MensaBar

RUB MensaBar ist eine macOS Menu-Bar-App für den Wochenplan der RUB-Mensen.
Die App zeigt aktuell die Speisepläne für:

- RUB Mensa
- Q-West
- Rote Bete

Status: **Beta**. Die App ist noch nicht notarisiert und kann sich während der
Beta ändern.

## Features

- Speiseplan der aktuellen Woche direkt in der macOS-Menüleiste
- Dropdown für RUB Mensa, Q-West und Rote Bete
- Refresh-Button und optionaler automatischer Refresh
- macOS Settings mit Standard-Mensa, Start at Login, Refresh-Intervall,
  Preisanzeige und Anzeigeoptionen
- Legende für die AKAFÖ-Gerichtskennzeichnungen wie vegan, vegetarisch,
  Geflügel, Rind oder Halal

## Installation mit Homebrew

Sobald das Beta-Release im GitHub-Repo vorhanden ist, kann die App über den
Tap installiert werden:

```bash
brew tap TobiasPol/rub-mensabar https://github.com/TobiasPol/rub-mensabar
brew install --cask rub-mensabar
open -a RUBMensaBar
```

Nach dem Start erscheint ein kleines Besteck-Icon in der macOS-Menüleiste.
Falls das Icon nicht direkt sichtbar ist, prüfe Menüleisten-Manager wie Ice,
Bartender oder Hidden Bar.

Updates:

```bash
brew update
brew upgrade --cask rub-mensabar
```

Deinstallation:

```bash
brew uninstall --cask rub-mensabar
brew untap TobiasPol/rub-mensabar
```

## Manuelle Installation auf einem MacBook

1. Öffne die [GitHub Releases](https://github.com/TobiasPol/rub-mensabar/releases).
2. Lade das aktuelle Beta-Zip herunter, zum Beispiel
   `RUBMensaBar-v0.1.0-beta.1.zip`.
3. Entpacke die Datei.
4. Ziehe `RUBMensaBar.app` in den Programme-Ordner.
5. Starte die App über Finder oder Spotlight.

Da die Beta aktuell ad-hoc signiert und nicht notarisiert ist, kann macOS beim
ersten Start eine Sicherheitsmeldung anzeigen. Öffne die App dann per Rechtsklick
auf `RUBMensaBar.app` und wähle `Öffnen`, oder erlaube den Start in
`Systemeinstellungen -> Datenschutz & Sicherheit`.

## Nutzung

Nach dem Start läuft RUB MensaBar ohne Dock-Icon in der Menüleiste:

1. Klicke auf das Besteck-Icon in der Menüleiste.
2. Wähle oben im Dropdown die gewünschte Mensa.
3. Wähle den Tag über die Segmentauswahl.
4. Nutze den Refresh-Button, um den Plan sofort neu zu laden.
5. Öffne die Einstellungen über das Zahnrad.

In den Einstellungen kannst du die Standard-Mensa, das Refresh-Intervall, die
Preisanzeige, die Kennzeichnungen und den Quellenlink ändern. `Start at Login`
ist in lokalen Entwicklungs-Builds eventuell deaktiviert; in einem installierten
App-Bundle wird der Status über macOS `SMAppService` verwaltet.

## Datenquelle

Die AKAFÖ-Webseite lädt die Speiseplandaten als JSON aus der StudyLife API. Die
App nutzt:

```text
https://akafoe.studylife.org/api/meal-plans/week/current?canteen_id=<canteen-id>
```

Verwendete IDs:

- RUB Mensa: `a0f40678-5e86-4ae4-9ff1-ae1e9e25934b`
- Q-West: `a0f40678-ac6b-4b31-a37b-7f0e4b5eb188`
- Rote Bete: `a0f4067a-78d2-42c2-a3de-1006cf571dea`

Die App speichert nur lokale Einstellungen über `UserDefaults` und sendet keine
Telemetrie.

## Entwicklung

Voraussetzungen:

- macOS 13 oder neuer
- Xcode Command Line Tools
- Swift 5.9 oder neuer

Tests:

```bash
env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache \
  swift test --disable-sandbox --cache-path .build/swiftpm-cache
```

Lokaler Start:

```bash
./script/build_and_run.sh
```

Beta-Paket bauen:

```bash
./script/package_release.sh 0.1.0-beta.1
```

Das erzeugt `dist/RUBMensaBar-v0.1.0-beta.1.zip` und gibt den SHA256-Hash für
die Homebrew-Cask-Datei aus.

## Releases

Release-Tags verwenden das Format `v<version>`, zum Beispiel:

```text
v0.1.0-beta.1
```

Jedes GitHub Release sollte enthalten:

- `RUBMensaBar-v<version>.zip`
- kurze Release Notes
- Hinweis, dass es sich aktuell um eine Beta handelt

## Lizenz

Noch keine Open-Source-Lizenz festgelegt.
