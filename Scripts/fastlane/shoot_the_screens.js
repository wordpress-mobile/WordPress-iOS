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
    win.tableViews()[0].cells()[2].tap();
    
    if (model.match(/iPhone/)) {
        app.actionSheet().elements()[1].tap();
    } else {
        win.popover().actionSheet().elements()[1].tap();
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

app.tabBar().buttons()[1].tap();
if (isIpad()) {
    app.navigationBar().buttons()[1].tap();    
} else {
    app.navigationBar().buttons()[0].tap();    
}

win.elements()["Pager View"].scrollViews()[0].tableViews()[0].cells()[0].tap(); sleep(5);

UIALogger.logMessage("Capture Reader Screenshot");
captureLocalizedScreenshot("1-reader"); sleep(1);

// Get Notifications Screenshot
app.tabBar().buttons()[4].tap(); sleep(3);
UIALogger.logMessage("Capture Notifications Screenshot");
captureLocalizedScreenshot("2-notifications"); sleep(1);

// Get My Sites Screenshot
app.tabBar().buttons()[0].tap(); sleep(1);
UIALogger.logMessage("Capture My Sites");
var blogsTableView = win.tableViews()["Blogs"];
if (blogsTableView.isValid()) {
    blogsTableView.cells()[0].tap();
}
sleep(1);
UIALogger.logMessage("Capture My Sites Screenshot");
captureLocalizedScreenshot("3-my-sites"); sleep(1);    

// Get Editor Screenshot
win.tableViews()[0].cells()[2].tap(); sleep(1);
win.tableViews()[0].visibleCells()[2].tap(); sleep(1)
app.navigationBar().rightButton().tap(); sleep(2);
// Get the cursor to the end of the text before the image
if (isIpad()) {
    target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].textFields()[1].tapWithOptions({tapOffset:{x:0.95, y:0.04}}); sleep(1);    
} else {
    target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].textFields()[1].tapWithOptions({tapOffset:{x:0.95, y:0.10}}); sleep(1);        
}

target.frontMostApp().mainWindow().scrollViews()[0].webViews()[0].textFields()[1].scrollUp(); sleep(1);
UIALogger.logMessage("Capture Editor Screenshot");
captureLocalizedScreenshot("4-editor"); sleep(1);

// Get Stats Screenshot
target.frontMostApp().navigationBar().buttons()[0].tap(); sleep(1);
if (isIpad()) {
    if (app.popover().isValid()) {
        win.popover().actionSheet().collectionViews()[0].cells()[0].buttons()[0].tap(); sleep(1);
    }
    app.navigationBar().buttons()[2].tap(); sleep(1);        
} else {
    if (app.actionSheet().isValid()) {
        app.actionSheet().elements()[1].tap(); sleep(1);        
    }
    app.navigationBar().buttons()[0].tap(); sleep(1);    
}

// Load Stats
target.frontMostApp().navigationBar().buttons()[0].tap(); sleep(1);
win.tableViews()[0].visibleCells()[1].tap(); sleep(10);
UIALogger.logMessage("Capture Stats Screenshot");
captureLocalizedScreenshot("5-stats"); sleep(1);

UIALogger.logPass("screenshots");



