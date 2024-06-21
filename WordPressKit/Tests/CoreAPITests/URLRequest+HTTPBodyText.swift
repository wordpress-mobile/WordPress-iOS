import Foundation

extension URLRequest {
    var httpBodyText: String? {
        guard let data = (httpBody ?? httpBodyStream?.readToEnd() ) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}
