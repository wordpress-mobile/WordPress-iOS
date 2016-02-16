import Foundation

protocol MediaSettingsStorage {
    func valueForKey(key: String) -> AnyObject?
    func setValue(value: AnyObject, forKey key: String)
}

class MediaSettings: NSObject {
    // MARK: - Constants
    private let maxImageSizeKey = "SavedMaxImageSizeSetting"
    private let minImageDimension = 150
    private let maxImageDimension = 3000

    // MARK: - Internal variables
    private let storage: MediaSettingsStorage

    // MARK: - Initialization
    init(storage: MediaSettingsStorage) {
        self.storage = storage
        super.init()
    }

    convenience override init() {
        self.init(storage: DefaultsStorage())
    }

    // MARK: Public accessors

    /// The minimum and maximum allowed sizes for `maxImageSizeSetting`.
    /// The UI to configure this setting should not allow values outside this limits.
    /// - seealso: maxImageSizeSetting
    var allowedImageSizeRange: (min: Int, max: Int) {
        return (minImageDimension, maxImageDimension)
    }

    /// The size that an image needs to be resized to before uploading.
    /// - note: if the image doesn't need to be resized, it returns `Int.max`
    var imageSizeForUpload: Int {
        if maxImageSizeSetting >= maxImageDimension {
            return Int.max
        } else {
            return maxImageSizeSetting
        }
    }

    /// The stored value for the maximum size images can have before uploading.
    /// If you set this to `maxImageDimension` or higher, it means images won't
    /// be resized on upload.
    /// If you set this to `minImageDimension` or lower, it will be set to `minImageDimension`.
    /// - important: don't access this propery directly to check what size to resize an image, use `imageSizeForUpload` instead.
    var maxImageSizeSetting: Int {
        get {
            if let savedSize = storage.valueForKey(maxImageSizeKey) as? Int {
                return savedSize
            } else if let savedSize = storage.valueForKey(maxImageSizeKey) as? String {
                let newSize = CGSizeFromString(savedSize).width
                storage.setValue(newSize, forKey: maxImageSizeKey)
                return Int(newSize)
            } else {
                return maxImageDimension
            }
        }
        set {
            let size = newValue.clamp(min: minImageDimension, max: maxImageDimension)
            storage.setValue(size, forKey: maxImageSizeKey)
        }
    }

    // MARK: - Storage implementations

    struct DefaultsStorage: MediaSettingsStorage {
        func setValue(value: AnyObject, forKey key: String) {
            NSUserDefaults.standardUserDefaults().setObject(value, forKey: key)
            NSUserDefaults.resetStandardUserDefaults()
        }
        func valueForKey(key: String) -> AnyObject? {
            return NSUserDefaults.standardUserDefaults().objectForKey(key)
        }
    }

    class EphemeralStorage: MediaSettingsStorage {
        private var memory = [String: AnyObject]()

        func setValue(value: AnyObject, forKey key: String) {
            memory[key] = value
        }

        func valueForKey(key: String) -> AnyObject? {
            return memory[key]
        }
    }
}
