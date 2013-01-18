// predefine target variables
var target = UIATarget;
var app = target.localTarget().frontMostApp();
var mainWindow = app.mainWindow();

target.localTarget().setTimeout(10);  // set timeout for waitForInvalid() to 10 seconds


function assertEquals(expected, received, message) {
    if (received != expected) {
        if (! message) message = "Expected " + expected + " but received " + received;
        throw message;
    }
}

function assertTrue(expression, message) {
    if (! expression) {
        if (! message) message = "Assertion failed";
        throw message;
    }
}

function assertFalse(expression, message) {
    assertTrue(! expression, message);
}

function assertNotNull(thing, message) {
    if (thing == null || thing.toString() == "[object UIAElementNil]") {
        if (message == null) message = "Expected not null object";
        throw message;
    }
}