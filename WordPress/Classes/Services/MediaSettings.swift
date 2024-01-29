import Foundation
import AVFoundation

class MediaSettings: NSObject {
    // MARK: - Constants
    fileprivate let imageOptimizationKey = "SavedImageOptimizationSetting"
    fileprivate let maxImageSizeKey = "SavedMaxImageSizeSetting"
    fileprivate let imageQualityKey = "SavedImageQualitySetting"
    fileprivate let removeLocationKey = "SavedRemoveLocationSetting"
    fileprivate let maxVideoSizeKey = "SavedMaxVideoSizeSetting"

    fileprivate let defaultImageOptimization = true
    fileprivate let defaultMaxImageDimension = 2000
    fileprivate let defaultImageQuality: ImageQuality = .medium
    fileprivate let defaultMaxVideoSize: VideoResolution = .sizeOriginal
    fileprivate let defaultRemoveLocation = true

    fileprivate let minImageDimension = 150
    fileprivate let maxImageDimension = 3000

    enum ImageQuality: String {
        case maximum = "MaximumQuality100"
        case high = "HighQuality90"
        case medium = "MediumQuality80"
        case low = "LowQuality70"

        var doubleValue: Double {
            switch self {
            case .maximum:
                return 1.0
            case .high:
                return 0.9
            case .medium:
                return 0.8
            case .low:
                return 0.7
            }
        }

        var description: String {
            switch self {
            case .maximum:
                return NSLocalizedString("appSettings.media.imageQuality.maximum", value: "Maximum", comment: "Indicates an image will use maximum quality when uploaded.")
            case .high:
                return NSLocalizedString("appSettings.media.imageQuality.high", value: "High", comment: "Indicates an image will use high quality when uploaded.")
            case .medium:
                return NSLocalizedString("appSettings.media.imageQuality.medium", value: "Medium", comment: "Indicates an image will use medium quality when uploaded.")
            case(.low):
                return NSLocalizedString("appSettings.media.imageQuality.low", value: "Low", comment: "Indicates an image will use low quality when uploaded.")
            }
        }
    }

    enum VideoResolution: String {
        case size640x480 = "AVAssetExportPreset640x480"
        case size1280x720 = "AVAssetExportPreset1280x720"
        case size1920x1080 = "AVAssetExportPreset1920x1080"
        case size3840x2160 = "AVAssetExportPreset3840x2160"
        case sizeOriginal = "AVAssetExportPresetPassthrough"

        var videoPreset: String {
            switch self {
            case .size640x480:
                return AVAssetExportPreset640x480
            case .size1280x720:
                return AVAssetExportPreset1280x720
            case .size1920x1080:
                return AVAssetExportPreset1920x1080
            case .size3840x2160:
                return AVAssetExportPreset3840x2160
            case .sizeOriginal:
                return AVAssetExportPresetHighestQuality
            }
        }

        var description: String {
            switch self {
            case .size640x480:
                return NSLocalizedString("480p", comment: "Indicates a video will be resized to 640x480 when uploaded.")
            case .size1280x720:
                return NSLocalizedString("720p", comment: "Indicates a video will be resized to HD 1280x720 when uploaded.")
            case .size1920x1080:
                return NSLocalizedString("1080p", comment: "Indicates a video will be resized to Full HD 1920x1080 when uploaded.")
            case .size3840x2160:
                return NSLocalizedString("4K", comment: "Indicates a video will be resized to 4K 3840x2160 when uploaded.")
            case(.sizeOriginal):
                return NSLocalizedString("Original", comment: "Indicates a video will use its original size when uploaded.")
            }
        }

        var intValue: Int {
            switch self {
            case .size640x480:
                return 1
            case .size1280x720:
                return 2
            case .size1920x1080:
                return 3
            case .size3840x2160:
                return 4
            case .sizeOriginal:
                return 5
            }
        }
    }

    // MARK: - Internal variables
    fileprivate let database: KeyValueDatabase

    // MARK: - Initialization
    init(database: KeyValueDatabase) {
        self.database = database
        super.init()
    }

    convenience override init() {
        self.init(database: UserPersistentStoreFactory.instance() as KeyValueDatabase)
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
    @objc var imageSizeForUpload: Int {
        // When image optimization is enabled, setting the max image size setting to
        // the maximum value will be considered as to using the original size.
        if !imageOptimizationEnabled || maxImageSizeSetting >= maxImageDimension {
            return Int.max
        } else {
            return maxImageSizeSetting
        }
    }

    var imageQualityForUpload: ImageQuality {
        return imageOptimizationEnabled ? imageQualitySetting : .high
    }

    /// The stored value for the maximum size images can have before uploading.
    /// If you set this to `maxImageDimension` or higher, it means images won't
    /// be resized on upload.
    /// If you set this to `minImageDimension` or lower, it will be set to `minImageDimension`.
    ///
    /// - Important: don't access this propery directly to check what size to resize an image, use
    ///             `imageSizeForUpload` instead.
    ///
    @objc var maxImageSizeSetting: Int {
        get {
            if let savedSize = database.object(forKey: maxImageSizeKey) as? Int {
                return savedSize
            } else if let savedSize = database.object(forKey: maxImageSizeKey) as? String {
                let newSize = NSCoder.cgSize(for: savedSize).width
                database.set(newSize, forKey: maxImageSizeKey)
                return Int(newSize)
            } else {
                return defaultMaxImageDimension
            }
        }
        set {
            let size = newValue.clamp(min: minImageDimension, max: maxImageDimension)
            database.set(size, forKey: maxImageSizeKey)
        }
    }

    @objc var removeLocationSetting: Bool {
        get {
            if let savedRemoveLocation = database.object(forKey: removeLocationKey) as? Bool {
                return savedRemoveLocation
            } else {
                return defaultRemoveLocation
            }
        }
        set {
            database.set(newValue, forKey: removeLocationKey)
        }
    }

    var maxVideoSizeSetting: VideoResolution {
        get {
            guard let savedSize = database.object(forKey: maxVideoSizeKey) as? String,
                  let videoSize = VideoResolution(rawValue: savedSize) else {
                    return defaultMaxVideoSize
            }
            return videoSize
        }
        set {
            database.set(newValue.rawValue, forKey: maxVideoSizeKey)
        }
    }

    var imageOptimizationEnabled: Bool {
        get {
            if let savedImageOptimization = database.object(forKey: imageOptimizationKey) as? Bool {
                return savedImageOptimization
            } else {
                return defaultImageOptimization
            }
        }
        set {
            database.set(newValue, forKey: imageOptimizationKey)
        }
    }

    var imageQualitySetting: ImageQuality {
        get {
            guard let savedQuality = database.object(forKey: imageQualityKey) as? String,
                  let imageQuality = ImageQuality(rawValue: savedQuality) else {
                    return defaultImageQuality
            }
            return imageQuality
        }
        set {
            database.set(newValue.rawValue, forKey: imageQualityKey)
        }
    }
}
