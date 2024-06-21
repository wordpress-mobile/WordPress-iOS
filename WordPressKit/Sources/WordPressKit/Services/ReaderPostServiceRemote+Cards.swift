public enum ReaderSortingOption: String, CaseIterable {
    case popularity
    case date
    case noSorting

    var queryValue: String? {
        guard self != .noSorting else {
            return nil
        }
        return rawValue
    }
}

extension ReaderPostServiceRemote {
    /// Returns a collection of RemoteReaderCard using the tags API
    /// a Reader Card can represent an item for the reader feed, such as
    /// - Reader Post
    /// - Topics you may like
    /// - Blogs you may like and so on
    ///
    /// - Parameter topics: an array of String representing the topics
    /// - Parameter page: a String that represents a page handle
    /// - Parameter sortingOption: a ReaderSortingOption that represents a sorting option
    /// - Parameter success: Called when the request succeeds and the data returned is valid
    /// - Parameter failure: Called if the request fails for any reason, or the response data is invalid
    public func fetchCards(for topics: [String],
                           page: String? = nil,
                           sortingOption: ReaderSortingOption = .noSorting,
                           refreshCount: Int? = nil,
                           success: @escaping ([RemoteReaderCard], String?) -> Void,
                           failure: @escaping (Error) -> Void) {
        let path = "read/tags/cards"
        guard let requestUrl = cardsEndpoint(with: path,
                                             topics: topics,
                                             page: page,
                                             sortingOption: sortingOption,
                                             refreshCount: refreshCount) else {
            return
        }
        fetch(requestUrl, success: success, failure: failure)
    }

    /// Returns a collection of RemoteReaderCard using the discover streams API
    /// a Reader Card can represent an item for the reader feed, such as
    /// - Reader Post
    /// - Topics you may like
    /// - Blogs you may like and so on
    ///
    /// - Parameter topics: an array of String representing the topics
    /// - Parameter page: a String that represents a page handle
    /// - Parameter sortingOption: a ReaderSortingOption that represents a sorting option
    /// - Parameter count: the number of cards to fetch. Warning: This also changes the number of objects returned for recommended sites/tags.
    /// - Parameter success: Called when the request succeeds and the data returned is valid
    /// - Parameter failure: Called if the request fails for any reason, or the response data is invalid
    public func fetchStreamCards(for topics: [String],
                                 page: String? = nil,
                                 sortingOption: ReaderSortingOption = .noSorting,
                                 refreshCount: Int? = nil,
                                 count: Int? = nil,
                                 success: @escaping ([RemoteReaderCard], String?) -> Void,
                                 failure: @escaping (Error) -> Void) {
        let path = "read/streams/discover"
        guard let requestUrl = cardsEndpoint(with: path,
                                             topics: topics,
                                             page: page,
                                             sortingOption: sortingOption,
                                             count: count,
                                             refreshCount: refreshCount) else {
            return
        }
        fetch(requestUrl, success: success, failure: failure)
    }

    private func fetch(_ endpoint: String,
                       success: @escaping ([RemoteReaderCard], String?) -> Void,
                       failure: @escaping (Error) -> Void) {
        Task { @MainActor [wordPressComRestApi] in
            await wordPressComRestApi.perform(.get, URLString: endpoint, type: ReaderCardEnvelope.self)
                .map { ($0.body.cards, $0.body.nextPageHandle) }
                .mapError { error -> Error in error.asNSError() }
                .execute(onSuccess: success, onFailure: failure)
        }
    }

    private func cardsEndpoint(with path: String,
                               topics: [String],
                               page: String? = nil,
                               sortingOption: ReaderSortingOption = .noSorting,
                               count: Int? = nil,
                               refreshCount: Int? = nil) -> String? {
        var path = URLComponents(string: path)

        path?.queryItems = topics.map { URLQueryItem(name: "tags[]", value: $0) }

        if let page {
            path?.queryItems?.append(URLQueryItem(name: "page_handle", value: page))
        }

        if let sortingOption = sortingOption.queryValue {
            path?.queryItems?.append(URLQueryItem(name: "sort", value: sortingOption))
        }

        if let count {
            path?.queryItems?.append(URLQueryItem(name: "count", value: String(count)))
        }

        if let refreshCount {
            path?.queryItems?.append(URLQueryItem(name: "refresh", value: String(refreshCount)))
        }

        guard let endpoint = path?.string else {
            return nil
        }

        return self.path(forEndpoint: endpoint, withVersion: ._2_0)
    }
}
