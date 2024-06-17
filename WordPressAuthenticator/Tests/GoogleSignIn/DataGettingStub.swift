@testable import WordPressAuthenticator

struct DataGettingStub: DataGetting {

    let result: Result<Data, Error>

    init(data: Data) {
        self.init(result: .success(data))
    }

    init(error: Error) {
        self.init(result: .failure(error))
    }

    init(result: Result<Data, Error>) {
        self.result = result
    }

    func data(for request: URLRequest) async throws -> Data {
        switch result {
        case .success(let data): return data
        case .failure(let error): throw error
        }
    }
}
