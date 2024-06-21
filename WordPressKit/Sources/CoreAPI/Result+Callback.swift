public extension Swift.Result {

    // Notice there are no explicit unit tests for this utility because it is implicitly tested via the consuming code's tests.
    func execute(onSuccess: (Success) -> Void, onFailure: (Failure) -> Void) {
        switch self {
        case .success(let value): onSuccess(value)
        case .failure(let error): onFailure(error)
        }
    }

    func execute(_ completion: (Self) -> Void) {
        completion(self)
    }

    func eraseToError() -> Result<Success, Error> {
        mapError { $0 }
    }

}
