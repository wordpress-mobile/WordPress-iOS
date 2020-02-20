import Foundation
import Gridicons

class PageListTableViewCell: BasePageListCell {
//    static CGFloat const PageListTableViewCellTagLabelRadius = 2.0;
//    static CGFloat const FeaturedImageSize = 120.0;
    private static let pageListTableViewCellTagLabelRadius = CGFloat(2)
    private static let featuredImageSize = CGFloat(120)
    
//    @property (nonatomic, strong) IBOutlet UILabel *titleLabel;
//    @property (nonatomic, strong) IBOutlet UILabel *timestampLabel;
//    @property (nonatomic, strong) IBOutlet UILabel *badgesLabel;
//    @property (strong, nonatomic) IBOutlet CachedAnimatedImageView *featuredImageView;
//    @property (nonatomic, strong) IBOutlet UIButton *menuButton;
//    @property (nonatomic, strong) IBOutlet NSLayoutConstraint *labelsContainerTrailing;
//    @property (nonatomic, strong) IBOutlet NSLayoutConstraint *leadingContentConstraint;
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var timestampLabel: UILabel!
    @IBOutlet private var badgesLabel: UILabel!
    @IBOutlet private var featuredImageView: CachedAnimatedImageView!
    @IBOutlet private var menuButton: UIButton!
    @IBOutlet private var labelsContainerTrailing: NSLayoutConstraint!
    @IBOutlet private var leadingContentConstraint: NSLayoutConstraint!
    
//    @property (nonatomic, strong) ImageLoader *featuredImageLoader;
//    @property (nonatomic, strong) NSDateFormatter *dateFormatter;
    private lazy var featuredImageLoader: ImageLoader = {
//        - (ImageLoader *)featuredImageLoader
//        {
//            if (_featuredImageLoader == nil) {
//                _featuredImageLoader = [[ImageLoader alloc] initWithImageView:self.featuredImageView
//                                                                  gifStrategy:GIFStrategyLargeGIFs];
//            }
//            return _featuredImageLoader;
//        }
        return ImageLoader(imageView: self.featuredImageView, gifStrategy: .largeGIFs)
    }()
    private lazy var dateFormatter: DateFormatter = {
//         - (NSDateFormatter *)dateFormatter
//         {
//             if (_dateFormatter == nil) {
//                 _dateFormatter = [NSDateFormatter new];
//                 _dateFormatter.doesRelativeDateFormatting = YES;
//                 _dateFormatter.dateStyle = NSDateFormatterNoStyle;
//                 _dateFormatter.timeStyle = NSDateFormatterShortStyle;
//             }
//             return _dateFormatter;
//         }
        let dateFormatter = DateFormatter()
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        
        return dateFormatter
    }()

//    CGFloat _indentationWidth;
//    NSInteger _indentationLevel;
    private var privateIndentationWidth: CGFloat = 0
    private var privateIndentationLevel: Int = 0
    
    override var indentationWidth: CGFloat {
        get {
//            - (CGFloat)indentationWidth
//            {
//                return _indentationWidth;
//            }
            return privateIndentationWidth
        }
        
        set {
//            - (void)setIndentationWidth:(CGFloat)indentationWidth
//            {
//                _indentationWidth = indentationWidth;
//                [self updateLeadingContentConstraint];
//            }
            privateIndentationWidth = newValue
            updateLeadingContentConstraint()
        }
    }

    override var indentationLevel: Int {
        get {
//            - (NSInteger)indentationLevel
//            {
//                return _indentationLevel;
//            }
            return privateIndentationLevel
        }
        
        set {
//            - (void)setIndentationLevel:(NSInteger)indentationLevel
//            {
//                _indentationLevel = indentationLevel;
//                [self updateLeadingContentConstraint];
//            }
            privateIndentationLevel = newValue
            updateLeadingContentConstraint()
        }
    }
    
//    - (void)awakeFromNib
//    {
//        [super awakeFromNib];
//
//        [self applyStyles];
//        [self setupAccessibility];
//    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyStyles()
        setupAccessibility()
    }
    
