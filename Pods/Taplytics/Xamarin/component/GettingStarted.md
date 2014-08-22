We have worked hard to make implementing the Taplytics SDK as simple as possible, all you need is to initialize the sdk as follows:

```csharp
using TaplyticsSDK;
// ...

// Get your Taplytics API key from:
// https://taplytics.com/
const string apiKey = "YOUR_TAPLYTICS_APIKEY_HERE";

public override bool FinishedLaunching (UIApplication app, NSDictionary options)
{
	Taplytics.StartTaplytics (apiKey);		
	// ...
}
``` 

In order to get your API Key please visitit [Taplytics website.](http://help.taplytics.com/hc/en-us/sections/200118704)