@testable import ContactUs
import Combine
import XCTest

class ContactUsProviderTests: XCTestCase {

    // TODO: This will check against a JSON file or something eventually
    func testProviderLoadsDummyDecisionTree() {
        let provider = ContactUsProvider()

        let expectation = XCTestExpectation(description: "Loads expected data")
        var cancellables = Set<AnyCancellable>()

        provider
            .loadDecisionTree()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Expected to receive a value, but failed with \(error).")
                    }
                },
                receiveValue: { value in
                    guard case .page(questions: let questions) = value.first?.next else { return XCTFail() }
                    guard case .url(let url) = questions.first?.next else { return XCTFail() }

                    XCTAssertEqual(
                        url.absoluteString,
                        "https://apps.wordpress.com/mobile-app-support/getting-started/#wordpresscom"
                    )
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 0.5)
    }
}
