# Releases

Releases werden vollständig von GitHub Actions gebaut: Ein Tag `v<version>`
startet [`.github/workflows/release.yml`](../.github/workflows/release.yml).
Der Workflow

1. prüft, dass der Tag eine SemVer-Version ist und auf einen Commit in `main` zeigt,
2. liest die Release Notes aus `CHANGELOG.md` (fehlt der Abschnitt, bricht er ab),
3. führt die Tests aus,
4. baut ein Universal-Binary (Apple Silicon + Intel) im Release-Modus,
5. signiert mit dem **Developer ID Application**-Zertifikat (Hardened Runtime + Timestamp),
6. notarisiert über den Apple Notary Service und heftet das Ticket an (`stapler`),
7. prüft das Ergebnis mit Gatekeeper (`spctl`),
8. erzeugt eine Build-Provenance-Attestation für das Zip,
9. veröffentlicht das GitHub Release (Versionen mit `-beta.N` usw. als Pre-Release),
10. öffnet einen PR, der `Casks/rub-mensabar.rb` auf die neue Version und den neuen SHA256 setzt.

## Einmalige Einrichtung

### 1. GitHub-Environment `release`

```bash
gh api -X PUT repos/TobiasPol/rub-mensabar/environments/release
```

Empfohlen in *Settings → Environments → release*:

- **Deployment branches and tags**: nur Tags `v*`
- optional **Required reviewers**, damit jedes Release einmal bestätigt wird

Unter *Settings → Actions → General* muss
**"Allow GitHub Actions to create and approve pull requests"** aktiv sein,
sonst kann der Workflow den Cask-PR nicht öffnen.

### 2. Developer-ID-Zertifikat

1. In der Schlüsselbundverwaltung das Zertifikat
   `Developer ID Application: Tobias Polley (CQ42H4H5MA)` **inklusive privatem
   Schlüssel** als `.p12` exportieren und ein starkes Passwort vergeben.
2. Als Secrets hinterlegen und die Datei danach löschen:

```bash
base64 -i DeveloperID.p12 | gh secret set DEVELOPER_ID_P12_BASE64 --env release
gh secret set DEVELOPER_ID_P12_PASSWORD --env release
rm -P DeveloperID.p12
```

### 3. App Store Connect API-Key für die Notarisierung

1. [App Store Connect → Benutzer und Zugriff → Integrationen → Team-Schlüssel](https://appstoreconnect.apple.com/access/integrations/api)
   einen Schlüssel mit der Rolle **Developer** anlegen und die `.p8` laden
   (geht nur einmal).
2. Als Secrets hinterlegen:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | gh secret set NOTARY_API_KEY_P8_BASE64 --env release
gh secret set NOTARY_API_KEY_ID --env release      # z. B. XXXXXXXXXX
gh secret set NOTARY_API_ISSUER_ID --env release   # UUID oben auf der Seite
```

Die `.p8` sicher (z. B. im Passwortmanager) ablegen und nicht ins Repo kopieren;
`.gitignore` blockiert `*.p8` und `*.p12` zusätzlich.

## Ein Release veröffentlichen

1. In `CHANGELOG.md` den Abschnitt `## Unreleased` in `## v<version>` umbenennen
   (z. B. `## v0.2.0`) und per PR nach `main` mergen.
2. Tag setzen und pushen:

```bash
git switch main && git pull
git tag -a v0.2.0 -m "RUB MensaBar v0.2.0"
git push origin v0.2.0
```

3. Den Lauf unter *Actions → Release* verfolgen (Notarisierung dauert meist
   wenige Minuten).
4. Den automatisch geöffneten PR `chore(cask): update rub-mensabar to v0.2.0`
   mergen – erst danach sehen Homebrew-Nutzer das Update.

Schlägt ein Release fehl, den Fehler beheben, Tag löschen und neu setzen:

```bash
git push --delete origin v0.2.0 && git tag -d v0.2.0
```

## Versionierung

- [SemVer](https://semver.org/lang/de/): `MAJOR.MINOR.PATCH`, Vorabversionen
  mit Suffix (`0.2.0-beta.1`).
- `CFBundleShortVersionString` ist der numerische Teil (`0.2.0`),
  die vollständige Version steht zusätzlich in `RUBMensaBarVersion`.
- `CFBundleVersion` ist die Anzahl der Commits auf dem Release-Commit und
  steigt dadurch monoton.

## Lokal signieren und notarisieren

Ohne weitere Konfiguration signiert `./script/package_release.sh <version>` mit
der ersten `Developer ID Application`-Identität im Schlüsselbund und überspringt
die Notarisierung. Für eine vollständig notarisierte lokale Build einmalig ein
Notary-Profil speichern:

```bash
xcrun notarytool store-credentials rub-mensabar-notary \
  --key AuthKey_XXXXXXXXXX.p8 --key-id XXXXXXXXXX --issuer <issuer-uuid>
```

Danach:

```bash
NOTARY_KEYCHAIN_PROFILE=rub-mensabar-notary REQUIRE_NOTARIZATION=1 \
  ./script/package_release.sh 0.2.0
```

Alle Optionen stehen im Kopf von [`script/package_release.sh`](../script/package_release.sh).
