struct TestError: Error {

    let id: Int

    init(id: Int = 1) {
        self.id = id
    }
}

// There must be a way to make this as an Error extension.
// However, when I try to do so I get the following errors.
//
// Usage: .testError()
// Error: Contextual member reference to static method 'testError(description:domain:code:)' requires 'Self' constraint in the protocol extension
//
// Usage: Error.testError()
// Error: Static member 'testError' cannot be used on protocol metatype '(any Error).Type'
//
// In the meantime, we can call this via NSError.testError()
extension NSError {

    static func testError(
        description: String = "A test error",
        domain: String = "org.wordpress.unit-tests",
        code: Int = 1
    ) -> NSError {
        NSError(
            domain: domain,
            code: code,
            userInfo: [
                NSLocalizedDescriptionKey: description
            ]
        )
    }
}

extension Error {

    static func testError(
        description: String = "A test error",
        domain: String = "org.wordpress.unit-tests",
        code: Int = 1
    ) -> Self {
        // This would be discouraged if it wasn't for the facts that we know that NSError converts to Error.
        NSError.testError(description: description, domain: domain, code: code) as! Self
    }
}
