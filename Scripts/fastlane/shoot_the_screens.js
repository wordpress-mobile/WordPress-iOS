var target = UIATarget.localTarget();
var app = target.frontMostApp();
var win = app.mainWindow();
var model = target.model();

var type = function(text) {
    app.keyboard().typeString(text);
}
var sleep = function(duration) {
    target.delay(duration);
}

var kPortraitString = "portrait"
var kLandscapeString = "landscape"

var kMaxDimension4inch = 568;
var kMaxDimension4point7inch = 667;
var kMaxDimension5point5inch = 736;

function rectMaxSizeMatchesPhoneWithMaxDimensionForOrientation(rect, maxDimension, orientation) {
    return (orientation == kPortraitString && rect.size.height == maxDimension) || (orientation == kLandscapeString && rect.size.width == maxDimension)
}

function captureLocalizedScreenshot(name) {
    var target = UIATarget.localTarget();
    var model = target.model();
    var rect = target.rect();
    
    var orientation = kPortraitString;
    if (rect.size.height < rect.size.width) {
        orientation = kLandscapeString;
    }
    
    if (model.match(/iPhone/)) {
        if (rectMaxSizeMatchesPhoneWithMaxDimensionForOrientation(rect, kMaxDimension4inch, orientation)) {
            model = "iOS-4-in";
        }
        else if (rectMaxSizeMatchesPhoneWithMaxDimensionForOrientation(rect, kMaxDimension4point7inch, orientation)) {
            model = "iOS-4.7-in";
        }
        else if (rectMaxSizeMatchesPhoneWithMaxDimensionForOrientation(rect, kMaxDimension5point5inch, orientation)) {
            model = "iOS-5.5-in";
        }
        else {
            model = "iOS-3.5-in";
        }
    } else {
        model = "iOS-iPad";
    }
    
    var parts = [model, orientation, name];
    target.captureScreenWithName(parts.join("___"));
}

function isIpad() {
    return model.match(/iPad/);
}

function dismissNewEditorModalIfApplicable() {
    var newEditorButton = win.buttons()["new-editor-modal-dismiss-button"];
    if (newEditorButton.isValid()) {
        newEditorButton.tap();
        sleep(1);
    } 
}

UIALogger.logStart("screenshots");

dismissNewEditorModalIfApplicable();

if (app.tabBar().checkIsValid()) {
    app.tabBar().buttons()[3].tap();
    sleep(5);
    
    target.frontMostApp().mainWindow().tableViews()[0].cells()[2].scrollToVisible(); sleep(2);
    target.frontMostApp().mainWindow().tableViews()[0].cells()[2].tap();        
    
    sleep(5);
    
    if (model.match(/iPhone/)) {
        app.actionSheet().elements()[2].cells()[0].buttons()[0].tap();
    } else {
        target.frontMostApp().mainWindow().popover().actionSheet().collectionViews()[0].cells()[0].buttons()[0].tap();
        
    }
}
sleep(2);

UIALogger.logMessage("Starting Sign In Process");

var username = "FILL-IN-USERNAME";
var password = "FILL-IN-PASSWORD";

win.textFields()[0].tap(); sleep(1);
win.textFields()[0].setValue(username); sleep(1);
win.secureTextFields()[0].tap();sleep(1);
win.secureTextFields()[0].setValue(password);
win.textFields()[0].tap(); sleep(1);
win.buttons()[1].tap();

// Wait for "Brand New Editor" dialog
sleep(5);
dismissNewEditorModalIfApplicable();

sleep(5);
target.frontMostApp().tabBar().buttons()[1].tap(); sleep(3);
if (isIpad()) {
    target.frontMostApp().navigationBar().buttons()[1].tap(); sleep(2);
} else {
    app.navigationBar().buttons()[0].tap(); sleep(2); sleep(2);    
}

target.frontMostApp().mainWindow().elements()["Pager View"].scrollViews()[0].tableViews()[0].cells()[0].tap(); sleep(5);
captureLocalizedScreenshot("1-reader");

target.frontMostApp().tabBar().buttons()[4].tap(); sleep(5);
captureLocalizedScreenshot("2-notifications");

target.frontMostApp().tabBar().buttons()[0].tap(); sleep(2);
target.frontMostApp().mainWindow().tableViews()[0].cells()[2].tap(); sleep(5);
captureLocalizedScreenshot("3-posts");

target.frontMostApp().mainWindow().tableViews()["PostsTable"].visibleCells()[0].tap(); sleep(3);
target.frontMostApp().navigationBar().rightButton().tap(); sleep(2);
if (isIpad()) {
    target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].textFields()[1].tapWithOptions({tapOffset:{x:0.95, y:0.04}}); sleep(1);    
} else {
    target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].textFields()[1].tapWithOptions({tapOffset:{x:0.95, y:0.10}}); sleep(1);        
}
captureLocalizedScreenshot("4-post-editor");

target.frontMostApp().navigationBar().buttons()[0].tap(); sleep(2);
if (isIpad()) {
    target.frontMostApp().mainWindow().popover().actionSheet().collectionViews()[0].cells()[0].buttons()[0].tap();
} else {
    target.frontMostApp().actionSheet().collectionViews()[0].cells()[0].buttons()[0].tap();
}

target.frontMostApp().navigationBar().buttons()[0].tap(); sleep(2);
target.frontMostApp().navigationBar().leftButton().tap(); sleep(2);
target.frontMostApp().mainWindow().tableViews()[0].cells()[1].tap(); sleep(5);
captureLocalizedScreenshot("5-stats");

UIALogger.logPass("screenshots");


