import Dispatch
import Foundation

/// This is a class that manages the location of the CoreData files.  This is for use in production code.
/// While testing it's discouraged to use this class.
///
@objc
class CoreDataFileLocationManager: NSObject {
    private static let baseFileName = "WordPress"
    private static let sqliteFileName = "\(baseFileName).sqlite"

    @objc
    var modelURL: URL

    @objc
    var storeURL: URL

    // MARK: - Initializer

    required init(modelURL: URL, storeURL: URL) {
        self.modelURL = modelURL
        self.storeURL = storeURL

        super.init()
    }
}

// MARK: - Production CoreDataFileLocationManager

extension CoreDataFileLocationManager {

    @objc
    static func production() -> CoreDataFileLocationManager {
        // This syntax is a bit weird.  What it does is it allows us to execute the code in
        // `executeProductionStoreMigrations` once.
        _ = executeProductionStoreMigrations

        return CoreDataFileLocationManager(modelURL: productionModelURL, storeURL: productionStoreURL)
    }

    // MARK: - Production File Locations

    /// The URL of the production model file.
    ///
    private static var productionModelURL: URL {
        guard let modelPath = Bundle.main.path(forResource: "WordPress", ofType: "momd") else {
            fatalError("Data model missing!")
        }

        return URL(fileURLWithPath: modelPath)
    }

    /// The URL of the production SQLLite Store.
    ///
    private static var productionStoreURL: URL {
        guard let storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WPAppGroupName)?.appendingPathComponent(Self.sqliteFileName) else {

            fatalError("Could not initialize the storeURL.  This is required for persistence to work.")
        }

        return storeURL
    }

    /// The legacy URL of the store back when it was located in the Main App Bundle.
    ///
    private static var legacyMainBundleStoreURL: URL {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Missing Documents Folder")
        }

        return url.appendingPathComponent("WordPress.sqlite")
    }

    // MARK: - Store Location Migrations

    private static var executeProductionStoreMigrations: () = {
        moveStoreFromMainBundleToAppGroup()
    }()

    /// Ensures that the CoreData Store is in the App Group, or moves it there if it isn't.
    ///
    private static func moveStoreFromMainBundleToAppGroup() {
        let mover = CoreDataStoreMover(modelLocation: productionModelURL)

        switch mover.moveStore(from: legacyMainBundleStoreURL, to: productionStoreURL) {
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
