import Foundation
import CoreData


public class SearchResultsStatsRecordValue: StatsRecordValue {

    /// This is a magic value indicating that this item represents search result counts for
    /// unknown/encrypted search terms.
    static let unknownSearchTermString = "WPiOS.search_string_unknown"
    // specific value here is mostly irrelevant, but I wanted to choose something that's REALLY
    // unlikely to show-up as a searched string — I could conceivably someone duckduckgoing
    // for things like "unknown search string" and landing on some SEO-explanation-blog.

}
