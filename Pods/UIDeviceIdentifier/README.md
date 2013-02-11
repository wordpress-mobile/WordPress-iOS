# Description
UIDeviceHardware is a class originally created in a [gist](https://gist.github.com/1323251) by [Jaybles](https://github.com/Jaybles). It allows querying of the current users device, and returns a human formatted string. 

It is written as a class method, to allow use without direct instantiation.

## Usage
To use this class, copy the class header files, or include the class in your Cocoapods Podfile. Then when you are ready to query the device, simply import the header file and use:

``` 
NSString *currentDevice = [UIDeviceHardware platformString];
```

## Licence
UIDeviceHardware is available under the MIT license. See the LICENSE file for more info.