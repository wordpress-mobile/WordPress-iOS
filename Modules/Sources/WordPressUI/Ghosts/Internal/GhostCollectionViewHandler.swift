import Foundation
import UIKit

/// GhostCollectionViewHandler: Encapsulates all of the methods required to setup a "Ghost UICollectionView".
///
class GhostCollectionViewHandler: NSObject {

    /// Ghost Settings!
    ///
    let options: GhostOptions

    /// Animation Style
    ///
    let style: GhostStyle

    /// Designated Initializer
    ///
    init(options: GhostOptions, style: GhostStyle) {
        self.options = options
        self.style = style
    }
}

/// SkeletonCollectionViewHandler: DataSource Methods
///
extension GhostCollectionViewHandler: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return options.rowsPerSection.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.rowsPerSection[section]
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: options.reuseIdentifier, for: indexPath)
        (cell as? GhostableView)?.ghostAnimationWillStart()
        cell.startGhostAnimation(style: style)

        return cell
    }
}

/// SkeletonCollectionViewHandler: Delegate Methods
///
extension GhostCollectionViewHandler: UICollectionViewDelegate { }
