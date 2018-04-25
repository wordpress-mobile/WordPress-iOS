
struct StockPhotosPageable: Pageable {
    let itemsPerPage: Int
    let pageHandle: Int

    static let defaultPageSize = 40
    static let defaultPageIndex = 0

    func next() -> Pageable? {
        if pageHandle == 0 {
            return nil
        }

        return StockPhotosPageable(itemsPerPage: itemsPerPage, pageHandle: pageHandle)
    }

    var pageSize: Int {
        return itemsPerPage
    }

    var pageIndex: Int {
        return pageHandle
    }
}

extension StockPhotosPageable {
    /// Builds the Pageable corresponding to the first page, with the default page size.
    ///
    /// - Returns: A StockPhotosPageable configured with the default page size and the initial page handle
    static func first() -> StockPhotosPageable {
        return StockPhotosPageable(itemsPerPage: defaultPageSize, pageHandle: defaultPageIndex)
    }
}

extension StockPhotosPageable: Decodable {
    enum CodingKeys: String, CodingKey {
        case nextPage = "next_page"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pageHandle = try values.decode(Int.self, forKey: .nextPage)
        itemsPerPage = type(of: self).defaultPageSize
    }
}

extension StockPhotosPageable: CustomStringConvertible {
    var description: String {
        return "Stock Photos Pageable: count \(itemsPerPage) next: \(pageHandle)"
    }
}
