import Foundation
import UniformTypeIdentifiers
import WordPressData
import WordPressMediaLibrary

@MainActor
enum MediaUploadPolicyFactory {
    static func make(from blog: Blog) -> MediaUploadPolicy {
        let pickerTypes = blog.allowedTypeIdentifiers.compactMap { UTType($0) }

        let serverAllowed: Set<String> = blog.allowedFileTypes
        let defaultAllowed = MediaImportService.defaultAllowableFileExtensions

        let mediaSettings = MediaSettings()
        let configuredMaxDim = mediaSettings.imageSizeForUpload
        let imageMax: Int? = configuredMaxDim < Int.max ? configuredMaxDim : nil

        return MediaUploadPolicy(
            filePickerContentTypes: pickerTypes,
            isAllowedForUpload: { _, fileExtension in
                let ext = fileExtension.lowercased()
                if defaultAllowed.contains(ext) { return true }
                if serverAllowed.isEmpty { return true }
                return serverAllowed.contains(ext)
            },
            imageMaxDimension: imageMax,
            imageJpegQuality: mediaSettings.imageQualityForUpload.doubleValue,
            convertHEICToJPEG: true,
            videoMaxDurationSeconds: blog.videoDurationLimit,
            videoExportPreset: mediaSettings.maxVideoSizeSetting.videoPreset,
            videoOutputContentType: .mpeg4Movie,
            stripImageLocation: mediaSettings.removeLocationSetting
        )
    }
}
