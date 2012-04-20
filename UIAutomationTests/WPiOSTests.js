#import "./Config.js"
#import "./Blog.js"
#import "./Post.js"

// Blog Tests /////////////////
Blog.checkBlogsListView();  // should already have a test blog added to app
Blog.selectBlog(0);         // test blog should be first on list
Blog.checkBlogView();

// Post Tests /////////////////
Post.createNewPost();