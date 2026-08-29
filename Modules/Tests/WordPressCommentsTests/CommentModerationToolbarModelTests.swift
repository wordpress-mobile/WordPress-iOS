import Testing
@testable import WordPressComments

struct CommentModerationToolbarModelTests {
    @Test func pendingStatusShowsPendingModel() {
        #expect(CommentModerationToolbarModel.make(status: .pending, showsToolbar: true) == .pending)
    }

    @Test func approvedStatusShowsApprovedModel() {
        #expect(CommentModerationToolbarModel.make(status: .approved, showsToolbar: true) == .approved)
    }

    @Test func spamStatusShowsBinModelRestoringFromSpam() {
        #expect(
            CommentModerationToolbarModel.make(status: .spam, showsToolbar: true)
                == .inBin
        )
    }

    @Test func trashStatusShowsBinModelRestoringFromTrash() {
        #expect(
            CommentModerationToolbarModel.make(status: .trash, showsToolbar: true)
                == .inBin
        )
    }

    @Test func otherStatusIsHiddenEvenWhenToolbarShows() {
        #expect(CommentModerationToolbarModel.make(status: .other("archived"), showsToolbar: true) == .hidden)
    }

    @Test func nilStatusIsHidden() {
        #expect(CommentModerationToolbarModel.make(status: nil, showsToolbar: true) == .hidden)
    }

    @Test(arguments: [
        CommentListItem.Status.pending,
        .approved,
        .spam,
        .trash,
        .other("archived")
    ])
    func toolbarOffForcesHidden(_ status: CommentListItem.Status) {
        #expect(CommentModerationToolbarModel.make(status: status, showsToolbar: false) == .hidden)
    }

    @Test func nilStatusWithToolbarOffIsHidden() {
        #expect(CommentModerationToolbarModel.make(status: nil, showsToolbar: false) == .hidden)
    }

    @Test func approvedModelMovesUnapproveToTheMenu() {
        #expect(CommentModerationToolbarModel.approved.menuAction == .unapprove)
    }

    @Test(arguments: [CommentModerationToolbarModel.pending, .inBin, .hidden])
    func pendingBinAndHiddenModelsHaveNoMenuAction(_ model: CommentModerationToolbarModel) {
        #expect(model.menuAction == nil)
    }
}
