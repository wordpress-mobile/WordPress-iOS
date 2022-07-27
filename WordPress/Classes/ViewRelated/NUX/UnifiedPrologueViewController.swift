import UIKit
import WordPressAuthenticator
import SwiftUI

class UnifiedPrologueViewController: UIPageViewController {

    fileprivate var pages: [UIViewController] = []

    fileprivate var pageControl: UIPageControl!

    fileprivate struct Constants {
        static let pagerPadding: CGFloat = 16.0
    }

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        UnifiedProloguePageType.allCases.forEach({ type in
                                                    pages.append(UnifiedProloguePageViewController(pageType: type))
        })

        setViewControllers([pages[0]], direction: .forward, animated: false)
        view.backgroundColor = .prologueBackground

        addPageControl()
        let backgroundView = UIView.embedSwiftUIView(UnifiedPrologueBackgroundView())
        view.insertSubview(backgroundView, at: 0)
        view.pinSubviewToAllEdges(backgroundView)
    }

    private func addPageControl() {
        let pageControl = UIPageControl()
        pageControl.currentPageIndicatorTintColor = .text
        pageControl.pageIndicatorTintColor = .textSubtle

        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)

        NSLayoutConstraint.activate([
            pageControl.leftAnchor.constraint(equalTo: view.leftAnchor),
            pageControl.rightAnchor.constraint(equalTo: view.rightAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Constants.pagerPadding)
        ])

        pageControl.numberOfPages = pages.count
        pageControl.addTarget(self, action: #selector(handlePageControlValueChanged(sender:)), for: .valueChanged)
        self.pageControl = pageControl
    }

    @objc func handlePageControlValueChanged(sender: UIPageControl) {
        guard let currentPage = viewControllers?.first,
              let currentIndex = pages.firstIndex(of: currentPage) else {
            return
        }

        let direction: UIPageViewController.NavigationDirection = sender.currentPage > currentIndex ? .forward : .reverse
        setViewControllers([pages[sender.currentPage]], direction: direction, animated: true)
        WordPressAuthenticator.track(.loginProloguePaged)
    }
}

extension UnifiedPrologueViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController),
              index > 0 else {
            return nil
        }

        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController),
              index < pages.count - 1 else {
            return nil
        }

        return pages[index + 1]
    }
}

extension UnifiedPrologueViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let toVC = previousViewControllers[0]
        guard let index = pages.firstIndex(of: toVC) else {
            return
        }
        if !completed {
            pageControl?.currentPage = index
        } else {
            WordPressAuthenticator.track(.loginProloguePaged)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let toVC = pendingViewControllers[0]
        guard let index = pages.firstIndex(of: toVC) else {
            return
        }
        pageControl?.currentPage = index
    }
}
