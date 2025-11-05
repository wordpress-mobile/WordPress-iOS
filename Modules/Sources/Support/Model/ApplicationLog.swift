import Foundation
import SwiftUI
import CoreTransferable
import UniformTypeIdentifiers

public struct ApplicationLog: Identifiable, Sendable, Equatable {
    public let path: URL
    public let createdAt: Date
    public let modifiedAt: Date

    public var id: String {
        path.absoluteString
    }

    public init?(filePath: String) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: filePath)

        guard
            let creationDate = attributes[.creationDate] as? Date,
            let modificationDate = attributes[.modificationDate] as? Date
        else {
            return nil
        }

        self.path = URL(fileURLWithPath: filePath)
        self.createdAt = creationDate
        self.modifiedAt = modificationDate
    }

    public init(path: URL, createdAt: Date, modifiedAt: Date) {
        self.path = path
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

extension ApplicationLog: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .plainText) { (logFile: ApplicationLog) in
            SentTransferredFile(logFile.path)
        }
        ProxyRepresentation(exporting: { (logFile: ApplicationLog) in
            try String(contentsOf: logFile.path, encoding: .utf8)
        })
    }

    static func exportedContentTypes(visibility: TransferRepresentationVisibility) -> [UTType] {
        [
            .plainText,
            .fileURL
        ]
    }
}
