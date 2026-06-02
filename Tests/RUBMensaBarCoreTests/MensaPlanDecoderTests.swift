import XCTest
@testable import RUBMensaBarCore

final class MensaPlanDecoderTests: XCTestCase {
    func testProvidesKnownCanteens() throws {
        XCTAssertEqual(MensaCanteen.available.map(\.displayName), ["RUB Mensa", "Q-West", "Rote Bete"])
        XCTAssertEqual(MensaCanteen.qWest.id, "a0f40678-ac6b-4b31-a37b-7f0e4b5eb188")
        XCTAssertEqual(MensaCanteen.roteBete.sourceURL.absoluteString, "https://www.akafoe.de/essen/mensen-und-cafeterien/speiseplan/a0f4067a-78d2-42c2-a3de-1006cf571dea")
    }

    func testProvidesMealIconLegend() throws {
        XCTAssertEqual(MealIconLegend.entries.map(\.code), ["A", "F", "G", "H", "L", "R", "S", "V", "VG", "W"])
        XCTAssertEqual(MealIconLegend.label(for: "VG"), "vegan")
        XCTAssertEqual(MealIconLegend.label(for: "W"), "mit Wild")
        XCTAssertEqual(MealIconLegend.label(for: "X"), "X")
    }

    func testDecodesAndSortsCurrentWeekPlan() throws {
        let plan = try MensaPlanDecoder.decode(Self.samplePayload.data(using: .utf8)!, fetchedAt: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(plan.weekNumber, 23)
        XCTAssertEqual(plan.days.count, 1)
        XCTAssertEqual(plan.days[0].id, "2026-06-01")
        XCTAssertEqual(plan.days[0].meals.map(\.category), ["Aktionsgericht", "Komponente 1", "Vegetarische Menükomponente"])
        XCTAssertEqual(plan.days[0].meals[0].title, "Caesar-Bowl mit Putenbruststreifen")
        XCTAssertEqual(plan.days[0].meals[0].studentPrice, 4.9)
        XCTAssertEqual(plan.days[0].meals[2].tags, ["VG"])
    }

    private static let samplePayload = """
    {
      "week_number": 23,
      "start_date": "2026-06-01",
      "end_date": "2026-06-05",
      "days": [
        {
          "date": "2026-06-01 00:00:00",
          "meals": [
            {
              "id": "component",
              "title": "Lammhacksteak mit Knoblauch Dip",
              "description": "",
              "icons": ["L"],
              "allergens": ["a", "a1"],
              "additives": [],
              "price_student": 3.1,
              "price_employee": 5.8,
              "price_guest": 5.8,
              "category": { "name": "Komponente 1", "priority": 30 }
            },
            {
              "id": "vegan",
              "title": "Gratinierte Aubergine mit Knoblauch Dip",
              "description": "",
              "icons": ["VG"],
              "allergens": ["a"],
              "additives": ["1"],
              "price_student": 2.6,
              "price_employee": 4.7,
              "price_guest": 4.7,
              "category": { "name": "Vegetarische Menükomponente", "priority": 100 }
            },
            {
              "id": "action",
              "title": "Caesar-Bowl mit Putenbruststreifen",
              "description": "",
              "icons": ["G"],
              "allergens": ["c", "g", "j"],
              "additives": ["2"],
              "price_student": 4.9,
              "price_employee": 7.8,
              "price_guest": 7.8,
              "category": { "name": "Aktionsgericht", "priority": 50 }
            }
          ]
        }
      ]
    }
    """
}
