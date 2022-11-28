/// Encapsulates logic related to content migration from WordPress to Jetpack.
///
class ContentMigrationCoordinator {

    static let shared: ContentMigrationCoordinator = .init()

    // MARK: Dependencies

    private let dataMigrator: ContentDataMigrating
    private let userPersistentRepository: UserPersistentRepository
    private let eligibilityProvider: ContentMigrationEligibilityProvider

    init(dataMigrator: ContentDataMigrating = DataMigrator(),
         userPersistentRepository: UserPersistentRepository = UserDefaults.standard,
         eligibilityProvider: ContentMigrationEligibilityProvider = AppConfiguration()) {
        self.dataMigrator = dataMigrator
        self.userPersistentRepository = userPersistentRepository
        self.eligibilityProvider = eligibilityProvider
    }

    enum ContentMigrationCoordinatorError: Error {
        case ineligible
        case exportFailure
    }

    // MARK: Methods

    /// Starts the content migration process of exporting app data to the shared location
    /// that will be accessible by the Jetpack app.
    ///
    /// The completion block is intentionally called regardless of whether the export process
    /// succeeds or fails. Since the export process consists of local file operations, we should
    /// just let the user continue with the original intent in case of failure.
    ///
    /// - Parameter completion: Closure called after the export process completes.
    func startAndDo(completion: ((Result<Void, ContentMigrationCoordinatorError>) -> Void)? = nil) {
        guard eligibilityProvider.isEligibleForMigration else {
            completion?(.failure(.ineligible))
            return
        }

        // TODO: Sync local post drafts here.

        dataMigrator.exportData { result in
            if case let .failure(error) = result {
                DDLogError("[Jetpack Migration] Error exporting data: \(error)")
                completion?(.failure(.exportFailure))
                return
            }

            completion?(.success(()))
        }
    }

    /// Silently starts the content migration process from WordPress to Jetpack.
    /// This operation is only executed once per installation, and only performed
    /// when all the conditions are fulfilled.
    ///
    /// Note: If the conditions are not fulfilled, this method will attempt to migrate
    /// again on the next call.
    ///
    func startOnceIfNeeded(completion: (() -> Void)? = nil) {
        if userPersistentRepository.bool(forKey: .oneOffMigrationKey) {
            completion?()
            return
        }

        startAndDo { [weak self] result in
            guard case .success = result else {
                completion?()
                return
            }

            self?.userPersistentRepository.set(true, forKey: .oneOffMigrationKey)
            completion?()
        }
    }
}

// MARK: - Content Migrating

protocol ContentDataMigrating {
    func exportData(completion: ((Result<Void, DataMigrator.DataMigratorError>) -> Void)?)
    func importData(completion: ((Result<Void, DataMigrator.DataMigratorError>) -> Void)?)
}

extension DataMigrator: ContentDataMigrating {}

// MARK: - Content Migration Eligibility Provider

protocol ContentMigrationEligibilityProvider {
    var isEligibleForMigration: Bool { get }
}

extension AppConfiguration: ContentMigrationEligibilityProvider {
    var isEligibleForMigration: Bool {
        FeatureFlag.contentMigration.enabled && Self.isWordPress && AccountHelper.isLoggedIn && AccountHelper.hasBlogs
    }
}

// MARK: - Constants

private extension String {
    static let oneOffMigrationKey = "wordpress_one_off_export"
}
