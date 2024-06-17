public struct StatsSearchTermTimeIntervalData {
    public let period: StatsPeriodUnit
    public let periodEndDate: Date

    public let totalSearchTermsCount: Int
    public let hiddenSearchTermsCount: Int
    public let otherSearchTermsCount: Int
    public let searchTerms: [StatsSearchTerm]

    public init(period: StatsPeriodUnit,
                periodEndDate: Date,
                searchTerms: [StatsSearchTerm],
                totalSearchTermsCount: Int,
                hiddenSearchTermsCount: Int,
                otherSearchTermsCount: Int) {
        self.period = period
        self.periodEndDate = periodEndDate
        self.searchTerms = searchTerms
        self.totalSearchTermsCount = totalSearchTermsCount
        self.hiddenSearchTermsCount = hiddenSearchTermsCount
        self.otherSearchTermsCount = otherSearchTermsCount
    }
}

public struct StatsSearchTerm {
    public let term: String
    public let viewsCount: Int

    public init(term: String,
                viewsCount: Int) {
        self.term = term
        self.viewsCount = viewsCount
    }
}

extension StatsSearchTermTimeIntervalData: StatsTimeIntervalData {
    public static var pathComponent: String {
        return "stats/search-terms"
    }

    public init?(date: Date, period: StatsPeriodUnit, jsonDictionary: [String: AnyObject]) {
        guard
            let unwrappedDays = type(of: self).unwrapDaysDictionary(jsonDictionary: jsonDictionary),
            let totalSearchTerms = unwrappedDays["total_search_terms"] as? Int,
            let hiddenSearchTerms = unwrappedDays["encrypted_search_terms"] as? Int,
            let otherSearchTerms = unwrappedDays["other_search_terms"] as? Int,
            let searchTermsDict = unwrappedDays["search_terms"] as? [[String: AnyObject]]
            else {
                return nil
        }

        let searchTerms: [StatsSearchTerm] = searchTermsDict.compactMap {
            guard let term = $0["term"] as? String, let views = $0["views"] as? Int else {
                return nil
            }

            return StatsSearchTerm(term: term, viewsCount: views)
        }

        self.periodEndDate = date
        self.period = period
        self.totalSearchTermsCount = totalSearchTerms
        self.hiddenSearchTermsCount = hiddenSearchTerms
        self.otherSearchTermsCount = otherSearchTerms
        self.searchTerms = searchTerms
    }

}
