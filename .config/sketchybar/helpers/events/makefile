bin/events: main.swift Info.plist | bin
	swiftc -O main.swift -o $@ -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Info.plist

bin:
	mkdir bin
