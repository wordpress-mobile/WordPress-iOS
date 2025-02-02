import WordPressUI
import WordPressShared
import WordPressReader

// MARK: - Controller

protocol ReaderDisplaySettingStoreDelegate: NSObjectProtocol {
    func displaySettingDidChange()
}

/// This should be the object to be strongly retained. Keeps the store up-to-date.
class ReaderDisplaySettingStore: NSObject {

    private let repository: UserPersistentRepository

    private let notificationCenter: NotificationCenter

    weak var delegate: ReaderDisplaySettingStoreDelegate?

    /// A public facade to simplify the flag checking dance for the `ReaderDisplaySetting` object.
    /// When the flag is disabled, this will always return the `standard` object, and the setter does nothing.
    var setting: ReaderDisplaySettings {
        get {
            return ReaderDisplaySettings.customizationEnabled ? _setting : .standard
        }
        set {
            guard ReaderDisplaySettings.customizationEnabled,
                  newValue != _setting else {
                return
            }
            _setting = newValue
            broadcastChangeNotification()
        }
    }

    /// The actual instance variable that holds the setting object.
    /// This is intentionally set to private so that it's only controllable by `ReaderDisplaySettingStore`.
    private var _setting: ReaderDisplaySettings = .standard {
        didSet {
            guard oldValue != _setting,
                  let dictionary = try? setting.toDictionary() else {
                return
            }
            repository.set(dictionary, forKey: Constants.key)
        }
    }

    init(repository: UserPersistentRepository = UserPersistentStoreFactory.instance(),
         notificationCenter: NotificationCenter = .default) {
        self.repository = repository
        self.notificationCenter = notificationCenter
        self._setting = {
            guard let dictionary = repository.dictionary(forKey: Constants.key),
                  let data = try? JSONSerialization.data(withJSONObject: dictionary),
                  let setting = try? JSONDecoder().decode(ReaderDisplaySettings.self, from: data) else {
                return .standard
            }
            return setting
        }()
        super.init()
        registerNotifications()
    }

    private func registerNotifications() {
        notificationCenter.addObserver(self,
                                       selector: #selector(handleChangeNotification),
                                       name: .readerDisplaySettingStoreDidChange,
                                       object: nil)
    }

    private func broadcastChangeNotification() {
        notificationCenter.post(name: .readerDisplaySettingStoreDidChange, object: self)
    }

    @objc
    private func handleChangeNotification(_ notification: NSNotification) {
        // ignore self broadcasts.
        if let broadcaster = notification.object as? ReaderDisplaySettingStore,
           broadcaster == self {
            return
        }

        // since we're handling change notifications, a stored setting object *should* exist.
        guard let updatedSetting = try? fetchSetting() else {
            DDLogError("ReaderDisplaySettingStore: Received a didChange notification with a nil stored value")
            return
        }

        _setting = updatedSetting
        delegate?.displaySettingDidChange()
    }

    /// Fetches the stored value of `ReaderDisplaySetting`.
    ///
    /// - Returns: `ReaderDisplaySetting`
    private func fetchSetting() throws -> ReaderDisplaySettings? {
        guard let dictionary = repository.dictionary(forKey: Constants.key) else {
            return nil
        }

        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let setting = try JSONDecoder().decode(ReaderDisplaySettings.self, from: data)
        return setting
    }

    private struct Constants {
        static let key = "readerDisplaySettingKey"
    }
}

fileprivate extension NSNotification.Name {
    static let readerDisplaySettingStoreDidChange = NSNotification.Name("ReaderDisplaySettingDidChange")
}
