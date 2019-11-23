import Foundation

struct TenorPageable: Pageable {
    static let defaultPageSize = 10
    static let defaultPageIndex = 0

    private let pageOffset: Int

    // MARK: - Pageable conformance

    func next() -> Pageable? {
        if pageOffset == 0 {
            return nil
        }

        return TenorPageable(pageOffset: pageOffset)
    }

    var pageSize: Int {
        return TenorPageable.defaultPageSize
    }

    var pageIndex: Int {
        return pageOffset
    }
}

extension TenorPageable {
    // Having zero nextOffset means that there are no more pages to display
    init?(nextOffset: Int) {
        guard nextOffset > 0 else {
            return nil
        }

        self.init(pageOffset: nextOffset)
    }
    
    // Builds the Pageable corresponding to the first page, with the default page size.
     static func first() -> TenorPageable {
         return TenorPageable(pageOffset: defaultPageIndex)
     }
}

extension TenorPageable: CustomStringConvertible {
    var description: String {
        return "Tenor Pageable: count \(pageSize) next: \(pageOffset)"
    }
}
