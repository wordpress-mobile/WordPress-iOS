
protocol Pageable {
    func next() -> Pageable?
    var pageSize: Int { get }
    var pageIndex: Int { get }
}
