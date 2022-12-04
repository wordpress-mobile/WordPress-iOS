/// Encapsulates logic related to content migration from WordPress to Jetpack.
///
class ContentMigrationCoordinator {

    static var shared: ContentMigrationCoordinator = {
        .init()
    }()

    // MARK: Dependencies

    private let coreDataStack: CoreDataStack
    private let dataMigrator: ContentDataMigrating
    private let userPersistentRepository: UserPersistentRepository
    private let eligibilityProvider: ContentMigrationEligibilityProvider
    private let tracker: MigrationAnalyticsTracker

    init(coreDataStack: CoreDataStack = ContextManager.shared,
         dataMigrator: ContentDataMigrating = DataMigrator(),
         userPersistentRepository: UserPersistentRepository = UserDefaults.standard,
         eligibilityProvider: ContentMigrationEligibilityProvider = AppConfiguration(),
         tracker: MigrationAnalyticsTracker = .init()) {
        self.coreDataStack = coreDataStack
        self.dataMigrator = dataMigrator
        self.userPersistentRepository = userPersistentRepository
        self.eligibilityProvider = eligibilityProvider
        self.tracker = tracker
    }

    enum ContentMigrationCoordinatorError: LocalizedError {
        case ineligible
        case exportFailure
        case localDraftsNotSynced

        var errorDescription: String? {
            switch self {
            case .ineligible: return "Content export is ineligible"
            case .exportFailure: return "Content export failed"
            case .localDraftsNotSynced: return "Local drafts not synced"
            }
        }
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
            tracker.trackContentExportEligibility(eligible: false)
            completion?(.failure(.ineligible))
            return
        }

        guard isLocalPostsSynced() else {
            let error = ContentMigrationCoordinatorError.localDraftsNotSynced
            tracker.trackContentExportFailed(reason: error.localizedDescription)
            completion?(.failure(error))
            return
        }

        dataMigrator.exportData { [weak self] result in
            switch result {
            case .success:
                self?.tracker.trackContentExportSucceeded()
                completion?(.success(()))

            case .failure(let error):
                DDLogError("[Jetpack Migration] Error exporting data: \(error)")
                self?.tracker.trackContentExportFailed(reason: error.localizedDescription)
                completion?(.failure(.exportFailure))
            }
        }
    }

    /// Starts the content migration process from WordPress to Jetpack.
    /// This method ensures that the migration will only be executed once per installation,
    /// and only performed when all the conditions are fulfilled.
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
            if case .success = result {
                self?.userPersistentRepository.set(true, forKey: .oneOffMigrationKey)
            }

            completion?()
        }
    }
}

// MARK: - Preflights Local Draft Check

private extension ContentMigrationCoordinator {

    func isLocalPostsSynced() -> Bool {
        let fetchRequest = NSFetchRequest<Post>(entityName: String(describing: Post.self))
        fetchRequest.predicate = NSPredicate(format: "remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@ || remoteStatusNumber = %@",
                                             NSNumber(value: AbstractPostRemoteStatus.pushing.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.failed.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.local.rawValue),
                                             NSNumber(value: AbstractPostRemoteStatus.pushingMedia.rawValue))
        guard let count = try? coreDataStack.mainContext.count(for: fetchRequest) else {
            return false
        }

        return count == 0
    }

}

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
