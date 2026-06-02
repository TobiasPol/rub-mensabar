import Foundation

public struct MensaCanteen: Identifiable, Equatable, Hashable {
    public let id: String
    public let displayName: String

    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }

    public var sourceURL: URL {
        URL(string: "https://www.akafoe.de/essen/mensen-und-cafeterien/speiseplan/\(id)")!
    }

    public static let rubMensa = MensaCanteen(
        id: "a0f40678-5e86-4ae4-9ff1-ae1e9e25934b",
        displayName: "RUB Mensa"
    )

    public static let qWest = MensaCanteen(
        id: "a0f40678-ac6b-4b31-a37b-7f0e4b5eb188",
        displayName: "Q-West"
    )

    public static let roteBete = MensaCanteen(
        id: "a0f4067a-78d2-42c2-a3de-1006cf571dea",
        displayName: "Rote Bete"
    )

    public static let available: [MensaCanteen] = [
        .rubMensa,
        .qWest,
        .roteBete
    ]
}

public struct MensaWeekPlan: Equatable {
    public let weekNumber: Int
    public let startDate: Date
    public let endDate: Date
    public let days: [MensaDay]
    public let fetchedAt: Date

    public init(weekNumber: Int, startDate: Date, endDate: Date, days: [MensaDay], fetchedAt: Date) {
        self.weekNumber = weekNumber
        self.startDate = startDate
        self.endDate = endDate
        self.days = days
        self.fetchedAt = fetchedAt
    }
}

public struct MensaDay: Identifiable, Equatable {
    public let id: String
    public let date: Date
    public let meals: [MensaMeal]

    public init(id: String, date: Date, meals: [MensaMeal]) {
        self.id = id
        self.date = date
        self.meals = meals
    }
}

public struct MensaMeal: Identifiable, Equatable {
    public let id: String
    public let category: String
    public let categoryPriority: Int
    public let title: String
    public let subtitle: String
    public let tags: [String]
    public let allergens: [String]
    public let additives: [String]
    public let studentPrice: Double?
    public let employeePrice: Double?
    public let guestPrice: Double?

    public init(
        id: String,
        category: String,
        categoryPriority: Int,
        title: String,
        subtitle: String,
        tags: [String],
        allergens: [String],
        additives: [String],
        studentPrice: Double?,
        employeePrice: Double?,
        guestPrice: Double?
    ) {
        self.id = id
        self.category = category
        self.categoryPriority = categoryPriority
        self.title = title
        self.subtitle = subtitle
        self.tags = tags
        self.allergens = allergens
        self.additives = additives
        self.studentPrice = studentPrice
        self.employeePrice = employeePrice
        self.guestPrice = guestPrice
    }
}

public struct MealIconLegendEntry: Identifiable, Equatable {
    public let code: String
    public let label: String

    public init(code: String, label: String) {
        self.code = code
        self.label = label
    }

    public var id: String {
        code
    }
}

public enum MealIconLegend {
    public static let entries: [MealIconLegendEntry] = [
        MealIconLegendEntry(code: "A", label: "mit Alkohol"),
        MealIconLegendEntry(code: "F", label: "mit Fisch"),
        MealIconLegendEntry(code: "G", label: "mit Geflügel"),
        MealIconLegendEntry(code: "H", label: "Halal"),
        MealIconLegendEntry(code: "L", label: "mit Lamm"),
        MealIconLegendEntry(code: "R", label: "mit Rind"),
        MealIconLegendEntry(code: "S", label: "mit Schwein"),
        MealIconLegendEntry(code: "V", label: "vegetarisch"),
        MealIconLegendEntry(code: "VG", label: "vegan"),
        MealIconLegendEntry(code: "W", label: "mit Wild")
    ]

    public static func label(for code: String) -> String {
        entries.first { $0.code == code }?.label ?? code
    }
}

public enum MealCategoryOrder {
    private static let preferredOrder = [
        "Aktionsgericht",
        "Komponente 1",
        "Komponentenessen",
        "Vegetarische Menükomponente",
        "Vegetarischer Sprinter",
        "Sprinter",
        "Döner",
        "Falafel Teller",
        "Nudeltheke",
        "Salattheke",
        "Beilage 1",
        "Beilage 2",
        "Dessert",
        "Kuchen",
        "Tagessuppe"
    ]

    public static func rank(for category: String, priority: Int) -> Int {
        if let index = preferredOrder.firstIndex(of: category) {
            return index * 10
        }

        return 1_000 + priority
    }
}
