protocol ResultsPage {
    associatedtype T
    func content() -> [T]?
    func nextPageable() -> Pageable?
}
