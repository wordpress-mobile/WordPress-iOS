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
            [.stats, .comments],
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
            [.stats, .comments],
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
            [.duplicate, .publish],
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
            [.trash]
        ]
        expect(buttons).to(equal(expectedButtons))
    }

    /// If the post fails to upload and there is internet connectivity, show "Upload failed" message
    ///
    func testReturnFailedMessageIfPostFailedAndThereIsConnectivity() {
        let post = PostBuilder(mainContext).revision().with(remoteStatus: .failed).confirmedAutoUpload().build()

        let viewModel = PostCardStatusViewModel(post: post, isInternetReachable: true)

        expect(viewModel.status).to(equal(i18n("Upload failed")))
        expect(viewModel.statusColor).to(equal(.error))
    }

    /// If the post fails to upload and there is NO internet connectivity, show a message that we'll publish when the user is back online
    ///
    func testReturnWillUploadLaterMessageIfPostFailedAndThereIsConnectivity() {
        let post = PostBuilder(mainContext).revision().with(remoteStatus: .failed).confirmedAutoUpload().build()

        let viewModel = PostCardStatusViewModel(post: post, isInternetReachable: false)

        expect(viewModel.status).to(equal(i18n("We'll publish the post when your device is back online.")))
        expect(viewModel.statusColor).to(equal(.warning))
    }
}
