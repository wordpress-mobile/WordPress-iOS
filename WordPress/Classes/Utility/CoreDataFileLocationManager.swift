import Foundation

@objc
protocol CoreDataFileLocationManager: NSObjectProtocol {
    var modelPath: String { get }
    var modelURL: URL { get }
    var storeURL: URL { get }
}

/// This is a class that manages the location of the CoreData files.  This is for use in production code.
/// While testing it's discouraged to use this class.
///
@objc
final class ProductionCoreDataFileLocationManager: NSObject, CoreDataFileLocationManager {
    private static let baseFileName = "WordPress"
    private static let sqliteFileName = "\(baseFileName).sqlite"

    // MARK: - Initializer

    override init() {
        super.init()

        ensureCoreDataStoreIsInAppGroup()
    }

    // MARK: - File Locations

    /// The path of the model file.
    ///
    @objc
    var modelPath: String {
        guard let path = Bundle.main.path(forResource: "WordPress", ofType: "momd") else {
            fatalError("Data model missing!")
        }

        return path
    }

    /// The URL of the model file.
    ///
    @objc
    var modelURL: URL {
        URL(fileURLWithPath: modelPath)
    }

    /// The URL of the SQLLite Store.
    ///
    @objc
    var storeURL: URL {
        guard let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName)?.appendingPathComponent(Self.sqliteFileName) else {

            fatalError("Could not initialize the storeURL.  This is required for persistence to work.")
        }

        return storeURL
    }
}

// MARK: - Migration of Store to App Group

extension ProductionCoreDataFileLocationManager {

    /// The legacy URL of the store back when it was located in the Main App Bundle.
    ///
    private var legacyMainBundleStoreURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Missing Documents Folder")
        }

        return url.appendingPathComponent("WordPress.sqlite")
    }

    /// Ensures that the CoreData Store is in the App Group, or moves it there if it isn't.
    ///
    private func ensureCoreDataStoreIsInAppGroup() {
        let mover = CoreDataStoreMover(modelLocation: modelURL)

        switch mover.moveStore(from: legacyMainBundleStoreURL, to: storeURL) {
        case .success(let url):
            DDLogInfo("Persistent store moved successfully to \(url)")
        case .failure(let error):
            switch error {
            case .destinationFileExists(let url):
                // This is considered a valid scenario in case the file has been moved already."
                // We'll just let the CoreData stack raise any flags if needed.
                DDLogInfo("Persistent store already exists in the App Group at \(url)")
            case .sourceFileDoesNotExist(let url):
                // This is considered a valid scenario, in case the Database hasn't been created yet.
                // We'll just let the CoreData stack raise any flags if needed.
                DDLogInfo("Persistent store does not exist in the Main Bundle at \(url)")
            default:
                let errorMessage = "Fatal error while migrating database to App Group: \(error)"

                DDLogError(errorMessage)
                fatalError(errorMessage)
            }
        }
    }
}
