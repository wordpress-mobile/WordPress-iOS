import UIKit

class LoginProloguePageViewController: UIPageViewController {
    var pages: [UIViewController] = []
    fileprivate var pageControl: UIPageControl?
    fileprivate var bgAnimation: UIViewPropertyAnimator?
    fileprivate struct Constants {
        static let topPadding: CGFloat = 20.0
        static let pageControlHeight: CGFloat = 40.0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        for ii in 1...5 {
            if let page = storyboard?.instantiateViewController(withIdentifier: "promo\(ii)") {
                pages.append(page)
            }
        }
        setViewControllers([pages[0]], direction: .forward, animated: false)
        view.backgroundColor = backgroundColor(for: 0)
        
        addPageControl()
    }
    
    func addPageControl() {
        let newControl = UIPageControl()
        
        view.addSubview(newControl)
        
        newControl.translatesAutoresizingMaskIntoConstraints = false
        newControl.topAnchor.constraint(equalTo: view.topAnchor, constant: Constants.topPadding).isActive = true
        newControl.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        newControl.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        newControl.heightAnchor.constraint(equalToConstant: Constants.pageControlHeight).isActive = true
        
        newControl.numberOfPages = pages.count
        pageControl = newControl
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
    @available(iOS 5.0, *)
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.index(of: viewController) else {
            return nil
        }
        if index > 0 {
            return pages[index - 1]
        }
        return nil
    }
    
    @available(iOS 5.0, *)
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
