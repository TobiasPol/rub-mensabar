import Foundation
import RUBMensaBarCore

// Presentation strings for the menu: dates, week header and prices.
extension MenuViewModel {
    var weekTitle: String {
        guard let plan else { return "Aktueller Wochenplan" }

        return "KW \(plan.weekNumber) · \(Self.shortDateFormatter.string(from: plan.startDate))-\(Self.shortDateFormatter.string(from: plan.endDate))"
    }

    var lastUpdatedText: String {
        guard let plan else { return "Noch nicht aktualisiert" }

        return "Aktualisiert \(Self.timeFormatter.string(from: plan.fetchedAt))"
    }

    func dayTitle(for day: MensaDay) -> String {
        let weekday = Self.weekdayFormatter.string(from: day.date)
        let date = Self.shortDateFormatter.string(from: day.date)
        return "\(weekday) \(date)"
    }

    func priceText(for meal: MensaMeal) -> String {
        let displayMode = PriceDisplayMode.normalized(UserDefaults.standard.string(forKey: AppPreferenceKeys.priceDisplayMode))

        switch displayMode {
        case .hidden:
            return ""
        case .student:
            return formattedPrice(meal.studentPrice)
        case .studentAndEmployee:
            return [
                formattedPrice(meal.studentPrice),
                formattedPrice(meal.employeePrice)
            ]
            .filter { !$0.isEmpty }
            .joined(separator: " / ")
        case .all:
            let prices = [
                ("Stud.", meal.studentPrice),
                ("MA", meal.employeePrice),
                ("Gast", meal.guestPrice)
            ]
            .compactMap { label, price -> String? in
                let formatted = formattedPrice(price)
                return formatted.isEmpty ? nil : "\(label) \(formatted)"
            }

            return prices.joined(separator: " · ")
        }
    }

    private func formattedPrice(_ price: Double?) -> String {
        guard let price else { return "" }
        return Self.currencyFormatter.string(from: NSNumber(value: price)) ?? ""
    }
}

extension MenuViewModel {
    fileprivate static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "E"
        return formatter
    }()

    fileprivate static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "dd.MM."
        return formatter
    }()

    fileprivate static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    fileprivate static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
