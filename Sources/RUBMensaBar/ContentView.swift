import AppKit
import SwiftUI
import RUBMensaBarCore

struct ContentView: View {
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            content
        }
        .frame(width: 460, height: 620)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedCanteen.displayName)
                        .font(.system(size: 20, weight: .semibold))
                    Text(viewModel.weekTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading)
                .help("Speiseplan aktualisieren")
                .accessibilityLabel("Speiseplan aktualisieren")

                Button {
                    SettingsWindowPresenter.open()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Einstellungen")
                .accessibilityLabel("Einstellungen")

                Button {
                    NSApp.terminate(nil)
                } label: {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("RUB MensaBar beenden")
                .accessibilityLabel("RUB MensaBar beenden")
            }

            Picker("Mensa", selection: Binding(
                get: { viewModel.selectedCanteenID },
                set: { viewModel.selectCanteen(id: $0) }
            )) {
                ForEach(viewModel.canteens) { canteen in
                    Text(canteen.displayName)
                        .tag(canteen.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            if let plan = viewModel.plan, !plan.days.isEmpty {
                Picker("Tag", selection: Binding(
                    // Mirror selectedDay so the highlighted segment always
                    // matches the meals shown below (today by default).
                    get: { viewModel.selectedDay?.id ?? plan.days.first?.id ?? "" },
                    set: { viewModel.selectedDayID = $0 }
                )) {
                    ForEach(plan.days) { day in
                        Text(viewModel.dayTitle(for: day))
                            .tag(day.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading, viewModel.plan == nil {
            loadingView
        } else if let errorMessage = viewModel.errorMessage, viewModel.plan == nil {
            errorView(message: errorMessage)
        } else if let day = viewModel.selectedDay {
            dayView(day)
        } else {
            emptyView
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Speiseplan wird geladen")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)
            Text("Speiseplan konnte nicht geladen werden")
                .font(.headline)
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 36)
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Erneut versuchen", systemImage: "arrow.clockwise")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.secondary)
            Text("Kein Speiseplan verfügbar")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dayView(_ day: MensaDay) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(day.meals) { meal in
                        MealRow(
                            meal: meal,
                            priceText: viewModel.priceText(for: meal),
                            showTags: viewModel.showMealTags
                        )
                    }

                    if viewModel.showMealTags {
                        IconLegendView()
                    }
                }
                .padding(16)
            }

            Divider()

            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                    Text("Aktualisiere")
                        .foregroundStyle(.secondary)
                } else if let errorMessage = viewModel.errorMessage {
                    // A background refresh failed: keep showing the last plan,
                    // but make it obvious the data may be stale.
                    Label("Aktualisierung fehlgeschlagen · \(viewModel.lastUpdatedText)", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .help(errorMessage)
                } else {
                    Text(viewModel.lastUpdatedText)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.showSourceLink {
                    Link(destination: viewModel.sourceURL) {
                        Label("Quelle", systemImage: "safari")
                    }
                }
            }
            .font(.caption)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}
