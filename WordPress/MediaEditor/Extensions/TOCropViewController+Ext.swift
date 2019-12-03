import TOCropViewController

extension TOCropViewController {
    // TOCropViewController sometimes resize the image by 1, 2 or 3 points automatically.
    // In those cases we're not considering that as a cropping action.
    var isCropped: Bool {
        return abs(imageSizeDiscardingRotation.width - image.size.width) > 4 ||
        abs(imageSizeDiscardingRotation.height - image.size.height) > 4
    }

    var imageSizeDiscardingRotation: CGSize {
        let imageSize = imageCropFrame.size

        let anglesThatChangesImageSize = [90, 270]
        if anglesThatChangesImageSize.contains(angle) {
            return CGSize(width: imageSize.height, height: imageSize.width)
        } else {
            return imageSize
        }
    }

    var isRotated: Bool {
        return angle != 0
    }

    var actions: [MediaEditorOperation] {
        var operations: [MediaEditorOperation] = []

        if isCropped {
            operations.append(.crop)
        }

        if isRotated {
            operations.append(.rotate)
        }

        return operations
    }
}
