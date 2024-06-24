import Foundation
import Kanvas

/// Contains custom colors and fonts for the KanvasCamera framework
public class KanvasCustomUI {

    public static let shared = KanvasCustomUI()

    func cameraFonts() -> KanvasFonts {
        fatalError()
    }

    func cameraImages() -> KanvasImages {
        return KanvasImages(confirmImage: UIImage(named: "stories-confirm-button"), editorConfirmImage: UIImage(named: "stories-confirm-button"), nextImage: UIImage(named: "stories-next-button"))
    }
}