//    - (void)prepareForReuse
//    {
//        [super prepareForReuse];
//
//        [self applyStyles];
//        [self.featuredImageLoader prepareForReuse];
//        [self setNeedsDisplay];
//    }
    override func prepareForReuse() {
        super.prepareForReuse()
        
        applyStyles()
        featuredImageLoader.prepareForReuse()
        setNeedsDisplay()
    }
    
    override var post: AbstractPost? {
        get {
            return super.post
        }
        
        set {
//            - (void)setPost:(AbstractPost *)post
//            {
//                [super setPost:post];
//                [self configureTitle];
//                [self configureForStatus];
//                [self configureBadges];
//                [self configureFeaturedImage];
//                self.accessibilityIdentifier = post.slugForDisplay;
//            }
            super.post = newValue
            configureTitle()
            configureForStatus()
            configureBadges()
            configureFeaturedImage()
            accessibilityIdentifier = post?.slugForDisplay()
        }
    }
    
    // MARK: - Configuration
    
//    - (void)applyStyles
//    {
//        [WPStyleGuide configureTableViewCell:self];
//        [WPStyleGuide configureLabel:self.timestampLabel textStyle:UIFontTextStyleSubheadline];
//        [WPStyleGuide configureLabel:self.badgesLabel textStyle:UIFontTextStyleSubheadline];
//
//        self.titleLabel.font = [WPStyleGuide notoBoldFontForTextStyle:UIFontTextStyleHeadline];
//        self.titleLabel.adjustsFontForContentSizeCategory = YES;
//
//        self.titleLabel.textColor = [UIColor murielText];
//        self.badgesLabel.textColor = [UIColor murielTextSubtle];
//        self.menuButton.tintColor = [UIColor murielTextSubtle];
//        [self.menuButton setImage:[Gridicon iconOfType:GridiconTypeEllipsis] forState:UIControlStateNormal];
//
//        self.backgroundColor = [UIColor murielNeutral5];
//        self.contentView.backgroundColor = [UIColor murielNeutral5];
//
//        self.featuredImageView.layer.cornerRadius = PageListTableViewCellTagLabelRadius;
//    }
    private func applyStyles() {
        WPStyleGuide.configureTableViewCell(self)
        
        // The next line was disabled as it was crashing.  The weird thing is that the outlet
        // isn't wired in develop but is only crashing after this migration.
        //
        // This has been left here to make the reviewer's job easier, and will be removed before
        // merging this code.
        //
        //WPStyleGuide.configureLabel(timestampLabel, textStyle: .subheadline)
        WPStyleGuide.configureLabel(badgesLabel, textStyle: .subheadline)
        
        titleLabel.font = WPStyleGuide.notoBoldFontForTextStyle(.headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        
        titleLabel.textColor = .text
        badgesLabel.textColor = .textSubtle
        menuButton.tintColor = .textSubtle
        menuButton.setImage(Gridicon.iconOfType(.ellipsis), for: .normal)
        
        backgroundColor = UIColor.neutral(.shade5)
        contentView.backgroundColor = .neutral(.shade5)
        
        featuredImageView.layer.cornerRadius = PageListTableViewCell.pageListTableViewCellTagLabelRadius
    }
    
//    - (void)configureTitle
//    {
//        AbstractPost *post = [self.post hasRevision] ? [self.post revision] : self.post;
//        self.titleLabel.text = [post titleForDisplay] ?: [NSString string];
//    }
    private func configureTitle() {
        let postForTitle = self.post?.hasRevision() == true ? self.post?.revision : self.post
        titleLabel.text = postForTitle?.titleForDisplay() ?? ""
    }
    
//    - (void)configureForStatus
//    {
//        if (self.post.isFailed && !self.post.hasLocalChanges) {
//            self.titleLabel.textColor = [UIColor murielError];
//            self.menuButton.tintColor = [UIColor murielError];
//        }
//    }
    private func configureForStatus() {
        guard let post = post else {
            return
        }
        
        if post.isFailed && !post.hasLocalChanges() {
            titleLabel.textColor = .error
            menuButton.tintColor = .error
        }
    }
    
//    - (void)updateLeadingContentConstraint
//    {
//        self.leadingContentConstraint.constant = (CGFloat)_indentationLevel * _indentationWidth;
//    }
    private func updateLeadingContentConstraint() {
        leadingContentConstraint.constant = CGFloat(indentationLevel) * indentationWidth
    }
    
//    - (void)configureBadges
//    {
//        Page *page = (Page *)self.post;
//
//        NSMutableArray<NSString *> *badges = [NSMutableArray new];
//
//        NSString *timestamp = [self.post isScheduled] ? [self.dateFormatter stringFromDate:self.post.dateCreated] : [self.post.dateCreated mediumString];
//        [badges addObject:timestamp];
//
//        if (page.hasPrivateState) {
//            [badges addObject:NSLocalizedString(@"Private", @"Title of the Private Badge")];
//        } else if (page.hasPendingReviewState) {
//            [badges addObject:NSLocalizedString(@"Pending review", @"Title of the Pending Review Badge")];
//        }
//
//        if (page.hasLocalChanges) {
//            [badges addObject:NSLocalizedString(@"Local changes", @"Title of the Local Changes Badge")];
//        }
//
//        self.badgesLabel.text = [badges componentsJoinedByString:@" · "];
//    }
    private func configureBadges() {
        guard let page = self.post as? Page else {
            return
        }
        
        var badges = [String]()
        
        if let dateCreated = page.dateCreated {
            let timeStamp = page.isScheduled() ? dateFormatter.string(from: dateCreated) : dateCreated.mediumString()
            badges.append(timeStamp)
        }
        
        if page.hasPrivateState {
            badges.append(NSLocalizedString("Private", comment: "Title of the Private Badge"))
        } else if page.hasPendingReviewState {
            badges.append(NSLocalizedString("Pending review", comment: "Title of the Pending Review Badge"))
        }
        
        if page.hasLocalChanges() {
            badges.append(NSLocalizedString("Local changes", comment: "Title of the Local Changes Badge"))
        }
        
        badgesLabel.text = badges.joined(separator: " · ")
    }
    
//    - (void)configureFeaturedImage
//    {
//        Page *page = (Page *)self.post;
//
//        BOOL hideFeaturedImage = page.featuredImage == nil;
//        self.featuredImageView.hidden = hideFeaturedImage;
//        self.labelsContainerTrailing.active = !hideFeaturedImage;
//
//        if (!hideFeaturedImage) {
//            [self.featuredImageLoader loadImageFromMedia:page.featuredImage
//                                           preferredSize:CGSizeMake(FeaturedImageSize, FeaturedImageSize)
//                                             placeholder:nil
//                                                 success:nil
//                                                   error:^(NSError *error) {
//                                                       DDLogError(@"Failed to load the media: %@", error);
//                                                   }];
//
//        }
//    }
    private func configureFeaturedImage() {
        guard let page = post as? Page else {
            return
        }
        
        let hideFeaturedImage = page.featuredImage == nil
        featuredImageView.isHidden = hideFeaturedImage
        labelsContainerTrailing.isActive = !hideFeaturedImage
        
        if !hideFeaturedImage,
            let media = page.featuredImage {
            
            featuredImageLoader.loadImage(media: media,
                                          preferredSize: CGSize(
                                            width: PageListTableViewCell.featuredImageSize,
                                            height: PageListTableViewCell.featuredImageSize),
                                          placeholder: nil,
                                          success: nil) { error in
                                            DDLogError("Failed to load the media: %@", level: .error);
            }
        }
    }
    
//    - (void)setupAccessibility {
//        self.menuButton.accessibilityLabel = NSLocalizedString(@"More", @"Accessibility label for the More button in Page List.");
//    }
    private func setupAccessibility() {
        menuButton.accessibilityLabel = NSLocalizedString("More", comment: "Accessibility label for the More button in Page List.")
    }
}
