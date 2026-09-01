import Testing
@testable import WordPressComments

struct CommentsListFilterMembershipTests {
    @Test func allMatchesOnlyPendingAndApproved() {
        #expect(CommentsListFilter.all.matches(.pending))
        #expect(CommentsListFilter.all.matches(.approved))
        #expect(!CommentsListFilter.all.matches(.spam))
        #expect(!CommentsListFilter.all.matches(.trash))
        #expect(!CommentsListFilter.all.matches(.other("post-trashed")))
    }

    @Test func exactFiltersMatchOnlyTheirStatus() {
        #expect(CommentsListFilter.pending.matches(.pending))
        #expect(!CommentsListFilter.pending.matches(.approved))
        #expect(CommentsListFilter.approved.matches(.approved))
        #expect(CommentsListFilter.spam.matches(.spam))
        #expect(CommentsListFilter.trash.matches(.trash))
    }

    @Test func customStatusMatchesNoFilter() {
        for filter in CommentsListFilter.allCases {
            #expect(!filter.matches(.other("weird")))
        }
    }
}
