# TraceLens Demo Host

Create an iOS 17+ SwiftUI app target in Xcode and add this repository as a local package. Add `TraceLensDemoApp.swift` to that target. The demo deliberately instruments its own `URLSessionConfiguration`; it is not a library target and does not impose TraceLens on feature modules.
