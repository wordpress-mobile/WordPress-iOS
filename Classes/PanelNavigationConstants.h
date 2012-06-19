//
//  PanelNavigationConstants.h
//  WordPress
//
//  Created by Danilo Ercoli on 06/06/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#ifndef IS_IPAD
#define IS_IPAD   ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#endif
#ifndef IS_IPHONE
#define IS_IPHONE   (!IS_IPAD)
#endif

// Visible part of the detail view on iPhone when sidebar is open
// Also used as minimum part visible of sidebar when closed on iPad (see: IPAD_DETAIL_OFFSET)
#define DETAIL_LEDGE 44.0f
#define SIDEBAR_WIDTH 320.0f

#define IPAD_WIDE_PANEL_WIDTH (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? IPAD_WIDE_PANEL_WIDTH_PORTRAIT : IPAD_WIDE_PANEL_WIDTH_LANDSCAPE )
#define IPAD_WIDE_PANEL_WIDTH_PORTRAIT 680.0f
#define IPAD_WIDE_PANEL_WIDTH_LANDSCAPE 704.0f

// Maximum x position for detail view
#define DETAIL_LEDGE_OFFSET (IS_IPAD ? SIDEBAR_WIDTH : (SIDEBAR_WIDTH - DETAIL_LEDGE))

#define PANEL_CORNER_RADIUS 7.0f
#define DURATION_FAST 0.3
#define DURATION_SLOW 0.3
#define SLIDE_DURATION(animated,duration) ((animated) ? (duration) : 0)
#define OPEN_SLIDE_DURATION(animated) SLIDE_DURATION(animated,DURATION_FAST)
#define CLOSE_SLIDE_DURATION(animated) SLIDE_DURATION(animated,DURATION_SLOW)

// On iPhone, sidebar can be fully closed
#define IPHONE_DETAIL_OFFSET 0
#define IPHONE_DETAIL_HEIGHT self.view.bounds.size.height
#define IPHONE_DETAIL_WIDTH self.view.bounds.size.width

// On iPad, always show part of the sidebar
#define IPAD_DETAIL_OFFSET DETAIL_LEDGE
#define IPAD_DETAIL_HEIGHT IPHONE_DETAIL_HEIGHT

// Fits two regular size panels with the sidebar collapsed
#define IPAD_DETAIL_WIDTH_LANDSCAPE ((self.view.bounds.size.width - DETAIL_LEDGE) / 2)
#define IPAD_DETAIL_WIDTH_PORTRAIT (self.view.bounds.size.width - SIDEBAR_WIDTH)
#define IPAD_DETAIL_WIDTH (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? IPAD_DETAIL_WIDTH_PORTRAIT : IPAD_DETAIL_WIDTH_LANDSCAPE)

// Minimum x position for detail view
#define DETAIL_OFFSET (IS_IPAD ? IPAD_DETAIL_OFFSET : IPHONE_DETAIL_OFFSET)
//#define DETAIL_OFFSET (IS_IPAD ? (self.hasWidePanel ? self.view.frame.size.width - IPAD_WIDE_PANEL_WIDTH : IPAD_DETAIL_OFFSET ) : IPHONE_DETAIL_OFFSET)
#define DETAIL_HEIGHT (IS_IPAD ? IPAD_DETAIL_HEIGHT : IPHONE_DETAIL_HEIGHT)
#define DETAIL_WIDTH (IS_IPAD ? IPAD_DETAIL_WIDTH : IPHONE_DETAIL_WIDTH)