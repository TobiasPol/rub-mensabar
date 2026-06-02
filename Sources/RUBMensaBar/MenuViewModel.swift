import Foundation
import RUBMensaBarCore

@MainActor
final class MenuViewModel: ObservableObject {
    @Published private(set) var plan: MensaWeekPlan?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var selectedCanteen: MensaCanteen = .rubMensa
    @Published var selectedDayID: String?

    let canteens = MensaCanteen.available

    private let service: MensaPlanFetching
    private var autoRefreshTimer: Timer?
    private var defaultsObserver: NSObjectProtocol?
    private var hasLoaded = false

    init(service: MensaPlanFetching? = nil) {
        AppPreferenceKeys.registerDefaults()
        self.service = service ?? MensaPlanService()
        selectedCanteen = Self.preferredCanteenFromDefaults()

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.applyPreferenceChanges()
            }
        }

        scheduleAutoRefresh()
    }

    deinit {
        autoRefreshTimer?.invalidate()
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
    }

    var selectedDay: MensaDay? {
        guard let plan else { return nil }

        if let selectedDayID, let selected = plan.days.first(where: { $0.id == selectedDayID }) {
            return selected
        }

        return preferredDay(in: plan)
    }

    var selectedCanteenID: String {
        selectedCanteen.id
    }

    var sourceURL: URL {
        selectedCanteen.sourceURL
    }

    var showMealTags: Bool {
        UserDefaults.standard.bool(forKey: AppPreferenceKeys.showMealTags)
    }

    var showSourceLink: Bool {
        UserDefaults.standard.bool(forKey: AppPreferenceKeys.showSourceLink)
    }

    var weekTitle: String {
        guard let plan else { return "Aktueller Wochenplan" }

        return "KW \(plan.weekNumber) · \(Self.shortDateFormatter.string(from: plan.startDate))-\(Self.shortDateFormatter.string(from: plan.endDate))"
    }

    var lastUpdatedText: String {
        guard let plan else { return "Noch nicht aktualisiert" }

        return "Aktualisiert \(Self.timeFormatter.string(from: plan.fetchedAt))"
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }

        hasLoaded = true
        await refresh()
    }

    func selectCanteen(id: String) {
        guard let canteen = canteens.first(where: { $0.id == id }), canteen != selectedCanteen else {
            return
        }

        selectedCanteen = canteen
        UserDefaults.standard.set(canteen.id, forKey: AppPreferenceKeys.defaultCanteenID)
        selectedDayID = nil
        plan = nil
        errorMessage = nil

        Task {
            await refresh()
        }
    }

    func refresh(silent: Bool = false) async {
        let requestCanteen = selectedCanteen

        if !silent || plan == nil {
            isLoading = true
        }
        errorMessage = nil

        do {
            let fetchedPlan = try await service.fetchCurrentWeek(canteenID: requestCanteen.id)

            guard selectedCanteen == requestCanteen else {
                return
            }

            plan = fetchedPlan
            selectedDayID = selectedDayIDForFreshPlan(fetchedPlan)
        } catch {
            if selectedCanteen == requestCanteen {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }

        if selectedCanteen == requestCanteen {
            isLoading = false
        }
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

    private func selectedDayIDForFreshPlan(_ plan: MensaWeekPlan) -> String? {
        if let selectedDayID, plan.days.contains(where: { $0.id == selectedDayID }) {
            return selectedDayID
        }

        return preferredDay(in: plan)?.id
    }

    private func applyPreferenceChanges() {
        scheduleAutoRefresh()
        objectWillChange.send()

        let preferredCanteen = Self.preferredCanteenFromDefaults()
        guard preferredCanteen != selectedCanteen else {
            return
        }

        selectedCanteen = preferredCanteen
        selectedDayID = nil
        plan = nil
        errorMessage = nil

        Task {
            await refresh()
        }
    }

    private func scheduleAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil

        let rawInterval = UserDefaults.standard.integer(forKey: AppPreferenceKeys.refreshIntervalMinutes)
        guard let seconds = RefreshInterval.normalized(rawInterval).seconds else {
            return
        }

        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh(silent: true)
            }
        }
        timer.tolerance = min(seconds * 0.1, 60)
        autoRefreshTimer = timer
    }

    private static func preferredCanteenFromDefaults() -> MensaCanteen {
        let storedID = UserDefaults.standard.string(forKey: AppPreferenceKeys.defaultCanteenID)
        return MensaCanteen.available.first(where: { $0.id == storedID }) ?? .rubMensa
    }

    private func preferredDay(in plan: MensaWeekPlan) -> MensaDay? {
        let today = Date()
        if let todayPlan = plan.days.first(where: { Self.berlinCalendar.isDate($0.date, inSameDayAs: today) }) {
            return todayPlan
        }

        if let nextOpenDay = plan.days.first(where: { $0.date >= Self.berlinCalendar.startOfDay(for: today) }) {
            return nextOpenDay
        }

        return plan.days.first
    }

    private static let berlinCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        return calendar
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "E"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "dd.MM."
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.numberStyle = .currency
        formatter.currencyCode = "EUR"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
