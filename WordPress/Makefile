
dependencies: xcframeworks


xcframeworks:
	curl https://cdn.a8c-ci.services/gutenberg-mobile/Gutenberg-v1.121.0.tar.gz --output Frameworks/Gutenberg.tar.gz -C -
	tar -xvf Frameworks/Gutenberg.tar.gz -C Frameworks/ -k
	mv -n Frameworks/Frameworks/*.xcframework Frameworks/
	rm -rf Frameworks/Frameworks Frameworks/dummy.txt
	mkdir -p Frameworks/hermes.xcframework/ios-arm64/dSYMs Frameworks/hermes.xcframework/ios-arm64_x86_64-simulator/dSYMs
