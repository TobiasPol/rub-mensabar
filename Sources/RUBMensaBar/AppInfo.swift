import Foundation

enum AppInfo {
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "RUBMensaBarVersion") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            ?? "dev"
    }

    static var userAgent: String {
        "RUBMensaBar/\(version) (+https://github.com/TobiasPol/rub-mensabar)"
    }
}
