import Foundation

public enum MensaPlanError: LocalizedError, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case emptyResponse
    case invalidDate(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Die Speiseplan-URL ist ungültig."
        case .requestFailed(let statusCode):
            return "Der Speiseplan konnte nicht geladen werden (HTTP \(statusCode))."
        case .emptyResponse:
            return "Die API hat keine Daten geliefert."
        case .invalidDate(let value):
            return "Ein Datum konnte nicht gelesen werden: \(value)"
        case .decodingFailed(let message):
            return "Die API-Antwort konnte nicht gelesen werden: \(message)"
        }
    }
}

public protocol MensaPlanFetching {
    func fetchCurrentWeek(canteenID: String) async throws -> MensaWeekPlan
}

public final class MensaPlanService: MensaPlanFetching {
    private let session: URLSession

    public init(
        session: URLSession = .shared
    ) {
        self.session = session
    }

    public func fetchCurrentWeek(canteenID: String) async throws -> MensaWeekPlan {
        guard let endpoint = URL(string: "https://akafoe.studylife.org/api/meal-plans/week/current?canteen_id=\(canteenID)") else {
            throw MensaPlanError.invalidURL
        }

        var request = URLRequest(url: endpoint, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("RUBMensaBar/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw MensaPlanError.requestFailed(statusCode: httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw MensaPlanError.emptyResponse
        }

        return try MensaPlanDecoder.decode(data, fetchedAt: Date())
    }
}

public enum MensaPlanDecoder {
    public static func decode(_ data: Data, fetchedAt: Date = Date()) throws -> MensaWeekPlan {
        do {
            let dto = try JSONDecoder().decode(WeekPlanDTO.self, from: data)
            return try map(dto, fetchedAt: fetchedAt)
        } catch let error as MensaPlanError {
            throw error
        } catch {
            throw MensaPlanError.decodingFailed(error.localizedDescription)
        }
    }

    private static func map(_ dto: WeekPlanDTO, fetchedAt: Date) throws -> MensaWeekPlan {
        let startDate = try DateParser.parseAPIDate(dto.startDate)
        let endDate = try DateParser.parseAPIDate(dto.endDate)

        let days = try dto.days.map { dayDTO in
            let date = try DateParser.parseAPIDate(dayDTO.date)
            let meals = dayDTO.meals.map { mealDTO in
                MensaMeal(
                    id: mealDTO.id,
                    category: mealDTO.category?.name ?? "Sonstiges",
                    categoryPriority: mealDTO.category?.priority ?? 100,
                    title: mealDTO.title.trimmingCharacters(in: .whitespacesAndNewlines),
                    subtitle: (mealDTO.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                    tags: mealDTO.icons,
                    allergens: mealDTO.allergens,
                    additives: mealDTO.additives,
                    studentPrice: mealDTO.priceStudent,
                    employeePrice: mealDTO.priceEmployee,
                    guestPrice: mealDTO.priceGuest
                )
            }
            .sorted { left, right in
                let leftRank = MealCategoryOrder.rank(for: left.category, priority: left.categoryPriority)
                let rightRank = MealCategoryOrder.rank(for: right.category, priority: right.categoryPriority)

                if leftRank != rightRank {
                    return leftRank < rightRank
                }

                return left.title.localizedCaseInsensitiveCompare(right.title) == .orderedAscending
            }

            return MensaDay(
                id: DateParser.idString(for: date),
                date: date,
                meals: meals
            )
        }
        .sorted { $0.date < $1.date }

        return MensaWeekPlan(
            weekNumber: dto.weekNumber,
            startDate: startDate,
            endDate: endDate,
            days: days,
            fetchedAt: fetchedAt
        )
    }
}

private enum DateParser {
    static func parseAPIDate(_ value: String) throws -> Date {
        let datePart = String(value.prefix(10))
        guard let date = apiDayFormatter.date(from: datePart) else {
            throw MensaPlanError.invalidDate(value)
        }

        return date
    }

    static func idString(for date: Date) -> String {
        apiDayFormatter.string(from: date)
    }

    private static let apiDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Berlin")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct WeekPlanDTO: Decodable {
    let weekNumber: Int
    let startDate: String
    let endDate: String
    let days: [DayDTO]

    enum CodingKeys: String, CodingKey {
        case weekNumber = "week_number"
        case startDate = "start_date"
        case endDate = "end_date"
        case days
    }
}

private struct DayDTO: Decodable {
    let date: String
    let meals: [MealDTO]
}

private struct MealDTO: Decodable {
    let id: String
    let title: String
    let description: String?
    let icons: [String]
    let allergens: [String]
    let additives: [String]
    let priceStudent: Double?
    let priceEmployee: Double?
    let priceGuest: Double?
    let category: CategoryDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case icons
        case allergens
        case additives
        case priceStudent = "price_student"
        case priceEmployee = "price_employee"
        case priceGuest = "price_guest"
        case category
    }
}

private struct CategoryDTO: Decodable {
    let name: String
    let priority: Int
}
