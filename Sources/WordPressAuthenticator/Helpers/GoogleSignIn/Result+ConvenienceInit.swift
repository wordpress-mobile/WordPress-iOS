extension Swift.Result {

    /// Convenience init to lift the values in an Objective-C style callback, where both success and failure parameters can be nil, to
    /// a domain where at least one is not nil.
    ///
    /// If both values are nil, it will create a `failure` instance wrapping the given `inconsistentStateError`.
    init(value: Success?, error: Failure?, inconsistentStateError: Failure) {
        switch (value, error) {
        case (.some(let value), .none): self = .success(value)
        case (.some, .some(let error)): self = .failure(error)
        case (.none, .some(let error)): self = .failure(error)
        case (.none, .none): self = .failure(inconsistentStateError)
        }
    }
}
