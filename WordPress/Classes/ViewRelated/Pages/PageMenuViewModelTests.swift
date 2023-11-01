import Nimble
import XCTest
@testable import WordPress

class PageMenuViewModelTests: CoreDataTestCase {

    func testPublishedPageButtons() {
        // Given
        let page = PageBuilder(mainContext, canBlaze: true)
            .withRemote()
            .with(status: .publish)
            .build()
        let viewModel = PageMenuViewModel(page: page, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.blaze],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testPublishedPageButtonsWithBlazeDisabled() {
        // Given
        let page = PageBuilder(mainContext, canBlaze: false)
            .withRemote()
            .with(status: .publish)
            .build()
        let viewModel = PageMenuViewModel(page: page, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: false)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testPublishedPageButtonsWithJetpackFeaturesDisabled() {
        // Given
        let page = PageBuilder(mainContext)
            .withRemote()
            .with(status: .publish)
            .build()

        let viewModel = PageMenuViewModel(page: page, isJetpackFeaturesEnabled: false, isBlazeFlagEnabled: false)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testDraftPageButtons() {
        // Given
        let page = PageBuilder(mainContext)
            .with(status: .draft)
            .build()
        let viewModel = PageMenuViewModel(page: page, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.duplicate, .publish],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testScheduledPostButtons() {
        // Given
        let page = PageBuilder(mainContext)
            .with(status: .scheduled)
            .build()
        let viewModel = PageMenuViewModel(page: page, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .publish],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testTrashedPageButtons() {
        // Given
        let page = PageBuilder(mainContext)
            .with(status: .trash)
            .build()
        let viewModel = PageMenuViewModel(page: page, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)
        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }
}
