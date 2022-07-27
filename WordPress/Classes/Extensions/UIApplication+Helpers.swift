import Foundation
import UIKit

extension UIApplication {
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        self.open(url)
    }
}
