
protocol Pageable {
    func next() -> Pageable?
    func pageSize() -> Int
    func pageIndex() -> Int
}
