
@testable import WordPress

import Nimble

private typealias ButtonGroups = PostCardStatusViewModel.ButtonGroups

class PostCardStatusViewModelTests: XCTestCase {
    private var contextManager: TestContextManager!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        contextManager = TestContextManager()
        context = contextManager.newDerivedContext()
    }

    override func tearDown() {
        context = nil
        contextManager = nil
        super.tearDown()
    }

    func testExpectedButtonGroups() {
        // Arrange
        let expectations: [Post: ButtonGroups] = [
            // Draft that was successfully uploaded to the server
            PostBuilder(context).drafted().withRemote().build():
                ButtonGroups(primary: [.edit, .view, .more], secondary: [.publish, .trash]),
            // Draft that was not uploaded to the server
            PostBuilder(context).drafted().with(remoteStatus: .failed).build():
                ButtonGroups(primary: [.edit, .publish, .trash], secondary: []),
            // Local published draft with confirmed auto-upload.
            PostBuilder(context).published().with(remoteStatus: .failed).confirmedAutoUpload().build():
                ButtonGroups(primary: [.edit, .cancel, .more], secondary: [.moveToDraft, .trash]),
            // Local published draft with canceled auto-upload.
            PostBuilder(context).published().with(remoteStatus: .failed).build():
                ButtonGroups(primary: [.edit, .publish, .more], secondary: [.moveToDraft, .trash])
        ]

        // Act and Assert
        expectations.forEach { post, expectedButtonGroups in
            let viewModel = PostCardStatusViewModel(post: post)

            expect(viewModel.buttonGroups).to(equal(expectedButtonGroups))
        }
    }
}
