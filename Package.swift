// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "CwlPreconditionTesting",
	dependencies: [
		.package(url: "/Users/matt/Projects/CwlCatchException", .revision("2910c600e2a5a1cd33122bf825ba7e7740ad9ed7")),
	],
	targets: [
		.target(name: "CwlMachBadInstructionHandler"),
		.target(name: "CwlPreconditionTesting", dependencies: ["CwlMachBadInstructionHandler", "CwlCatchException"], exclude: [
				"Mach/CwlPreconditionTesting.h",
				"Posix/CwlPreconditionTesting.h",
				"CwlCatchBadInstructionPosix.swift"
		]),
		.testTarget(name: "CwlPreconditionTestingTests", dependencies: ["CwlPreconditionTesting"]),
	]
)
