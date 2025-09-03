import Foundation

extension HTTPURLResponse {

    /// Return parameter value in a header field.
    ///
    /// For example, you can use this method to get "charset" value from a 'Content-Type' header like
    /// `Content-Type: applications/json; charset=utf-8`.
    func value(ofParameter parameterName: String, inHeaderField headerName: String, stripQuotes: Bool = true) -> String? {
        guard let headerValue = value(forHTTPHeaderField: headerName) else {
            return nil
        }

        return Self.value(ofParameter: parameterName, inHeaderValue: headerValue, stripQuotes: stripQuotes)
    }

    func value(forHTTPHeaderField field: String, withoutParameters: Bool) -> String? {
        guard withoutParameters else {
            return value(forHTTPHeaderField: field)
        }

        guard let headerValue = value(forHTTPHeaderField: field) else {
            return nil
        }

        guard let firstSemicolon = headerValue.firstIndex(of: ";") else {
            return headerValue
        }

        return String(headerValue[headerValue.startIndex..<firstSemicolon])
    }

    static func value(ofParameter parameterName: String, inHeaderValue headerValue: String, stripQuotes: Bool = true) -> String? {
        // Find location of '<parameter>=' string in the header.
        guard let location = headerValue.range(of: parameterName + "=", options: .caseInsensitive) else {
            return nil
        }

        let parameterValueStart = location.upperBound
        let parameterValueEnd: String.Index

        // ';' marks the end of the parameter value.
        if let found = headerValue.range(of: ";", range: parameterValueStart..<headerValue.endIndex)?.lowerBound {
            parameterValueEnd = found
        } else {
            // No ';' found. The parameter must be the last one.
            parameterValueEnd = headerValue.endIndex
        }

        let parameterValueRange = parameterValueStart..<parameterValueEnd
        var value = String(headerValue[parameterValueRange])

        if stripQuotes {
            value.removePrefix("\"")
            value.removeSuffix("\"")
        }

        return value
    }

}
