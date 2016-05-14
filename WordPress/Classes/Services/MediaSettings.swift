import Foundation

class MediaSettings: NSObject {
    // MARK: - Constants
    private let maxImageSizeKey = "SavedMaxImageSizeSetting"
    private let removeLocationKey = "SavedRemoveLocationSetting"

    private let minImageDimension = 150
    private let maxImageDimension = 3000

    // MARK: - Internal variables
    private let database: KeyValueDatabase

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
        super.init()
    }

    convenience override init() {
        self.init(database: NSUserDefaults())
    }

    // MARK: Public accessors

    /// The minimum and maximum allowed sizes for `maxImageSizeSetting`.
    /// The UI to configure this setting should not allow values outside this limits.
    ///
    /// - Seealso: maxImageSizeSetting
    ///
    var allowedImageSizeRange: (min: Int, max: Int) {
        return (minImageDimension, maxImageDimension)
    }

    /// The size that an image needs to be resized to before uploading.
    ///
    /// - Note: if the image doesn't need to be resized, it returns `Int.max`
    ///
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
    ///
    /// - Important: don't access this propery directly to check what size to resize an image, use
    ///             `imageSizeForUpload` instead.
    ///
    var maxImageSizeSetting: Int {
        get {
            if let savedSize = database.objectForKey(maxImageSizeKey) as? Int {
                return savedSize
            } else if let savedSize = database.objectForKey(maxImageSizeKey) as? String {
                let newSize = CGSizeFromString(savedSize).width
                database.setObject(newSize, forKey: maxImageSizeKey)
                return Int(newSize)
            } else {
                return maxImageDimension
            }
        }
        set {
            let size = newValue.clamp(min: minImageDimension, max: maxImageDimension)
            database.setObject(size, forKey: maxImageSizeKey)
        }
    }

    var removeLocationSetting: Bool {
        get {
            if let savedRemoveLocation = database.objectForKey(removeLocationKey) as? Bool {
                return savedRemoveLocation
            } else {
                return true
            }
        }
        set {
            database.setObject(newValue, forKey: removeLocationKey)
        }
    }
}
