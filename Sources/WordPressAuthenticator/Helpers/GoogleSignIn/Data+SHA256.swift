import CryptoKit

extension Data {

    func sha256Hashed() -> Data {
        Data(SHA256.hash(data: self))
    }

    func sha256Hashed() -> String {
        SHA256.hash(data: self).map { String(format: "%02hhx", $0) }.joined()
    }
}
