protocol DataGetting {

    func data(for request: URLRequest) async throws -> Data
}
