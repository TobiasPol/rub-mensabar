import SwiftUI
import RUBMensaBarCore

struct SettingsView: View {
    @AppStorage(AppPreferenceKeys.defaultCanteenID) private var defaultCanteenID = MensaCanteen.rubMensa.id
    @AppStorage(AppPreferenceKeys.refreshIntervalMinutes) private var refreshIntervalMinutes = RefreshInterval.hourly.rawValue
    @AppStorage(AppPreferenceKeys.priceDisplayMode) private var priceDisplayMode = PriceDisplayMode.studentAndEmployee.rawValue
    @AppStorage(AppPreferenceKeys.showMealTags) private var showMealTags = true
    @AppStorage(AppPreferenceKeys.showSourceLink) private var showSourceLink = true

    @State private var launchAtLogin = LoginItemManager.isEnabled
    @State private var canModifyLoginItem = LoginItemManager.canModify
    @State private var loginItemMessage = LoginItemManager.statusText

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("Allgemein", systemImage: "gearshape")
                }

            dataTab
                .tabItem {
                    Label("Daten", systemImage: "arrow.triangle.2.circlepath")
                }

            displayTab
                .tabItem {
                    Label("Anzeige", systemImage: "textformat")
                }
        }
        .frame(width: 500, height: 320)
        .padding(20)
        .onAppear {
            refreshLoginItemState()
        }
    }

    private var generalTab: some View {
        Form {
            Picker("Standard-Mensa", selection: $defaultCanteenID) {
                ForEach(MensaCanteen.available) { canteen in
                    Text(canteen.displayName)
                        .tag(canteen.id)
                }
            }

            Toggle("Beim Anmelden starten", isOn: Binding(
                get: { launchAtLogin },
                set: { setLaunchAtLogin($0) }
            ))
            .disabled(!canModifyLoginItem)

            Text(loginItemMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private var dataTab: some View {
        Form {
            Picker("Aktualisierungsintervall", selection: $refreshIntervalMinutes) {
                ForEach(RefreshInterval.allCases) { interval in
                    Text(interval.title)
                        .tag(interval.rawValue)
                }
            }

            Text("Der Refresh-Button lädt unabhängig vom Intervall immer sofort neu.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 12)
    }

    private var displayTab: some View {
        Form {
            Picker("Preise", selection: $priceDisplayMode) {
                ForEach(PriceDisplayMode.allCases) { mode in
                    Text(mode.title)
                        .tag(mode.rawValue)
                }
            }

            Toggle("Kennzeichnungen anzeigen", isOn: $showMealTags)
            Toggle("Quellenlink anzeigen", isOn: $showSourceLink)
        }
        .padding(.top, 12)
    }

    private func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            try LoginItemManager.setEnabled(isEnabled)
            refreshLoginItemState()
        } catch {
            canModifyLoginItem = LoginItemManager.canModify
            launchAtLogin = LoginItemManager.isEnabled
            loginItemMessage = error.localizedDescription
        }
    }

    private func refreshLoginItemState() {
        canModifyLoginItem = LoginItemManager.canModify
        launchAtLogin = LoginItemManager.isEnabled
        loginItemMessage = LoginItemManager.statusText
    }
}
