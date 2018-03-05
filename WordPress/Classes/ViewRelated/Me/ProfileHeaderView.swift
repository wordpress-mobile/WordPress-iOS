import Foundation

let ProfileHeaderViewHeight = 154;
let ProfileHeaderViewGravatarSize = 64.0;
let ProfileHeaderViewButtonHeight = 20.0;
let ProfileHeaderViewVerticalMargin = 20.0;
let ProfileHeaderViewVerticalSpacing = 10.0;

class ProfileHeaderView: UIView {
    var gravatarImageView: UIImageView?
    var gravatarButton: UIButton?
    
    convenience init() {
        let rect = CGRect(x: 0, y: 0, width: 0, height: ProfileHeaderViewHeight)
        self.init(frame: rect)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        gravatarImageView = newImageViewForGravatar()
        addSubview(gravatarImageView)
        gravatarButton = newButtonForGravatar()
        addSubview(gravatarButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }
    
    func newImageViewForGravatar() -> UIImageView {
        
    }
    
    func newButtonForGravatar() -> UIButton {
        
    }
}
