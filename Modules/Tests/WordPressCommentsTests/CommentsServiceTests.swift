import Testing
import WordPressAPI
@testable import WordPressComments

struct CommentsServiceTests {
    @Test func firstPageParamsUseDesignDefaults() {
        let params = CommentsListFilter.approved.firstPageParams
        #expect(params.perPage == 20)
        #expect(params.order == .desc)
        #expect(params.orderby == .dateGmt)
        #expect(params.status?.description == "approve")
    }

    @Test func firstPageParamsCarryEachFilterStatus() {
        for filter in CommentsListFilter.allCases {
            #expect(filter.firstPageParams.status?.description == filter.queryStatus.description)
        }
    }
}
