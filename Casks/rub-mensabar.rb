cask "rub-mensabar" do
  version "0.1.0-beta.1"
  sha256 "0e75389006a860f76ddb854205773f7f2a3e0900880a03fd76f7313ae0076e10"

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
