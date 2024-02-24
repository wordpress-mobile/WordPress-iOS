public struct JetpackScanThreat: Decodable {
    public enum ThreatStatus: String, Decodable, UnknownCaseRepresentable {
        case fixed
        case ignored
        case current

        // Internal states
        case fixing

        case unknown
        static let unknownCase: Self = .unknown
    }

    public enum ThreatType: String, UnknownCaseRepresentable {
        case core
        case file
        case plugin
        case theme
        case database

        case unknown
        static let unknownCase: Self = .unknown

        init(threat: JetpackScanThreat) {
            // Logic used from https://github.com/Automattic/wp-calypso/blob/5a6b257ad97b361fa6f6a6e496cbfc0ef952b921/client/components/jetpack/threat-item/utils.ts#L11
            if threat.diff != nil {
                self = .core
            } else if threat.context != nil {
                self =  .file
            } else if let ext = threat.extension {
                self = ThreatType(rawValue: ext.type.rawValue)
            } else if threat.rows != nil || threat.signature.contains(Constants.databaseSignature) {
                self = .database
            } else {
                self = .unknown
            }
        }

        private struct Constants {
            static let databaseSignature = "Suspicious.Links"
        }
    }

    /// The ID of the threat
    public let id: Int

    /// The name of the threat signature
    public let signature: String

    /// The description of the threat signature
    public let description: String

    /// The date the threat was first detected
    public let firstDetected: Date

    /// Whether the threat can be automatically fixed
    public let fixable: JetpackScanThreatFixer?

    /// The filename
    public let fileName: String?

    /// The status of the threat (fixed, ignored, current)
    public var status: ThreatStatus?

    /// The date the threat was fixed on
    public let fixedOn: Date?

    /// More information if the threat is a extension type (plugin or theme)
    public let `extension`: JetpackThreatExtension?

    /// The type of threat this is
    public private(set) var type: ThreatType = .unknown

    /// If this is a file based threat this will provide code context to be displayed
    /// Context example:
    /// 3: start test
    /// 4: VIRUS_SIG
    /// 5: end test
    /// marks: 4: (0, 9)
    public let context: JetpackThreatContext?

    // Core modification threats will contain a git diff string
    public let diff: String?

    // Database threats will contain row information
    public let rows: [String: Any]?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        signature = try container.decode(String.self, forKey: .signature)
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        description = try container.decode(String.self, forKey: .description)
        firstDetected = try container.decode(Date.self, forKey: .firstDetected)
        fixedOn = try container.decodeIfPresent(Date.self, forKey: .fixedOn)
        fixable = try? container.decodeIfPresent(JetpackScanThreatFixer.self, forKey: .fixable) ?? nil
        `extension` = try container.decodeIfPresent(JetpackThreatExtension.self, forKey: .extension)
        diff = try container.decodeIfPresent(String.self, forKey: .diff)
        rows = try container.decodeIfPresent([String: Any].self, forKey: .rows)
        status = try container.decode(ThreatStatus.self, forKey: .status)

        // Context obj can either be:
        // - not present
        // - a dictionary
        // - an empty string
        // we can not just set to nil because the threat type logic needs to know if the
        // context attr was present or not
        if let contextDict = try? container.decodeIfPresent([String: Any].self, forKey: .context) {
            context = JetpackThreatContext(with: contextDict)
        } else if (try container.decodeIfPresent(String.self, forKey: .context)) != nil {
            context = JetpackThreatContext.emptyObject()
        } else {
            context = nil
        }

        // Calculate the type of threat last
        type = ThreatType(threat: self)
    }

    private enum CodingKeys: String, CodingKey {
        case fileName = "filename"
        case firstDetected, fixedOn
        case id, signature, description, fixable
        case `extension`, diff, context, rows, status
    }
}

/// An object that describes how a threat can be fixed
public struct JetpackScanThreatFixer: Decodable {
    public enum ThreatFixType: String, Decodable, UnknownCaseRepresentable {
        case replace
        case delete
        case update
        case edit
        case rollback

        case unknown
        static let unknownCase: Self = .unknown
    }

    /// The suggested threat fix type
    public let type: ThreatFixType

    /// The file path of the file to be fixed
    public var file: String?

    /// The target version to fix to
    public var target: String?

    private enum CodingKeys: String, CodingKey {
        case type = "fixer", file, target
    }
}

/// Represents plugin or theme additional metadata
public struct JetpackThreatExtension: Decodable {
    public enum JetpackThreatExtensionType: String, Decodable, UnknownCaseRepresentable {
        case plugin
        case theme

        case unknown
        static let unknownCase: Self = .unknown
    }

    public let slug: String
    public let name: String
    public let type: JetpackThreatExtensionType
    public let isPremium: Bool
    public let version: String
}

public struct JetpackThreatContext {
    public struct ThreatContextLine {
        public var lineNumber: Int
        public var contents: String
        public var highlights: [NSRange]?
    }

    public let lines: [ThreatContextLine]

    public static func emptyObject() -> JetpackThreatContext {
        return JetpackThreatContext(with: [])
    }

    public init(with lines: [ThreatContextLine]) {
        self.lines = lines
    }

    public init?(with dict: [String: Any]) {
        guard let marksDict = dict["marks"] as? [String: Any] else {
            return nil
        }

        var lines: [ThreatContextLine] = []

        // Parse the "lines" which are represented as the keys of the dict
        // "3", "4", "5"
        for key in dict.keys {
            // Since we've already pulled the marks out above, ignore it here
            if key == "marks" {
                continue
            }

            // Validate the incoming object to make sure it contains an integer line, and
            // the string contents
            guard let lineNum = Int(key), let contents = dict[key] as? String else {
                continue
            }

            let highlights: [NSRange]? = Self.highlights(with: marksDict, for: key)

            let context = ThreatContextLine(lineNumber: lineNum,
                                            contents: contents,
                                            highlights: highlights)

            lines.append(context)
        }

        // Since the dictionary keys are unsorted, resort by line number
        self.lines =  lines.sorted { $0.lineNumber < $1.lineNumber }
    }

    /// Parses the marks dictionary and converts them to an array of NSRange's
    private static func highlights(with dict: [String: Any], for key: String) -> [NSRange]? {
        guard let marks = dict[key] as? [[Double]] else {
            return nil
        }

        var highlights: [NSRange] = []

        for rangeArray in marks {
            if let range = Self.range(with: rangeArray) {
                highlights.append(range)
            }
        }

        return (highlights.count > 0) ? highlights : nil
    }

    /// Generates an NSRange from an array
    /// - Parameter array: An array that contains 2 numbers [start, length]
    /// - Returns: Nil if the array fails validation, or an NSRange
    private static func range(with array: [Double]) -> NSRange? {
        guard array.count == 2,
              let location = array.first,
              let length = array.last
        else {
            return nil
        }

        return NSRange(location: Int(location), length: Int(length - location))
    }
}
