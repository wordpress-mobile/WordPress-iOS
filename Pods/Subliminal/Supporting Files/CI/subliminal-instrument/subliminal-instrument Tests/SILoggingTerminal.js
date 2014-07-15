//
//  SILoggingTerminal.js
//  subliminal-instrument
//
//  For details and documentation:
//  http://github.com/inkling/Subliminal
//
//  Copyright 2014 Inkling Systems, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

/**
 This `UIALogger` is a mock version of the `UIALogger` class that is part of
 the UIAutomation framework. It is designed to format messages as the real
 `UIALogger` does and then return the formatted messages to its caller.
 */
UIALogger = {
	_timestamp: function() {
		// A sample timestamp of the form logged by UIAutomation.
		return "2014-01-16 00:00:23 +0000";
	},

	_primitiveLog: function(messageType, message) {
		return this._timestamp() + " " + messageType + ": " + message;
	},

	logDebug: function(message) {
		return this._primitiveLog("Debug", message);
	},

	logError: function(message) {
		return this._primitiveLog("Error", message);
	},

	logMessage: function(message) {
		return this._primitiveLog("Default", message);
	},

	logWarning: function(message) {
		return this._primitiveLog("Warning", message);
	},

	logFail: function(message) {
		return this._primitiveLog("Fail", message);
	},

	logIssue: function(message) {
		return this._primitiveLog("Issue", message);
	},

	logPass: function(message) {
		return this._primitiveLog("Pass", message);
	},

	logStart: function(message) {
		return this._primitiveLog("Start", message);
	},
};
