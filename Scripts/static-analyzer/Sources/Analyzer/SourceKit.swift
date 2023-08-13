import Foundation
import SourceKittenFramework

extension Request {
    static func expressionType(file: String, compilerArguments: [String]) -> Request {
        // https://github.com/apple/swift/blob/main/tools/SourceKit/docs/Protocol.md#expression-type
        Request.customRequest(request: [
            "key.request": UID("source.request.expression.type"),
            "key.sourcefile": file,
            "key.compilerargs": compilerArguments,
            "key.expectedtypes": [String](),
        ])
    }
}

public enum SourceKitHelper {

    public static func printVersion() {
        let version: ([String: SourceKitRepresentable]) -> String = { response in
            let major: Int64 = response["key.version_major"] as? Int64 ?? 0
            let minor: Int64 = response["key.version_minor"] as? Int64 ?? 0
            let patch: Int64 = response["key.version_patch"] as? Int64 ?? 0
            return "\(major).\(minor).\(patch)"
        }

        do {
            let protocolVersion = try Request.customRequest(request: [
                "key.request": UID("source.request.protocol_version")
            ]).send()
            let compilerVersion = try Request.compilerVersion.send()
            print("sourcekid protocol version \(version(protocolVersion)), Swift compiler \(version(compilerVersion))")
        } catch {
            print("Error: failed to get the running sourcekitd version info")
        }
    }

}

extension Dictionary where Key == String, Value == SourceKitRepresentable {
    func toJSON() -> String {
        let data = try! JSONSerialization.data(withJSONObject: self)
        return String(data: data, encoding: .utf8)!
    }

    func get<T: SourceKitRepresentable>(_ key: String, as type: T.Type = T.self) throws -> T {
        guard let value = self[key] else {
            throw SourceKitResponseError.missing(key: key)
        }
        guard let casted = value as? T else {
            throw SourceKitResponseError.unexpectedType(key: key)
        }
        return casted
    }

    func ensureSourceKitSuccessfulReponse() throws {
        if self["key.internal_diagnostic"] != nil {
            throw AnyError(message: "SourceKit failure: \(toJSON())")
        }
    }
}

extension Structure {

    public func substructure(matching byteRange: ClosedRange<Int64>) throws -> [String: SourceKitRepresentable]? {
        let dict = dictionary
        let offset: Int64 = try dict.get("key.offset")
        let length: Int64 = try dict.get("key.length")
        if offset == byteRange.lowerBound && length == byteRange.count {
            return dict
        }

        let substructures: [[String: SourceKitRepresentable]] = (try? dict.get("key.substructure")) ?? []
        for sub in substructures {
            if let found = try Structure(sourceKitResponse: sub).substructure(matching: byteRange) {
                return found
            }
        }

        return nil
    }

}
