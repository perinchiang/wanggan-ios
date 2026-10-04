// Original vector artwork, matching the in-app SwiftUI packet character.
import AppKit

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                              bytesPerRow: size * 4, space: colorSpace,
                              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("Cannot create icon context") }
let ink = CGColor(red: 0.098, green: 0.098, blue: 0.098, alpha: 1)
context.setFillColor(CGColor(red: 0.843, green: 0.969, blue: 0.357, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: CGFloat(size), height: CGFloat(size)))
context.setFillColor(ink)
context.addPath(CGPath(roundedRect: CGRect(x: 224, y: 240, width: 576, height: 580), cornerWidth: 225, cornerHeight: 225, transform: nil))
context.fillPath()
for x in [330.0, 595.0] {
    context.addPath(CGPath(roundedRect: CGRect(x: x, y: 205, width: 110, height: 62), cornerWidth: 31, cornerHeight: 31, transform: nil))
    context.fillPath()
}
for x in [447.0, 597.0] {
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fillEllipse(in: CGRect(x: x, y: 530, width: 116, height: 165))
    context.setFillColor(ink)
    context.fillEllipse(in: CGRect(x: x + 60, y: 569, width: 47, height: 67))
}
guard let image = context.makeImage(),
      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { fatalError("Cannot encode icon") }
let destination = URL(fileURLWithPath: "Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
try png.write(to: destination)
print("Generated original 1024px app icon")
