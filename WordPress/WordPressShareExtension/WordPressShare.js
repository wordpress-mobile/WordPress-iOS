var WordPressShare = function() {};

WordPressShare.prototype = {
    title: function() {
        return document.title;
    },

    description: function() {
        var description = document.getElementsByName("description")[0];
        if (description == null) {
            return "";
        }
        return description.content;
    },

    selection: function() {
        return window.getSelection().toString();
    },

    result: function() {
        return {
            "title": this.title(),
            "description": this.description(),
            "selection": this.selection(),
            "url": document.baseURI
        }
    },

    run: function(arguments) {
        arguments.completionFunction(this.result());
    }
};

var ExtensionPreprocessingJS = new WordPressShare;
