// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription



let package = Package(
	name: "NotPokerApi",
	
	platforms: [
		.iOS(.v15),
		.macOS(.v10_15)
	],
	

	products: [
		.library(
			name: "NotPokerApi",
			targets: [
				"NotPokerApi"
			]),
	],
	targets: [

		.target(
			name: "NotPokerApi",
			/* include all targets where .h contents need to be accessible to swift */
			dependencies: [/*"PopMp4Objc","PopMp4Framework"*/],
			path: "./NotPokerApiSwift"
		)
	]
)
