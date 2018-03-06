import Foundation

let ProfileHeaderViewHeight = 126;
let ProfileHeaderViewGravatarSize = 64.0;
let ProfileHeaderViewButtonHeight = 32.0;
let ProfileHeaderViewVerticalMargin = 20.0;
let ProfileHeaderViewVerticalSpacing = 10.0;

class MyProfileHeaderView: UIView {
    var gravatarImageView: UIImageView?
    var gravatarButton: UIButton?
    
    convenience init() {
        let rect = CGRect(x: 0, y: 0, width: 0, height: ProfileHeaderViewHeight)
        self.init(frame: rect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gravatarImageView = newImageViewForGravatar()
        if let imageView = gravatarImageView {
            addSubview(imageView)
        }
        
        gravatarButton = newButtonForGravatar()
        if let button = gravatarButton {
            addSubview(button)
        }
        
        configureConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    func newImageViewForGravatar() -> UIImageView? {
        let gravatarFrame = CGRect(x: 0.0, y: 0.0, width: ProfileHeaderViewGravatarSize, height: ProfileHeaderViewGravatarSize)
        let imageView = UIImageView(frame: gravatarFrame)
        imageView.layer.cornerRadius = CGFloat(ProfileHeaderViewGravatarSize * 0.5)
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        return imageView
    }
    
    func newButtonForGravatar() -> UIButton? {
        let button = UIButton(frame: CGRect.zero)
        button.setTitleColor(WPStyleGuide.wordPressBlue(), for: .normal)
        button.titleLabel?.font = WPStyleGuide.tableviewTextFont()
        button.titleLabel?.textAlignment = .center
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = true
        return button
    }
    
    func configureConstraints() {
        let views: [String: Any] = ["gravatarImageView": gravatarImageView, "gravatarButton": gravatarButton]
        let metrics = ["gravatarSize": ProfileHeaderViewGravatarSize, "buttonHeight": ProfileHeaderViewButtonHeight, "verticalSpacing": ProfileHeaderViewVerticalSpacing, "verticalMargin": ProfileHeaderViewVerticalMargin]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-verticalMargin-[gravatarImageView(gravatarSize)]-verticalSpacing-[gravatarButton(buttonHeight)]-|", options: [], metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[gravatarImageView(gravatarSize)]", options: [], metrics: metrics, views: views))
        addConstraint(NSLayoutConstraint(item: gravatarImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: gravatarButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        super.setNeedsUpdateConstraints()
    }
}
