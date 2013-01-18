var Blog = {
    checkBlogsListView: function () {
        var test = 'Check initial screen after launch';
        UIALogger.logStart(test);
        
        // check navigation bar
        navBar = mainWindow.navigationBar();
        assertEquals("Blogs", navBar.name());
        assertEquals("Edit", navBar.leftButton().name());
        assertEquals("Add", navBar.rightButton().name());
        
        // check table
        assertNotNull(mainWindow.tableViews()["Blog List"]);

        UIALogger.logPass(test);
    },
    
    selectBlog: function (pos) {
        var test = 'Select specific blog';
        UIALogger.logStart(test);

        table = mainWindow.tableViews()["Blog List"];
        
        table.cells()[pos].tap();
        table.cells()[pos].waitForInvalid();
        
        UIALogger.logPass(test);
    },
    
    checkBlogView: function () {
        var test = 'Check layout of blog view';
        UIALogger.logStart(test);

        tabBar = mainWindow.tabBar();

        ["Posts", "Pages", "Comments", "Stats"].forEach(function(i,e) {
                                                        Blog.tapTab(e);                                
                     });
        
        UIALogger.logPass(test);        
    },
    
    tapTab: function (pos) {
        var test = 'Tap ' + pos + ' tab';
        UIALogger.logStart(test);
        UIALogger.
        tabBar = mainWindow.tabBar();
        tabBar.buttons()[pos].tap();
        tabBar.buttons()[pos].waitForInvalid();
        
        UIALogger.logPass(test);
    },
    
    checkBlogPostsView: function () {
        var test = 'Check the layout of the blog posts view';
        UIALogger.logStart(test);

        // check selected tab
        tabBar = mainWindow.tabBar();
        assertEquals("Posts", tabBar.selectedButton().name());
                
        // check table
        table = mainWindow.tableViews()[0];
        tableGroup = table.groups()[0];
        assertEquals("Posts", tableGroup.name());
        
        UIALogger.logPass(test);        
    },

    checkBlogPagesView: function () {
        var test = 'Check the layout of the blog pages view';
        UIALogger.logStart(test);

        // check selected tab
        tabBar = mainWindow.tabBar();
        assertEquals("Pages", tabBar.selectedButton().name());
        
        // check table
        table = mainWindow.tableViews()[0];
        tableGroup = table.groups()[0];
        assertEquals("Pages", tableGroup.name());
        
        UIALogger.logPass(test);                
    },
    
    checkBlogCommentsView: function () {
        var test = 'Check the layout of the blog comments view';
        UIALogger.logStart(test);
        
        tabBar = mainWindow.tabBar();
        assertEquals("Comments", tabBar.selectedButton().name());
        
        UIALogger.logPass(test);        
    },
    
    checkBlogStatsView: function () {
        var test = 'Check the layout of the blog stats view';
        UIALogger.logStart(test);
        
        tabBar = mainWindow.tabBar();
        assertEquals("Stats", tabBar.selectedButton().name());
        
        UIALogger.logPass(test);
    },
}
