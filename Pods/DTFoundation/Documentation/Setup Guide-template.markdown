Setup Guide
===========

You have multiple options available for integrating DTFoundation into your own apps. Ranked from most to least convenient they are:

- [Using Cocoapods](#Cocoapods)
- [As Sub-Project and/or Git Submodule](#Subproject)
- [As Framework](#Framework)

DTFoundation is designed to be included as static library from a subproject.

<a id="Cocoapods"></a>
Integrating via Cocoapods
-------------------------

Having [set up Cocoapods](http://www.cocoanetics.com/2013/01/digging-into-cocoapods/) you add DTFoundation to your `Podfile` like this:

    platform :ios
    pod 'DTFoundation'

This always gets the latest version of the pod spec from the global repository and includes all subspecs that apply to the platform. Alternatively you can pick individual sub specs should you only require certain parts. Available subspecs are:

### Mac only

- AppKit

### iOS only

- DTSidePanel
- UIKit
- UIKit_BlocksAdditions

### Dual Platform

- Core
- DTAWS
- DTASN1
- DTHTMLParser
- DTReachability
- DTUTI
- DTZipArchive

Cocoapods works by copying all source files into an Xcode project that compiles into a static library. It also automatically sets up all header search path and dependencies.

One mild disadvantage of using Cocoapods is that you cannot easily make changes and submit them as pull requests. But generally you should not need to modify DTFoundation code anyway.

<a id="Subproject"></a>
Integrating via Sub-Project
---------------------------

This is the recommended approach as it lets Xcode see all the project symbols and dependencies and also allows for execution of the special build rule that processes the `default.css` file into a link-able form.

If you use `git` as SCM of your apps you would add DTFoundation as a submodule, if not then you would simply clone the project into an Externals sub-folder of your project. The repo URL can either be the one of the master repository or - if you plan to [contribute to it](http://www.cocoanetics.com/2012/01/github-fork-fix-pull-request/) - could be a fork of the project.

### Getting the Files

The process of getting the source files of DTFoundation differs slightly whether or not you use `git` for your project's source code management.

#### As Git Submodule

You add DTFoundation as a submodule:

    git submodule add https://github.com/Cocoanetics/DTFoundation.git Externals/DTFoundation

Now you have a clone of DTFoundation in `Externals/DTFoundation`.

#### As Git Clone

If you don't use git for your project's SCM you clone the project into the Externals folder:

    git clone --recursive https://github.com/Cocoanetics/DTFoundation.git Externals/DTFoundation
   
Now you have a clone of DTFoundation in `Externals/DTFoundation`.

### Project Setup

You want to add a reference to `DTFoundation.xcodeproj` in your Xcode project so that you can access its targets. You also have to set the header search paths, add some framework/library references and check your linker flags.

#### Adding the Sub-Project

Open the destination project and create an "Externals" group.

Add files… or drag `DTFoundation.xcodeproj` to the Externals group. Make sure to uncheck the Copy checkbox. You want to create a reference, not a copy.

#### Setting up Header Search Paths

For Xcode to find the headers of DTFoundation add `Externals/DTFoundation/Core` to the *User Header Search Paths*. Make sure you select the *Recursive* check box.

#### Setting Linker Flags

For the linker to be able to find the symbols of DTFoundation, specifically category methods, you need to add the `-ObjC` linker flag:

In Xcode versions before 4.6 you also needed the `-all_load` flag but that appears to no longer be necessary.

<a id="Framework"></a>
Integrating via Framework
-------------------------

The **Static Framework** target is a fake static framework which you can use with iOS apps. It includes the headers and when adding them to a project Xcode should set up the header search path accordingly. 

Please note that this exists mostly for historic reasons, we do not recommend that you use this method for including it into your projects. 
