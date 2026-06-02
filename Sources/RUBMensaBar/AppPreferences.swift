import Foundation
import RUBMensaBarCore

enum AppPreferenceKeys {
    static let defaultCanteenID = "defaultCanteenID"
    static let refreshIntervalMinutes = "refreshIntervalMinutes"
    static let priceDisplayMode = "priceDisplayMode"
    static let showMealTags = "showMealTags"
    static let showSourceLink = "showSourceLink"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            defaultCanteenID: MensaCanteen.rubMensa.id,
            refreshIntervalMinutes: RefreshInterval.hourly.rawValue,
            priceDisplayMode: PriceDisplayMode.studentAndEmployee.rawValue,
            showMealTags: true,
            showSourceLink: true
        ])
    }
}

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case manual = 0
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case hourly = 60
    case twoHours = 120
    case fourHours = 240

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .manual:
            return "Manuell"
        case .fifteenMinutes:
            return "Alle 15 Minuten"
        case .thirtyMinutes:
            return "Alle 30 Minuten"
        case .hourly:
            return "Stündlich"
        case .twoHours:
            return "Alle 2 Stunden"
        case .fourHours:
            return "Alle 4 Stunden"
        }
    }

    var seconds: TimeInterval? {
        guard rawValue > 0 else { return nil }
        return TimeInterval(rawValue * 60)
    }

    static func normalized(_ rawValue: Int) -> RefreshInterval {
        RefreshInterval(rawValue: rawValue) ?? .hourly
    }
}

enum PriceDisplayMode: String, CaseIterable, Identifiable {
    case hidden
    case student
    case studentAndEmployee
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hidden:
            return "Keine Preise"
        case .student:
            return "Studierende"
        case .studentAndEmployee:
            return "Studierende + Mitarbeitende"
        case .all:
            return "Alle Preise"
        }
    }

    static func normalized(_ rawValue: String?) -> PriceDisplayMode {
        rawValue.flatMap(PriceDisplayMode.init(rawValue:)) ?? .studentAndEmployee
    }
}
