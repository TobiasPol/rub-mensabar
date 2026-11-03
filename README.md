# RUB MensaBar

RUB MensaBar ist eine macOS Menu-Bar-App für den Wochenplan der RUB-Mensen.
Die App zeigt aktuell die Speisepläne für:

- RUB Mensa
- Q-West
- Rote Bete

Die App ist mit einer Apple Developer ID signiert und von Apple notarisiert.
Sie läuft als Universal Binary auf Apple Silicon und Intel-Macs.

## Features

- Speiseplan der aktuellen Woche direkt in der macOS-Menüleiste
- Dropdown für RUB Mensa, Q-West und Rote Bete
- Refresh-Button und optionaler automatischer Refresh
- macOS Settings mit Standard-Mensa, Start at Login, Refresh-Intervall,
  Preisanzeige und Anzeigeoptionen
- Legende für die AKAFÖ-Gerichtskennzeichnungen wie vegan, vegetarisch,
  Geflügel, Rind oder Halal

## Installation mit Homebrew

Die App kann über den Tap installiert werden:

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
2. Lade das aktuelle Zip herunter, zum Beispiel `RUBMensaBar-v0.2.0.zip`.
3. Entpacke die Datei.
4. Ziehe `RUBMensaBar.app` in den Programme-Ordner.
5. Starte die App über Finder oder Spotlight.

Releases ab v0.2.0 sind notarisiert und starten ohne Gatekeeper-Warnung.
Für ältere Beta-Builds (ad-hoc signiert) öffne die App per Rechtsklick auf
`RUBMensaBar.app` → `Öffnen`.

Die Echtheit eines Downloads lässt sich prüfen mit:

```bash
shasum -a 256 -c RUBMensaBar-v0.2.0.zip.sha256
gh attestation verify RUBMensaBar-v0.2.0.zip --repo TobiasPol/rub-mensabar
spctl --assess --type execute --verbose /Applications/RUBMensaBar.app
```

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

Release-Paket lokal bauen (signiert automatisch mit der Developer ID aus dem
Schlüsselbund, sofern vorhanden):

```bash
./script/package_release.sh 0.2.0
```

Das erzeugt `dist/RUBMensaBar-v0.2.0.zip` samt `.sha256`-Datei.

Jeder Push und Pull Request läuft durch die CI
([`.github/workflows/ci.yml`](.github/workflows/ci.yml)): Tests, Shell-Checks
und ein ad-hoc signiertes Test-Paket als Build-Artefakt.

## Releases

Releases entstehen automatisch, wenn ein Tag `v<version>` gepusht wird: GitHub
Actions baut, signiert, notarisiert und veröffentlicht die App und öffnet einen
PR für das Homebrew-Cask. Einrichtung und Ablauf stehen in
[`docs/RELEASING.md`](docs/RELEASING.md).

## Lizenz

Noch keine Open-Source-Lizenz festgelegt.
