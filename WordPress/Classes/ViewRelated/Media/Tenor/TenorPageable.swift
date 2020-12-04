
struct TenorPageable: Pageable {
    let itemsPerPage: Int
    let position: String?
    let currentPageIndex: Int

    static let defaultPageSize = 40 // same size as StockPhotos
    static let defaultPageIndex = 0
    static let defaultPosition: String? = nil

    func next() -> Pageable? {
        guard let position = position,
        let currentPosition = Int(position) else {
            return nil
        }

        // If the last page is not full, there is no more to load (thus there is no next).
        let totalPossibleResults = (currentPageIndex + 1) * itemsPerPage
        let remainingPageSpace = totalPossibleResults - currentPosition

        if remainingPageSpace < itemsPerPage {
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
        return TenorPageable(itemsPerPage: defaultPageSize, position: defaultPosition, currentPageIndex: defaultPageIndex)
    }
}

extension TenorPageable: CustomStringConvertible {
    var description: String {
        return "Tenor Pageable: count \(itemsPerPage) next: \(position ?? "")"
    }
}
