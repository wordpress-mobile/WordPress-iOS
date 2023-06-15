/// A generic stub test double implementation to delegate stubbing methods that have a success/failure behavior.
///
/// Use it via specialized protocol extensions to generated a Stub for a single-method protocol.
///
/// ```swift
/// protocol ResourceFetching {
///
///     func fetch(completion: (Result<Resource, Error>))
/// }
///
/// // TODO....
/// ```
class Stub<Value, Error: Swift.Error> {

    let stubbedResult: Result<Value, Error>

    init(stubbedResult: Result<Value, Error>) {
        self.stubbedResult = stubbedResult
    }

    func stubBehavior(completion: @escaping (Result<Value, Error>) -> Void) {
        completion(stubbedResult)
    }

    func stubBehavior(success: (Value) -> Void, failure: (Error) -> Void) {
        switch stubbedResult {
        case .success(let value): success(value)
        case .failure(let error): failure(error)
        }
    }
}
