import UIKit

class LoginProloguePageViewController: UIPageViewController {
    @objc var pages: [UIViewController] = []
    fileprivate var pageControl: UIPageControl?
    fileprivate var bgAnimation: UIViewPropertyAnimator?
    fileprivate struct Constants {
        static let pagerPadding: CGFloat = 9.0
        static let pagerHeight: CGFloat = 0.13
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        pages.append(LoginProloguePromoViewController(as: .post))
        pages.append(LoginProloguePromoViewController(as: .stats))
        pages.append(LoginProloguePromoViewController(as: .reader))
        pages.append(LoginProloguePromoViewController(as: .notifications))
        pages.append(LoginProloguePromoViewController(as: .jetpack))

        setViewControllers([pages[0]], direction: .forward, animated: false)
        view.backgroundColor = backgroundColor(for: 0)

        addPageControl()
    }

    @objc func addPageControl() {
        let newControl = UIPageControl()

        newControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newControl)

        newControl.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.pagerPadding).isActive = true
        newControl.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        newControl.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        newControl.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: Constants.pagerHeight).isActive = true


        newControl.numberOfPages = pages.count
        newControl.addTarget(self, action: #selector(handlePageControlValueChanged(sender:)), for: UIControlEvents.valueChanged)
        pageControl = newControl
    }

    @objc func handlePageControlValueChanged(sender: UIPageControl) {
        guard let currentPage = viewControllers?.first,
            let currentIndex = pages.index(of: currentPage) else {
            return
        }

        let direction: UIPageViewControllerNavigationDirection = sender.currentPage > currentIndex ? .forward : .reverse
        setViewControllers([pages[sender.currentPage]], direction: direction, animated: true)
        WordPressAuthenticator.post(event: .loginProloguePaged)
    }

    fileprivate func animateBackground(for index: Int, duration: TimeInterval = 0.5) {
        bgAnimation?.stopAnimation(true)
        bgAnimation = UIViewPropertyAnimator(duration: 0.5, curve: .easeOut) { [weak self] in
            self?.view.backgroundColor = self?.backgroundColor(for: index)
        }
        bgAnimation?.startAnimation()
    }

    fileprivate func backgroundColor(for index: Int) -> UIColor {
        switch index % 2 {
        case 0:
            return WPStyleGuide.lightBlue()
        case 1:
            fallthrough
        default:
            return WPStyleGuide.wordPressBlue()
        }
    }
}

extension LoginProloguePageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.index(of: viewController) else {
            return nil
        }
        if index > 0 {
            return pages[index - 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.index(of: viewController) else {
            return nil
        }
        if index < pages.count - 1 {
            return pages[index + 1]
        }
        return nil
    }
}

extension LoginProloguePageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let toVC = previousViewControllers[0]
        guard let index = pages.index(of: toVC) else {
            return
        }
        if !completed {
            pageControl?.currentPage = index
            animateBackground(for: index, duration: 0.2)
        } else {
            WordPressAuthenticator.post(event: .loginProloguePaged)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let toVC = pendingViewControllers[0]
        guard let index = pages.index(of: toVC) else {
            return
        }
        animateBackground(for: index)
        pageControl?.currentPage = index
    }
}
