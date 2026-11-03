import AppKit
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
    private var scheduledInterval: RefreshInterval?
    private var observers: [(NotificationCenter, NSObjectProtocol)] = []
    private var hasLoaded = false
    private var lastKnownDay: Date

    init(service: MensaPlanFetching? = nil) {
        AppPreferenceKeys.registerDefaults()
        self.service = service ?? MensaPlanService(userAgent: AppInfo.userAgent)
        lastKnownDay = Self.berlinCalendar.startOfDay(for: Date())
        selectedCanteen = Self.preferredCanteenFromDefaults()

        observe(NotificationCenter.default, UserDefaults.didChangeNotification) { model in
            model.applyPreferenceChanges()
        }
        // A menu bar app stays running for days: jump to the new day (and the
        // new week's plan) at midnight and after the Mac wakes from sleep.
        observe(NotificationCenter.default, .NSCalendarDayChanged) { model in
            model.handleClockChange(afterWake: false)
        }
        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.didWakeNotification) { model in
            model.handleClockChange(afterWake: true)
        }

        scheduleAutoRefresh()
    }

    deinit {
        autoRefreshTimer?.invalidate()
        for (center, observer) in observers {
            center.removeObserver(observer)
        }
    }

    private func observe(
        _ center: NotificationCenter,
        _ name: Notification.Name,
        perform action: @escaping @MainActor (MenuViewModel) -> Void
    ) {
        let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                action(self)
            }
        }
        observers.append((center, observer))
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

    private func selectedDayIDForFreshPlan(_ plan: MensaWeekPlan) -> String? {
        if let selectedDayID, plan.days.contains(where: { $0.id == selectedDayID }) {
            return selectedDayID
        }

        return preferredDay(in: plan)?.id
    }

    private func handleClockChange(afterWake: Bool) {
        let today = Self.berlinCalendar.startOfDay(for: Date())
        if today != lastKnownDay {
            lastKnownDay = today
            // Drop the old selection so the fresh plan opens on today.
            selectedDayID = nil
        }

        guard hasLoaded else { return }

        Task {
            if afterWake {
                // Give Wi-Fi a moment to reconnect before hitting the API.
                try? await Task.sleep(for: .seconds(5))
            }
            await refresh(silent: true)
        }
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
        let rawInterval = UserDefaults.standard.integer(forKey: AppPreferenceKeys.refreshIntervalMinutes)
        let interval = RefreshInterval.normalized(rawInterval)

        // didChangeNotification fires for every defaults write in the process
        // (including AppKit's own), so only restart the timer on a real change.
        guard interval != scheduledInterval else { return }
        scheduledInterval = interval

        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil

        guard let seconds = interval.seconds else {
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
}
