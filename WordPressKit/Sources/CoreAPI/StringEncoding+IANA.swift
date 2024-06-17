import Foundation

extension String.Encoding {
    /// See: https://www.iana.org/assignments/character-sets/character-sets.xhtml
    init?(ianaCharsetName: String) {
        let encoding: CFStringEncoding = CFStringConvertIANACharSetNameToEncoding(ianaCharsetName as CFString)
        guard encoding != kCFStringEncodingInvalidId,
              let builtInEncoding = CFStringBuiltInEncodings(rawValue: encoding)
        else {
            return nil
        }

        switch builtInEncoding {
        case .macRoman:
            self = .macOSRoman
        case .windowsLatin1:
            self = .windowsCP1252
        case .isoLatin1:
            self = .isoLatin1
        case .nextStepLatin:
            self = .nextstep
        case .ASCII:
            self = .ascii
        case .unicode:
            self = .unicode
        case .UTF8:
            self = .utf8
        case .nonLossyASCII:
            self = .nonLossyASCII
        case .UTF16BE:
            self = .utf16BigEndian
        case .UTF16LE:
            self = .utf16LittleEndian
        case .UTF32:
            self = .utf32
        case .UTF32BE:
            self = .utf32BigEndian
        case .UTF32LE:
            self = .utf32LittleEndian
        @unknown default:
            return nil
        }
    }
}
