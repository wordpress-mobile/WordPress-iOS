extension NSError {

    static func testInstance(
        description: String = "A test error",
        domain: String = "org.wordpress.unit-tests",
        code: Int = 1
    ) -> NSError {
        .init(code: code, domain: domain, description: description)
    }
}

extension NSError {

    convenience init(code: Int, domain: String, description: String) {
        self.init(domain: domain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
    }
}
