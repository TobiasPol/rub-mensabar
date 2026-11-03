import SwiftUI
import RUBMensaBarCore

struct MealRow: View {
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

struct IconLegendView: View {
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
