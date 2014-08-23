using System;
using System.Drawing;
using MonoTouch.ObjCRuntime;
using MonoTouch.Foundation;
using MonoTouch.UIKit;

namespace TaplyticsSDK
{
	delegate void TLExperimentHandler (NSDictionary variables);
	delegate void TLBackgroundFetchHandler (UIBackgroundFetchResult result);

	interface ITaplyticsDelegate {}

	[BaseType (typeof (NSObject))]
	[Model]
	[Protocol]
	interface TaplyticsDelegate {

		[Export ("taplyticsExperimentChanged:variationName:")]
		void ExperimentChanged (string experimentName, [NullAllowed] string variationName);

		[Export ("taplyticsDeviceInfo:")]
		void DeviceInfo (NSDictionary deviceInfo);

		[Export ("taplyticsLastApps:")]
		void LastApps (NSObject[] lastApps);
	}

	[BaseType (typeof (NSObject))]
	interface Taplytics {

		[Static]
		[Export ("startTaplyticsAPIKey:")]
		void StartTaplytics (string apiKey);

		[Static]
		[Export ("startTaplyticsAPIKey:options:")]
		void StartTaplytics (string apiKey, [NullAllowed] NSDictionary options);

		[Since (7,0)]
		[Static]
		[Export ("performBackgroundFetch:")]
		void PerformBackgroundFetch (TLBackgroundFetchHandler completionHandler);

		[Static]
		[Export ("setTaplyticsDelegate:")]
		void SetTaplyticsDelegate ([NullAllowed] ITaplyticsDelegate taplyticsDelegate);

		[Static]
		[Export ("runCodeExperiment:withBaseline:variations:")]
		void RunCodeExperiment (string experimentName, TLExperimentHandler baselineHandler, [NullAllowed] NSDictionary variationNamesAndBlocks);

		[Static]
		[Export ("goalAchieved:")]
		void GoalAchieved (string goalName);

		[Static]
		[Export ("goalAchieved:value:")]
		void GoalAchieved (string goalName, NSNumber value);
	}
}

