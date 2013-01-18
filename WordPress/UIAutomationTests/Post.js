var Post = {
    createNewPost: function () {
        var testname = 'Create new post';
    
        UIALogger.logStart(testname);
    
        // recorded with instruments.  sometimes this tests cleanly but usually not.
        mainWindow.tableViews()["Empty list"].cells()["irbrad's testing grounds, irtesting.wordpress.com"].tap();
        app.navigationBar().rightButton().tap();
        mainWindow.textFields()[0].tap();
        app.keyboard().typeString("WPiOS Automated Test");
        mainWindow.textFields()[1].tap();
        app.keyboard().typeString("testing");
        mainWindow.tableViews()["Empty list"].tapWithOptions({tapOffset:{x:0.80, y:0.28}, tapCount:2});
        target.tap({x:229.00, y:96.50});
        app.navigationBar().leftButton().tap();
        mainWindow.textFields()[2].tap();
        app.keyboard().typeString("This is a test post from UIAutomation");
        app.windows()[1].buttons()["Done"].tap();
        app.navigationBar().rightButton().tap();
	
        UIALogger.logPass(testname);
    }
}
