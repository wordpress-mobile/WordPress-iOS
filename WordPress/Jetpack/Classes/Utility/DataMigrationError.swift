import Foundation

enum DataMigrationError {
    case databaseImportError
    case databaseExportError(underlyingError: Error)
    case backupLocationNil
    case sharedUserDefaultsNil
    case dataNotReadyToImport
}

extension DataMigrationError: LocalizedError, CustomNSError {

    var errorDescription: String? {
        switch self {
        case .databaseImportError: return "The database couldn't be copied from shared directory"
        case .databaseExportError: return "The database couldn't be copied to shared directory"
        case .backupLocationNil: return "Database shared directory not found"
        case .sharedUserDefaultsNil: return "Shared user defaults not found"
        case .dataNotReadyToImport: return "The data wasn't ready to import"
        }
    }

    static var errorDomain: String {
        return String(describing: DataMigrationError.self)
    }

    var errorCode: Int {
        switch self {
        case .dataNotReadyToImport: return 100
        case .databaseImportError: return 200
        case .databaseExportError: return 300
        case .backupLocationNil: return 400
        case .sharedUserDefaultsNil: return 401
        }
    }

    var errorUserInfo: [String: Any] {
        var userInfo = [String: Any]()
        if let errorDescription {
            userInfo[NSDebugDescriptionErrorKey] = errorDescription
        }
        return userInfo
    }
}

extension DataMigrationError: CustomDebugStringConvertible {

    var debugDescription: String {
        guard let desc = errorDescription else {
            return String(describing: self)
        }
        return "[\(Self.errorDomain)] \(desc)"
    }
}
