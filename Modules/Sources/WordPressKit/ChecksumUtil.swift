import Foundation

public class ChecksumUtil {

    /// Generates a checksum based on the encoded keys.
    static func checksum<T>(from codable: T) -> String where T: Encodable {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let result: String
        do {
            let data = try encoder.encode(codable)
            result = String(data: data, encoding: .utf8) ?? ""
        } catch {
            result = ""
        }
        return result.md5()
    }
}
