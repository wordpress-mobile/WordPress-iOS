import Nimble
import XCTest
@testable import WordPress

final class PostSyncStateViewModelTests: CoreDataTestCase {

    func testIdleState() {
        // Given
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .sync)
            .build()
        let viewModel = PostSyncStateViewModel(post: post, isInternetReachable: true)

        // When & Then
        expect(viewModel.state).to(equal(.idle))
        expect(viewModel.isEditable).to(beTrue())
        expect(viewModel.isShowingEllipsis).to(beTrue())
        expect(viewModel.isShowingIndicator).to(beFalse())
        expect(viewModel.iconInfo).to(beNil())
    }

    func testSyncingState() {
        // Given
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .pushing)
            .build()
        let viewModel = PostSyncStateViewModel(post: post, isInternetReachable: true)

        // When & Then
        expect(viewModel.state).to(equal(.syncing))
        expect(viewModel.isEditable).to(beFalse())
        expect(viewModel.isShowingEllipsis).to(beFalse())
        expect(viewModel.isShowingIndicator).to(beTrue())
        expect(viewModel.iconInfo).to(beNil())
    }

    func testOfflineChangesState() {
        // Given
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .failed)
            .build()
        let viewModel = PostSyncStateViewModel(post: post, isInternetReachable: false)

        // When & Then
        expect(viewModel.state).to(equal(.offlineChanges))
        expect(viewModel.isEditable).to(beTrue())
        expect(viewModel.isShowingEllipsis).to(beTrue())
        expect(viewModel.isShowingIndicator).to(beFalse())
        expect(viewModel.iconInfo).toNot(beNil())
    }

    func testFailedState() {
        // Given
        let post = PostBuilder(mainContext)
            .with(remoteStatus: .failed)
            .build()
        let viewModel = PostSyncStateViewModel(post: post, isInternetReachable: true)

        // When & Then
        expect(viewModel.state).to(equal(.failed))
        expect(viewModel.isEditable).to(beTrue())
        expect(viewModel.isShowingEllipsis).to(beTrue())
        expect(viewModel.isShowingIndicator).to(beFalse())
        expect(viewModel.iconInfo).toNot(beNil())
    }
}
