import Nimble
import XCTest
@testable import WordPress

class PageMenuViewModelTests: CoreDataTestCase {

    func testPublishedPageButtonsWithBlazeEnabled() {
        // Given
        let page = PageBuilder(mainContext, canBlaze: true)
            .withRemote()
            .with(status: .publish)
            .build()
        let viewModel = PageMenuViewModel(
            page: page,
            isSiteHomepage: false,
            isSitePostsPage: false,
            isJetpackFeaturesEnabled: true,
            isBlazeFlagEnabled: true
        )

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.blaze],
            [.setParent, .setHomepage, .setPostsPage],
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
        let viewModel = PageMenuViewModel(
            page: page,
            isSiteHomepage: false,
            isSitePostsPage: false,
            isJetpackFeaturesEnabled: true,
            isBlazeFlagEnabled: false
        )

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.setParent, .setHomepage, .setPostsPage],
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
        let viewModel = PageMenuViewModel(
            page: page,
            isSiteHomepage: false,
            isSitePostsPage: false,
            isJetpackFeaturesEnabled: false,
            isBlazeFlagEnabled: false
        )

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.setParent, .setHomepage, .setPostsPage],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testPublishedPageButtonsForHomepage() {
        // Given
        let page = PageBuilder(mainContext, canBlaze: true)
            .withRemote()
            .with(status: .publish)
            .build()
        let viewModel = PageMenuViewModel(
            page: page,
            isSiteHomepage: true,
            isSitePostsPage: false,
            isJetpackFeaturesEnabled: true,
            isBlazeFlagEnabled: true
        )

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.blaze],
            [.setParent, .setPostsPage],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testPublishedPageButtonsForPostsPage() {
        // Given
        let page = PageBuilder(mainContext, canBlaze: true)
            .withRemote()
            .with(status: .publish)
            .build()
        let viewModel = PageMenuViewModel(
            page: page,
            isSiteHomepage: false,
            isSitePostsPage: true,
            isJetpackFeaturesEnabled: true,
            isBlazeFlagEnabled: true
        )

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate],
            [.blaze],
            [.setParent, .setHomepage],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testDraftPageButtons() {
        // Given
        let page = PageBuilder(mainContext)
            .with(status: .draft)
            .build()
        let viewModel = PageMenuViewModel(page: page)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.duplicate, .publish],
            [.setParent],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testScheduledPostButtons() {
        // Given
        let page = PageBuilder(mainContext)
            .with(status: .scheduled)
            .build()
        let viewModel = PageMenuViewModel(page: page)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .publish],
            [.setParent, .setHomepage, .setPostsPage],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testTrashedPageButtons() {
        // Given
        let page = PageBuilder(mainContext)
            .with(status: .trash)
            .build()
        let viewModel = PageMenuViewModel(page: page)
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
