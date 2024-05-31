import Nimble
import XCTest
@testable import WordPress

class PostCardStatusViewModelTests: CoreDataTestCase {

    func testPublishedPostButtons() {
        // Given
        let post = PostBuilder(mainContext, canBlaze: true)
            .withRemote()
            .published()
            .build()
        let viewModel = PostCardStatusViewModel(post: post, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate, .share],
            [.blaze],
            [.stats, .comments, .settings],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testPublishedPostButtonsWithBlazeDisabled() {
        // Given
        let post = PostBuilder(mainContext, canBlaze: false)
            .withRemote()
            .published()
            .build()
        let viewModel = PostCardStatusViewModel(post: post, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate, .share],
            [.stats, .comments, .settings],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testPublishedPostButtonsWithJetpackFeaturesDisabled() {
        // Given
        let post = PostBuilder(mainContext)
            .withRemote()
            .published()
            .build()
        let viewModel = PostCardStatusViewModel(post: post, isJetpackFeaturesEnabled: false, isBlazeFlagEnabled: false)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft, .duplicate, .share],
            [.settings],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testDraftPostButtons() {
        // Given
        let post = PostBuilder(mainContext)
            .drafted()
            .build()
        let viewModel = PostCardStatusViewModel(post: post, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.publish, .duplicate],
            [.settings],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testPendingPostButtons() {
        // Given
        let post = PostBuilder(mainContext)
            .pending()
            .build()
        let viewModel = PostCardStatusViewModel(post: post, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.publish, .moveToDraft, .duplicate],
            [.settings],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testScheduledPostButtons() {
        // Given
        let post = PostBuilder(mainContext)
            .scheduled()
            .build()
        let viewModel = PostCardStatusViewModel(post: post, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.view],
            [.moveToDraft],
            [.settings],
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    func testTrashedPostButtons() {
        // Given
        let post = PostBuilder(mainContext)
            .trashed()
            .build()
        let viewModel = PostCardStatusViewModel(post: post, isJetpackFeaturesEnabled: true, isBlazeFlagEnabled: true)

        // When & Then
        let buttons = viewModel.buttonSections
            .filter { !$0.buttons.isEmpty }
            .map { $0.buttons }
        let expectedButtons: [[AbstractPostButton]] = [
            [.moveToDraft],
            [.delete]
        ]
        expect(buttons).to(equal(expectedButtons))
    }
}
