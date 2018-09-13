
struct GiphyPageable: Pageable {
    let itemsPerPage: Int
    let pageHandle: Int

    static let defaultPageSize = 40
    static let defaultPageIndex = 0

    func next() -> Pageable? {
        if pageHandle == 0 {
            return nil
        }

        return GiphyPageable(itemsPerPage: itemsPerPage, pageHandle: pageHandle)
    }

    var pageSize: Int {
        return itemsPerPage
    }

    var pageIndex: Int {
        return pageHandle
    }
}

extension GiphyPageable {
    /// Builds the Pageable corresponding to the first page, with the default page size.
    ///
    /// - Returns: A GiphyPageable configured with the default page size and the initial page handle
    static func first() -> GiphyPageable {
        return GiphyPageable(itemsPerPage: defaultPageSize, pageHandle: defaultPageIndex)
    }
}

extension GiphyPageable: CustomStringConvertible {
    var description: String {
        return "Giphy Pageable: count \(itemsPerPage) next: \(pageHandle)"
    }
}
