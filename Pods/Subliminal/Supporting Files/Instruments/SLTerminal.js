/**
 * SLTerminal.js
 *
 * For details and documentation:
 * http://github.com/inkling/Subliminal
 *
 * Copyright 2013-2014 Inkling Systems, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/**
 * This script forms the basis of Subliminal's trace template, 
 * derived from UIAutomation.tracetemplate, which allows Subliminal
 * to manipulate the Automation instrument. It waits for `SLTerminal` 
 * to write a JavaScript script to the application's preferences, 
 * evaluates that script, and writes the result (or resulting exception) 
 * back to the preferences. `SLTerminal` and `SLTerminal.js` are synchronized 
 * on the value of `scriptIndex`.
 *
 * See also `-[SLTerminal eval:]`.
 */

var _target = UIATarget.localTarget();

// SLTerminal's namespace, used to denote properties of the terminal
// and to avoid collisions with UIAutomation/arbitrary JS executed by/using Subliminal
var SLTerminal = {} 

// private variable
SLTerminal._scriptIndex = 0;

// public variables (manipulated by SLTerminal)
SLTerminal.scriptLoggingEnabled = false;
SLTerminal.hasShutDown = false;

while(!SLTerminal.hasShutDown) {
	// Wait for JavaScript from SLTerminal
	while (true) {
		var scriptIndex = _target.frontMostApp().preferencesValueForKey("scriptIndex");
		
		if (scriptIndex === SLTerminal._scriptIndex) {
			break;
		}
		_target.delay(0.1);
	}
	
	// Read the JavaScript
	var script = _target.frontMostApp().preferencesValueForKey("script");
	if (SLTerminal.scriptLoggingEnabled) {
		UIALogger.logMessage("script:" + SLTerminal._scriptIndex + ": " + script);
	}
	
	// Evaluate the script
	var result = null;
	try {
		result = eval(script);
	} catch (e) {
		// Special case SyntaxErrors so that we can examine the malformed script
		var message = e.toString();
		if ((e instanceof Error) && e.name === "SyntaxError") {
			message += " from script: \"" + script + "\"";
		}
		_target.frontMostApp().setPreferencesValueForKey(message, "exception");
	}

	// Serialize the result only if we can guarantee that it can be serialized to the preferences
	var resultType = (typeof result);
	if (!((resultType === "string") ||
		  (resultType === "boolean") ||
		  (resultType === "number"))) {
		result = null;	
	}
	_target.frontMostApp().setPreferencesValueForKey(result, "result");

	// Notify SLTerminal that we've finished evaluation
	_target.frontMostApp().setPreferencesValueForKey(SLTerminal._scriptIndex, "resultIndex");
	SLTerminal._scriptIndex++;
}
