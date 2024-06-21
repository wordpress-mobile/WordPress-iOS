/// Represents a JSON Web Token (JWT)
///
/// See https://jwt.io/introduction
public struct JSONWebToken {
    let rawValue: String

    let header: [String: Any]
    let payload: [String: Any]
    let signature: String

    init?(encodedString: String) {
        let segments = encodedString.components(separatedBy: ".")

        // JWT has three segments: header, payload, and signature
        guard segments.count == 3 else {
            return nil
        }

        // Notice that JWT uses base64url encoding, not base64.
        //
        // See:
        // - https://tools.ietf.org/html/rfc7515#appendix-C
        // - https://jwt.io/introduction

        // Note: Splitting the guards is useful to know which one fails
        guard let headerData = Data(base64URLEncoded: segments[0]) else {
            return nil
        }

        guard let payloadData = Data(base64URLEncoded: segments[1]) else {
            return nil
        }

        guard let header = try? JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any] else {
            return nil
        }

        guard let payload = try? JSONSerialization.jsonObject(with: payloadData, options: []) as? [String: Any] else {
            return nil
        }

        self.rawValue = encodedString
        self.header = header
        self.payload = payload
        self.signature = segments[2]
    }
}
