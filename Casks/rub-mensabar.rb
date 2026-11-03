cask "rub-mensabar" do
  version "0.2.0"
  sha256 "8ab9d529e3ebe3ab6b2914da4226470c39b11709905ce72be05cc713902a4e9d"

  url "https://github.com/TobiasPol/rub-mensabar/releases/download/v#{version}/RUBMensaBar-v#{version}.zip"
  name "RUB MensaBar"
  desc "macOS menu bar app for RUB canteen meal plans"
  homepage "https://github.com/TobiasPol/rub-mensabar"

  depends_on macos: ">= :ventura"

  app "RUBMensaBar.app"

  zap trash: [
    "~/Library/Preferences/de.tobiaspolley.RUBMensaBar.plist",
  ]
end
