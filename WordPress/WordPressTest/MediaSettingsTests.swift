import XCTest
import Nimble
@testable import WordPress

class MediaSettingsTests: XCTestCase {

    // MARK: - Default values
    func testDefaultMaxImageSize() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let maxImageSize = settings.maxImageSizeSetting
        expect(maxImageSize).to(equal(2000))
    }

    func testDefaultImageOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let imageOptimization = settings.imageOptimizationSetting
        expect(imageOptimization).to(beTrue())
    }

    func testDefaultImageQuality() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let imageQuality = settings.imageQualitySetting
        expect(imageQuality).to(equal(.medium))
    }

    func testDefaultAdvertiseImageOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let advertiseImageOptimization = settings.advertiseImageOptimization
        expect(advertiseImageOptimization).to(beTrue())
    }

    // MARK: - Max Image Size values
    func testMaxImageSizeMigratesCGSizeToInt() {
        let dimension = Int(1200)
        let size = CGSize(width: dimension, height: dimension)
        let database = EphemeralKeyValueDatabase()
        database.set(NSCoder.string(for: size), forKey: "SavedMaxImageSizeSetting")

        let settings = MediaSettings(database: database)
        expect(settings.maxImageSizeSetting).to(equal(dimension))
    }

    func testMaxImageSizeClampsValues() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let lowValue = settings.allowedImageSizeRange.min - 1
        let highValue = settings.allowedImageSizeRange.max + 1

        settings.maxImageSizeSetting = lowValue
        expect(settings.maxImageSizeSetting).to(equal(settings.allowedImageSizeRange.min))
        settings.maxImageSizeSetting = highValue
        expect(settings.maxImageSizeSetting).to(equal(settings.allowedImageSizeRange.max))
    }

    func testImageSizeForUploadReturnsIntMax() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        let highValue = settings.allowedImageSizeRange.max + 1

        settings.maxImageSizeSetting = highValue
        expect(settings.imageSizeForUpload).to(equal(Int.max))

    }

    // MARK: - Values based on image optimization
    func testImageSizeForUploadValueBasedOnOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        expect(settings.imageSizeForUpload).to(equal(2000))
        settings.imageOptimizationSetting = false
        expect(settings.imageSizeForUpload).to(equal(Int.max))
    }

    func testImageQualityForUploadValueBasedOnOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        expect(settings.imageQualityForUpload).to(equal(.medium))
        settings.imageOptimizationSetting = false
        expect(settings.imageQualityForUpload).to(equal(.high))
    }

    func testAdvertiseImageOptimizationValueBasedOnOptimization() {
        let settings = MediaSettings(database: EphemeralKeyValueDatabase())
        expect(settings.advertiseImageOptimization).to(beTrue())
        settings.imageOptimizationSetting = false
        expect(settings.advertiseImageOptimization).to(beFalse())
    }
}
