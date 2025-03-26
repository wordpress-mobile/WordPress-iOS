public protocol UserPersistentRepositoryReader {
    func string(forKey key: String) -> String?
    func bool(forKey key: String) -> Bool
    func integer(forKey key: String) -> Int
    func float(forKey key: String) -> Float
    func double(forKey key: String) -> Double
    func array(forKey key: String) -> [Any]?
    func dictionary(forKey key: String) -> [String: Any]?
    func url(forKey key: String) -> URL?
    func dictionaryRepresentation() -> [String: Any]
}
