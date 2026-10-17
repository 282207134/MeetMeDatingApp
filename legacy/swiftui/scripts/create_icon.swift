import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let output = root.appendingPathComponent("MeetMe/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
let context = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
let rect = NSRect(x: 0, y: 0, width: 1024, height: 1024)
NSGradient(starting: NSColor(red: 0.39, green: 0.86, blue: 0.91, alpha: 1), ending: NSColor(red: 0.20, green: 0.64, blue: 0.90, alpha: 1))!.draw(in: rect, angle: -50)
let logo = NSImage(contentsOf: root.appendingPathComponent("MeetMe/Assets.xcassets/MeetMeMark.imageset/logo.png"))!
logo.draw(in: NSRect(x: 212, y: 206, width: 600, height: 610))
NSGraphicsContext.restoreGraphicsState()
try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("AppIcon.png"))
let contents = """
{"images":[{"filename":"AppIcon.png","idiom":"universal","platform":"ios","size":"1024x1024"}],"info":{"author":"xcode","version":1}}
"""
try contents.write(to: output.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)
print("Created branded iOS app icon.")
