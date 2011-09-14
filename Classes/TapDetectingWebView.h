//
//  TapDetectingWindow.h
//  WordPress
//
//  Created by Danilo Ercoli on 13/09/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TapDetectingWebViewDelegate
- (void)userDidTapWebView:(id)tapPoint;
@end


@interface TapDetectingWebView : UIWebView {
    id <TapDetectingWebViewDelegate> controllerThatObserves;
}
@property (nonatomic, assign) id <TapDetectingWebViewDelegate> controllerThatObserves;
//@property (retain, nonatomic) NSTimer *timer;
@end