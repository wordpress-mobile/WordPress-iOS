
struct StockPhotosPageable: Pageable {
    private let number: Int
    private let pageHandle: Int

    func next() -> Pageable? {
        if pageHandle == 0 {
            return nil
        }

        return StockPhotosPageable(number: number, pageHandle: pageHandle)
    }

    func pageSize() -> Int {
        return number
    }

    func pageIndex() -> Int {
        return pageHandle
    }
}

extension StockPhotosPageable: Decodable {
    enum CodingKeys: String, CodingKey {
        case nextPage = "next_page"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pageHandle = try values.decode(Int.self, forKey: .nextPage)
        number = 20
    }
}

extension StockPhotosPageable: CustomStringConvertible {
    var description: String {
        return "Stock Photos Pageable: count \(number) next: \(pageHandle)"
    }
}
