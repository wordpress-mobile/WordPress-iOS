import Foundation

enum DataMigrationError {
    case databaseImportError(underlyingError: Error)
    case databaseExportError(underlyingError: Error)
    case backupLocationNil
    case sharedUserDefaultsNil
    case dataNotReadyToImport
}

extension DataMigrationError: LocalizedError, CustomNSError {

    var errorDescription: String? {
        switch self {
        case .backupLocationNil: return "Database shared directory not found"
        case .sharedUserDefaultsNil: return "Shared user defaults not found"
        case .dataNotReadyToImport: return "The data wasn't ready to import"
        case .databaseImportError(let error): return "Import Failed: \(error.localizedDescription)"
        case .databaseExportError(let error): return "Export Failed: \(error.localizedDescription)"
        }
    }

    static var errorDomain: String {
        return String(describing: DataMigrationError.self)
    }

    var errorCode: Int {
        switch self {
        case .dataNotReadyToImport: return 100
        case .backupLocationNil: return 200
        case .sharedUserDefaultsNil: return 201
        case .databaseImportError(let error): return 1000 + (error as NSError).code
        case .databaseExportError(let error): return 2000 + (error as NSError).code
        }
    }

    var errorUserInfo: [String: Any] {
        switch self {
        case .databaseExportError(let error), .databaseImportError(let error):
            let nsError = error as NSError
            return ["underlying-error-domain": nsError.domain,
                    "underlying-error-code": nsError.code,
                    "underlying-error-message": nsError.localizedDescription,
                    "underlying-error-user-info": nsError.userInfo]
        default:
            return [:]
        }
    }
}

extension DataMigrationError: CustomDebugStringConvertible {
    var debugDescription: String {
        return "[\(Self.errorDomain)] \(localizedDescription)"
    }
}

extension DataMigrationError: Equatable {

    static func ==(left: DataMigrationError, right: DataMigrationError) -> Bool {
        let leftNSError = left as NSError
        let rightNSError = right as NSError
        return leftNSError == rightNSError
    }
}
