import XCTest
@testable import WordPress

class SiteIntentDataTests: XCTestCase {

    /// Tests that a single vertical is returned when there's an exact match
    func testExactFiltering() throws {
        // Given
        let foodSearchTerm = "food"
        let expectedFoodVertical = SiteIntentVertical(
            slug: "food",
            localizedTitle: "Food",
            emoji: "🍔",
            isDefault: true,
            isCustom: false
        )

        // When
        let foodSearchResult = SiteIntentData.filterVerticals(with: foodSearchTerm)

        // Then
        XCTAssertEqual(foodSearchResult.count, 1)
        XCTAssertEqual(foodSearchResult[0], expectedFoodVertical)
    }

    func testPartialFiltering() throws {
        // Given
        let partialSearchTerm = "tr"
        let expectedVerticals = [
            SiteIntentVertical(
                slug: "tr",
                localizedTitle: "tr",
                emoji: "＋",
                isDefault: false,
                isCustom: true
            ),
            SiteIntentVertical(
                slug: "travel",
                localizedTitle: NSLocalizedString("Travel", comment: "Travel site intent topic"),
                emoji: "✈️",
                isDefault: true,
                isCustom: false
            ),
            SiteIntentVertical(
                slug: "writing_poetry",
                localizedTitle: NSLocalizedString("Writing & Poetry", comment: "Writing & Poetry site intent topic"),
                emoji: "📓",
                isDefault: false,
                isCustom: false
            )
        ]

        // When
        let partialResults = SiteIntentData.filterVerticals(with: partialSearchTerm)

        // Then
        XCTAssertEqual(expectedVerticals, partialResults)
    }

    /// Tests that a custom vertical is inserted when there isn't an exact match
    func testCustomFiltering() throws {
        // Given
        let fooSearchTerm = "foo"
        let expectedCustomResult = SiteIntentVertical(
            slug: "foo",
            localizedTitle: "foo",
            emoji: "＋",
            isDefault: false,
            isCustom: true
        )
        let expectedFoodVertical = SiteIntentVertical(
            slug: "food",
            localizedTitle: "Food",
            emoji: "🍔",
            isDefault: true,
            isCustom: false
        )

        // When
        let fooSearchResult = SiteIntentData.filterVerticals(with: fooSearchTerm)

        // Then
        XCTAssertEqual(fooSearchResult.count, 2)
        XCTAssertEqual(fooSearchResult[0], expectedCustomResult)
        XCTAssertEqual(fooSearchResult[1], expectedFoodVertical)
    }


    /// Tests that the output isn't changed when whitespace is searched
    func testWhitespaceFiltering() throws {
        // Given
        let whitespaceSearchTerm = " "

        // When
        let emptyStringResult = SiteIntentData.filterVerticals(with: "")
        let whitespaceSearchResult = SiteIntentData.filterVerticals(with: whitespaceSearchTerm)

        // Then
        XCTAssertEqual(whitespaceSearchResult, emptyStringResult)
    }

    /// Tests that verticals are in alphabetical order by localized title
    func testAlphabetizedTitles() throws {
        // Given
        let allVerticals = SiteIntentData.allVerticals

        // When
        let alphabetizedVerticals = allVerticals.sorted(by: { $0.localizedTitle < $1.localizedTitle })

        // Then
        XCTAssertEqual(alphabetizedVerticals, allVerticals)
    }

    /// Tests that the defaultVerticals properties returns default verticals
    func testDefaultVerticals() throws {
        // Given
        let defaultVerticals = SiteIntentData.defaultVerticals

        // When
        let nilNonDefault = defaultVerticals.first(where: { $0.isDefault == false })

        // Then
        XCTAssertNil(nilNonDefault)
    }

}
