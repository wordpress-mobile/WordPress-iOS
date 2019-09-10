//
//  ExpandableInputAccessoryView.swift
//  WordPress
//
//  Created by Nathan Glass on 8/25/19.
//  Copyright © 2019 WordPress. All rights reserved.
//

import Foundation
import UIKit

struct TextViewConstraintStore {
    var leading: CGFloat
    var trailing: CGFloat
    var top: CGFloat
}


@objc class ProgrammaticExpandableInputAccessoryView: UIView, ExpandableInputAccessoryViewDelegate {
    
    let expandableInputAccessoryView = ExpandableInputAccessoryView.loadFromNib()
    var topConstraint: NSLayoutConstraint?
//    var heightConstraint: NSLayoutConstraint?
    
    @objc init(parentDelegate: ExpandableInputAccessoryViewParentDelegate) {
        super.init(frame: CGRect.zero)
        backgroundColor = .blue
        expandableInputAccessoryView.translatesAutoresizingMaskIntoConstraints = false
        expandableInputAccessoryView.delegate = self
        expandableInputAccessoryView.parentDelegate = parentDelegate
        self.addSubview(expandableInputAccessoryView)
        
        self.autoresizingMask = .flexibleHeight
        
        NSLayoutConstraint(item: expandableInputAccessoryView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: expandableInputAccessoryView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: expandableInputAccessoryView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: expandableInputAccessoryView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
    
    func didMoveTo(_ state: ExpandableInputAccessoryView.ExpandedState) {
        switch state {
        case .fullScreen:
//            if self.heightConstraint == nil {
//                self.heightConstraint = self.heightAnchor.constraint(equalToConstant: 300)
//            }
//            heightConstraint?.isActive = true
            if topConstraint == nil {
                topConstraint = self.topAnchor.constraint(equalTo: self.window!.safeAreaLayoutGuide.topAnchor)
            }
            topConstraint?.isActive = true
        case .normal:
//            heightConstraint?.isActive = false
            topConstraint?.isActive = false
        }
    }
    
    @objc func resignResponder() {
        expandableInputAccessoryView.textView.resignFirstResponder()
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: self.bounds.width, height: expandableInputAccessoryView.intrinsicContentSize.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

protocol ExpandableInputAccessoryViewDelegate: class {
    func didMoveTo(_ state: ExpandableInputAccessoryView.ExpandedState)
}

@objc protocol ExpandableInputAccessoryViewParentDelegate: class {
    func expandableInputAccessoryViewDidBeginEditing()
}

class ExpandableInputAccessoryView: UIView, UITextViewDelegate, NibLoadable {
    
    enum ExpandedState {
        case fullScreen
        case normal
    }
    
    @IBOutlet weak var dividerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var placeholerLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.delegate = self
        }
    }
    weak var delegate: ExpandableInputAccessoryViewDelegate?
    weak var parentDelegate: ExpandableInputAccessoryViewParentDelegate?
    var isExpanded = false
    var explicityCollapsed = false
    var wasAutomatticallyExpanded = false
    var topConstraint: NSLayoutConstraint?
    let expandedTextViewConstraints = TextViewConstraintStore(leading: 10.0, trailing: 4.0, top: 50.0)
    var collapsedTextViewConstraints = TextViewConstraintStore(leading: 45.0, trailing: 60.0, top: 6.0)
    private let sendButtonDisabledTintColor = UIColor(red: 150/255, green: 156/255, blue: 161/255, alpha: 1.0)
    private let sendButtonEnabledTintColor = UIColor(red: 213/255, green: 44/255, blue: 130/255, alpha: 1.0)
    private let expandButtonCollapsedTransform = CGAffineTransform(rotationAngle: CGFloat.pi)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.autoresizingMask = .flexibleHeight
        
        self.headerLabel.alpha = 0
        self.sendButton.tintColor = sendButtonDisabledTintColor
        expandButton.transform = expandButtonCollapsedTransform
    }
    
    @IBAction func expandButtonTapped(_ sender: UIButton) {
        if !isExpanded {
            expandToFullScreen()
        } else {
            collapseTextView()
        }
    }

    override var canBecomeFirstResponder: Bool { return true }
    
    fileprivate func expandToFullScreen(automatically: Bool = false) {
        isExpanded = true
        wasAutomatticallyExpanded = automatically
        delegate?.didMoveTo(.fullScreen)
        if topConstraint == nil {
//            topConstraint = self.topAnchor.constraint(equalTo: self.window!.safeAreaLayoutGuide.topAnchor)
        }
        UIView.animate(withDuration: 0.2) {
//            self.topConstraint?.isActive = true
            self.textViewTrailingConstraint.constant = self.expandedTextViewConstraints.trailing
            self.textViewLeadingConstraint.constant = self.expandedTextViewConstraints.leading
            self.textViewTopConstraint.constant = self.expandedTextViewConstraints.top
            self.dividerViewTopConstraint.constant = 44.0
            self.headerLabel.alpha = 1
            self.expandButton.transform = .identity
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }
    }
    
    fileprivate func collapseTextView() {
        isExpanded = false
        if wasAutomatticallyExpanded {
            explicityCollapsed = true
        }
        delegate?.didMoveTo(.normal)
        UIView.animate(withDuration: 0.2) {
            self.topConstraint?.isActive = false
            self.topAnchor.constraint(equalTo: self.window!.safeAreaLayoutGuide.topAnchor).isActive = false
            self.textViewTrailingConstraint.constant = self.collapsedTextViewConstraints.trailing
            self.textViewLeadingConstraint.constant = self.collapsedTextViewConstraints.leading
            self.textViewTopConstraint.constant = self.collapsedTextViewConstraints.top
            self.dividerViewTopConstraint.constant = 0
            self.headerLabel.alpha = 0
            self.expandButton.transform = self.expandButtonCollapsedTransform
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let textSize = self.textView.sizeThatFits(CGSize(width: self.textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        return CGSize(width: self.bounds.width, height: textSize.height)
    }
    
    // MARK: TextView delegates
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        parentDelegate?.expandableInputAccessoryViewDidBeginEditing()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // Re-calculate intrinsicContentSize when text changes
        placeholerLabel.isHidden = !textView.text.isEmpty
        sendButton.tintColor = textView.text.isEmpty ? sendButtonDisabledTintColor : sendButtonEnabledTintColor

        if let fontLineHeight = self.textView.font?.lineHeight {
            let numLines = Int(self.textView.contentSize.height / fontLineHeight)
            if numLines > 4 && !self.isExpanded && !explicityCollapsed {
                self.expandToFullScreen(automatically: true)
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.invalidateIntrinsicContentSize()
                    self.superview?.setNeedsLayout()
                    self.superview?.layoutIfNeeded()
                }
                
            }
        }
    }
}
