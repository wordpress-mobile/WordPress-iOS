struct TestError: Error {

    let id: Int

    init(id: Int = 1) {
        self.id = id
    }
}

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
