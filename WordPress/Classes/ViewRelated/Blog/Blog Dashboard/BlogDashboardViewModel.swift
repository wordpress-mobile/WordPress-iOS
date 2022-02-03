import Foundation
import UIKit

class BlogDashboardViewModel {
    private weak var viewController: BlogDashboardViewController?

    enum Section: CaseIterable {
        case quickLinks
        case posts
    }

    // FIXME: temporary placeholder
    private let quickLinks = ["Quick Links"]
    private let posts = ["Posts"]

    typealias DataSource = UICollectionViewDiffableDataSource<Section, String>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, String>
    typealias QuickLinksHostCell = HostCollectionViewCell<QuickLinksView>

    private lazy var dataSource: DataSource? = {
        guard let viewController = viewController else {
            return nil
        }

        print("$$ one")
        return DataSource(collectionView: viewController.collectionView) { [unowned self] collectionView, indexPath, identifier in
            print("$$ two")
            switch identifier {
            case self.quickLinks.first:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: QuickLinksHostCell.defaultReuseID, for: indexPath) as? QuickLinksHostCell
                cell?.hostedView = QuickLinksView(title: self.quickLinks[indexPath.item])
                return cell
            case self.posts.first:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DashboardPostsCardCell.defaultReuseID, for: indexPath) as? DashboardPostsCardCell
                cell?.configure(viewController, blog: viewController.blog!)
                return cell
            default:
                break
            }
            return UICollectionViewCell()
        }
    }()

    init(viewController: BlogDashboardViewController?) {
        self.viewController = viewController
    }

    func applySnapshotForInitialData(_ collectionView: UICollectionView) {
        var snapshot = Snapshot()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems(quickLinks, toSection: Section.quickLinks)
        snapshot.appendItems(posts, toSection: Section.posts)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
}
