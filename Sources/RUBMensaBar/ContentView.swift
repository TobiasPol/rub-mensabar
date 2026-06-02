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
                    get: { viewModel.selectedDayID ?? plan.days.first?.id ?? "" },
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

private struct MealRow: View {
    let meal: MensaMeal
    let priceText: String
    let showTags: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(meal.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 118, alignment: .leading)

                Text(meal.title)
                    .font(.system(size: 14, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if (showTags && !meal.tags.isEmpty) || !priceText.isEmpty {
                HStack(spacing: 6) {
                    if showTags && !meal.tags.isEmpty {
                        ForEach(meal.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(mealTagColor(tag).opacity(0.18), in: Capsule())
                                .foregroundStyle(mealTagColor(tag))
                                .help("\(tag): \(MealIconLegend.label(for: tag))")
                                .accessibilityLabel("\(tag), \(MealIconLegend.label(for: tag))")
                        }
                    }

                    if !priceText.isEmpty {
                        Text(priceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.leading, 128)
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct IconLegendView: View {
    private let columns = [
        GridItem(.flexible(minimum: 130), spacing: 8),
        GridItem(.flexible(minimum: 130), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Legende", systemImage: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(MealIconLegend.entries) { entry in
                    HStack(spacing: 6) {
                        Text(entry.code)
                            .font(.system(size: 10, weight: .semibold))
                            .frame(minWidth: 24)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(mealTagColor(entry.code).opacity(0.18), in: Capsule())
                            .foregroundStyle(mealTagColor(entry.code))

                        Text(entry.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.code), \(entry.label)")
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private func mealTagColor(_ tag: String) -> Color {
    switch tag {
    case "VG":
        return .green
    case "V":
        return .mint
    case "F":
        return .blue
    case "G", "H":
        return .orange
    case "R", "S", "L":
        return .red
    default:
        return .secondary
    }
}
