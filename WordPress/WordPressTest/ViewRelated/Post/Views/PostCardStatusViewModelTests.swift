import Nimble
import XCTest

@testable import WordPress


class PostCardStatusViewModelTests: CoreDataTestCase {
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
