import Foundation
import XCTest

@testable import WordPress

@MainActor
class ApplicationPasswordsViewModelTests: XCTestCase {

    func testOrder() async throws {
        let expectedOrder: [ApplicationTokenItem] = [
            .testInstance(name: "Token 1", lastUsed: .now, createdAt: .now.addingTimeInterval(-100)),
            .testInstance(name: "Token 2", lastUsed: .now.addingTimeInterval(-10), createdAt: .now.addingTimeInterval(-100)),
            .testInstance(name: "Token 3", lastUsed: nil, createdAt: .now.addingTimeInterval(-10)),
            .testInstance(name: "Token 4", lastUsed: nil, createdAt: .now.addingTimeInterval(-20)),
        ]

        let shuffled = expectedOrder.shuffled()
        let viewModel = ApplicationTokenListViewModel(dataProvider: StaticTokenProvider(tokens: .success(shuffled)))

        await viewModel.fetchTokens()

        XCTAssertEqual(viewModel.applicationTokens.count, expectedOrder.count)

        for (index, token) in viewModel.applicationTokens.enumerated() {
            let expectedIndex = try XCTUnwrap(expectedOrder.firstIndex { $0.uuid == token.uuid })
            XCTAssertEqual(index, expectedIndex, "\(token.name) is in the wrong place")
        }
    }

}

private extension ApplicationTokenItem {
    static func testInstance(name: String, lastUsed: Date?, createdAt: Date) -> Self {
        .init(name: name, uuid: UUID(), appId: "app-id", createdAt: createdAt, lastUsed: lastUsed, lastIpAddress: lastUsed == nil ? nil : "1.1.1.1")
    }
}

private class StaticTokenProvider: ApplicationTokenListDataProvider {

    private let result: Result<[ApplicationTokenItem], Error>

    init(tokens: Result<[ApplicationTokenItem], Error>) {
        self.result = tokens
    }

    func loadApplicationTokens() async throws -> [ApplicationTokenItem] {
        try result.get()
    }

}
