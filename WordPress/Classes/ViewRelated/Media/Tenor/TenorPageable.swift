import Foundation

struct TenorPageable: Pageable {
    let itemsPerPage: Int
    let pageHandle: Int

    static let defaultPageSize = 20
    static let defaultPageIndex = 0
    
    func next() -> Pageable? {
        if pageHandle == 0 {
            return nil
        }

        return TenorPageable(itemsPerPage: itemsPerPage, pageHandle: pageHandle)
    }

    var pageSize: Int {
        return itemsPerPage
    }

    var pageIndex: Int {
        return pageHandle
    }
}

extension TenorPageable {
    init (nextOffset: Int) {
        self.init(itemsPerPage: TenorPageable.defaultPageSize, pageHandle: nextOffset)
    }
}

extension TenorPageable {
    /// Builds the Pageable corresponding to the first page, with the default page size.
    ///
    /// - Returns: A TenorPageable configured with the default page size and the initial page handle
    static func first() -> TenorPageable {
        return TenorPageable(itemsPerPage: defaultPageSize, pageHandle: defaultPageIndex)
    }
}

extension TenorPageable: CustomStringConvertible {
    var description: String {
        return "Tenor Pageable: count \(itemsPerPage) next: \(pageHandle)"
    }
}
