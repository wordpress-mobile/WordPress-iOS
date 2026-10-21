public protocol KeychainAccessible {
    func getPassword(for username: String, serviceName: String) throws(KeychainError) -> String
    func setPassword(for username: String, to newValue: String?, serviceName: String) throws(KeychainError)
}
