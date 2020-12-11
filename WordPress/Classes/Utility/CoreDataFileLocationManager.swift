/// This is a class that manages the location of the CoreData files.  This is for use in production code.
/// While testing it's discouraged to use this class.
///
@objc
class CoreDataFileLocationManager: NSObject {
    private static let baseFileName = "WordPress"
    private static let modelExtension = "momd"
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
        guard let modelPath = Bundle.main.path(forResource: baseFileName, ofType: modelExtension) else {
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

    private static let StoreToAppGroupMigrationIdentifier = "org.wordpress.StoreToAppGroupMigration"
    private static let StoreToAppGroupMigrationCompleteKey = "org.wordpress.StoreToAppGroupMigrationComplete"

    /// Ensures that the CoreData Store is in the App Group, or moves it there if it isn't.
    ///
    private static func moveStoreFromMainBundleToAppGroup() {
        guard !CommandLine.arguments.contains("isTesting") else {
            // We really don't want any of this code run during unit testing.
            return
        }

        guard !UserDefaults.standard.bool(forKey: StoreToAppGroupMigrationCompleteKey) else {
            DDLogInfo("\(StoreToAppGroupMigrationIdentifier): Migration already performed.")
            return
        }

        let mover = CoreDataStoreMover()

        switch mover.moveStore(ofType: NSSQLiteStoreType, from: legacyMainBundleStoreURL, to: productionStoreURL) {
        case .success(let url):
            DDLogInfo("\(StoreToAppGroupMigrationIdentifier): Persistent store moved successfully to \(url)")

            UserDefaults.standard.set(true, forKey: StoreToAppGroupMigrationCompleteKey)
        case .failure(let error):
            switch error {
            case .sourceFileDoesNotExist(let url):
                // If it's the first run there will be no need to perform the migration as the source file won't exist.
                DDLogInfo("\(StoreToAppGroupMigrationIdentifier): Persistent store does not exist at source location \(url). We assume this is the first App run.")

                UserDefaults.standard.set(true, forKey: StoreToAppGroupMigrationCompleteKey)
            default:
                let errorMessage = "🔴 \(StoreToAppGroupMigrationIdentifier): Fatal error while migrating database to App Group: \(error)"

                fatalError(errorMessage)
            }
        }
    }
}
