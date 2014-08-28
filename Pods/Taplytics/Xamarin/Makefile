# Path to mono's xbuild
MONOXBUILD=/Library/Frameworks/Mono.framework/Commands/xbuild

# Target to build the TaplyticsSDK.dll
all: TaplyticsSDK.dll

# Target to download Xamarin-Component.exe
xpkg:
	echo "* Downloading xamarin-component..."
	mkdir xpkg
	curl -L https://components.xamarin.com/submit/xpkg > xpkg/xpkg.zip
	cd xpkg && unzip -qq -o xpkg.zip
	mono xpkg/xamarin-component.exe

# Target to build the TaplyticsSDK.dll
TaplyticsSDK.dll:
	$(MONOXBUILD) /p:Configuration=Release binding/TaplyticsSDK.csproj
	cp binding/bin/Release/TaplyticsSDK.dll TaplyticsSDK.dll

# Target to build the Taplytics Xamarin Component
component: TaplyticsSDK.dll xpkg
	mono xpkg/xamarin-component.exe package

# Clean everything
clean:
	rm -rf xpkg *.xam *.dll
	rm -rf binding/*.dll binding/bin/ binding/obj/ binding/*.sln binding/*.userprefs
	rm -rf samples/TaplyticsSample/TaplyticsSample/bin samples/TaplyticsSample/TaplyticsSample/obj