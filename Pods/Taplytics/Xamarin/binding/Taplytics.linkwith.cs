using System;
using MonoTouch.ObjCRuntime;

[assembly: LinkWith ("Taplytics", LinkTarget.Simulator | LinkTarget.ArmV7 | LinkTarget.ArmV7s, Frameworks = "CFNetwork Security CoreTelephony SystemConfiguration", LinkerFlags = "-ObjC -licucore", SmartLink = true, ForceLoad = true)]
