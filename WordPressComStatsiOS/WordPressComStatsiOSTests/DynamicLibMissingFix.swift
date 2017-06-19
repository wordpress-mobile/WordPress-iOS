// This file is only here to force the CopySwiftLibs build phase to detect it needs to include
// libswiftSwiftOnoneSupport.dylib. This framework does not use Swift but links against ones that
// do and in debug mode optimization is set to -Onone which requires that runtime library. To force
// the scanner to use that library I've added this reference to an array of integers based upon
// the source code of the Swift framework here https://github.com/apple/swift/blob/master/stdlib/public/SwiftOnoneSupport/SwiftOnoneSupport.swift
// Aaron Douglas June 9 2017
import Foundation
let stupidArray = [1, 2, 3, 4]
