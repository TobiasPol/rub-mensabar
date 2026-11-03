# Changelog

## Unreleased

Erstes signiertes und notarisiertes Release.

- App ist mit Developer ID signiert und von Apple notarisiert: kein
  Gatekeeper-Warnhinweis mehr beim ersten Start
- Universal Binary für Apple Silicon und Intel, optimierter Release-Build
- Releases werden automatisch per GitHub Actions gebaut, signiert,
  notarisiert und mit Build-Provenance-Attestation veröffentlicht
- Fix: Nach Mitternacht und nach dem Aufwachen aus dem Ruhezustand springt die
  App auf den aktuellen Tag und lädt den Plan neu, statt den alten Tag
  bzw. die alte Woche weiter anzuzeigen
- Fix: Automatischer Refresh wurde durch unabhängige Einstellungsänderungen
  immer wieder verschoben
- Fix: Tagesauswahl markiert immer den Tag, dessen Gerichte angezeigt werden
- Fix: Fehlgeschlagene Hintergrund-Aktualisierungen werden in der Fußzeile
  angezeigt, statt veraltete Daten stillschweigend als aktuell darzustellen
- Robustere Verarbeitung der API-Antwort bei fehlenden optionalen Feldern

## v0.1.0-beta.1

Erstes öffentliches Beta-Release.

- Wochenplan für RUB Mensa, Q-West und Rote Bete
- Mensa-Dropdown und Tagesauswahl in der Menüleiste
- manueller Refresh und konfigurierbares Refresh-Intervall
- macOS Settings für Standard-Mensa, Start at Login, Preise und Anzeigeoptionen
- Legende für AKAFÖ-Gerichtskennzeichnungen
- Homebrew Cask für Installation über einen GitHub Tap
