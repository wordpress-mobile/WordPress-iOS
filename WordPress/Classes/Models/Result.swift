
/// Result type, encapsulates the result of an operation that either returns a value or an error
///
/// - success: the operation was a success, and it returned this value
/// - error: the error returned by the operation
enum Result<Value, Error> {
    case success(Value)
    case failure(Error)
}
