import XCTest
import UIKit
@testable import WordPress

class ReaderRetryFailedImageViewTests: XCTestCase {

    class Delegate: ReaderRetryFailedImageDelegate {
        var didTap = false

        func didTapRetry() {
            didTap = true
        }
    }

    func testLoadFromNib() {
        // Given
        let type = ReaderRetryFailedImageView.self

        // When
        let view = type.loadFromNib()

        // Then
        XCTAssert(view.isMember(of: type))
    }

    func testContentForDisplayIsNotEmpty() {
        // Given
        let type = ReaderRetryFailedImageView.self

        // When
        let content = type.contentForDisplay()

        // Then
        XCTAssertFalse(content.string.isEmpty)
    }

    func testCallDelegateWhenTapActionIsCalled() {
        // Given
        let retryView = ReaderRetryFailedImageView.loadFromNib()
        let delegate = Delegate()
        retryView.delegate = delegate

        // When
        retryView.sendActions(for: .touchUpInside)

        // Then
        XCTAssertTrue(delegate.didTap)
    }
}
