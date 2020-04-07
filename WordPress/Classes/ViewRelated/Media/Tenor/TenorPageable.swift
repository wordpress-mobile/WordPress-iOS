
struct TenorPageable: Pageable {
    let itemsPerPage: Int
    let position: String?
    let currentPageIndex: Int

    static let defaultPageSize = 40
    static let defaultPageIndex = 0

    func next() -> Pageable? {
        guard position != nil else {
            return nil
        }

        return TenorPageable(itemsPerPage: itemsPerPage, position: position, currentPageIndex: currentPageIndex + 1)
    }

    var pageSize: Int {
        return itemsPerPage
    }

    var pageIndex: Int {
        return currentPageIndex
    }
}

extension TenorPageable {
    /// Builds the Pageable corresponding to the first page, with the default page size.
    ///
    /// - Returns: A TenorPageable configured with the default page size and the initial page handle
    static func first() -> TenorPageable {
        return TenorPageable(itemsPerPage: defaultPageSize, position: nil, currentPageIndex: defaultPageIndex)
    }
}

extension TenorPageable: CustomStringConvertible {
    var description: String {
        return "Tenor Pageable: count \(itemsPerPage) next: \(position ?? "")"
    }
}
