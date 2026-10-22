// Renders the Koto app icon and launch-screen logo: a LINE-style white speech
// bubble on green with こと set inside it.
//
//   swift tools/render_icon.swift
//
// Writes into Koto/Assets.xcassets (AppIcon + LaunchLogo).

import AppKit
import CoreText

let green = CGColor(srgbRed: 0x06 / 255, green: 0xC7 / 255, blue: 0x55 / 255, alpha: 1)
let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)

/// The bubble and its tail (y up), sized to the icon.
func bubblePaths(in rect: CGRect) -> [CGPath] {
    let path = CGMutablePath()
    let w = rect.width * 0.80, h = rect.height * 0.64
    let cx = rect.midX, cy = rect.minY + rect.height * 0.535

    // Superellipse: rounder than a rounded rect, squarer than an ellipse.
    let n = 2.6
    let steps = 720
    for i in 0...steps {
        let t = Double(i) / Double(steps) * 2 * .pi
        let c = cos(t), s = sin(t)
        let x = cx + w / 2 * CGFloat(copysign(pow(abs(c), 2 / n), c))
        let y = cy + h / 2 * CGFloat(copysign(pow(abs(s), 2 / n), s))
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()

    // Tail: hangs off the bottom, just left of center, sweeping down-left.
    let u = rect.width
    let bottom = cy - h / 2
    let tail = CGMutablePath()
    tail.move(to: CGPoint(x: rect.minX + u * 0.44, y: bottom + u * 0.06))
    tail.addLine(to: CGPoint(x: rect.minX + u * 0.60, y: bottom + u * 0.06))
    tail.addCurve(
        to: CGPoint(x: rect.minX + u * 0.36, y: bottom - u * 0.105),
        control1: CGPoint(x: rect.minX + u * 0.54, y: bottom - u * 0.03),
        control2: CGPoint(x: rect.minX + u * 0.44, y: bottom - u * 0.08))
    tail.addCurve(
        to: CGPoint(x: rect.minX + u * 0.44, y: bottom + u * 0.06),
        control1: CGPoint(x: rect.minX + u * 0.40, y: bottom - u * 0.06),
        control2: CGPoint(x: rect.minX + u * 0.44, y: bottom - u * 0.02))
    tail.closeSubpath()
    return [path, tail]
}

func drawWordmark(_ ctx: CGContext, in rect: CGRect, color: CGColor) {
    let font = CTFontCreateWithName("HiraginoSans-W8" as CFString, rect.width * 0.30, nil)
    let attrs: [NSAttributedString.Key: Any] = [
        .init(kCTFontAttributeName as String): font,
        .init(kCTForegroundColorAttributeName as String): color,
        .kern: rect.width * 0.004,
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: "こと", attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    let cy = rect.minY + rect.height * 0.535
    ctx.textPosition = CGPoint(x: rect.midX - bounds.midX, y: cy - bounds.midY)
    CTLineDraw(line, ctx)
}

func render(size: Int, background: Bool, scale: CGFloat = 1, to url: URL) {
    let ctx = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: background ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    let full = CGRect(x: 0, y: 0, width: size, height: size)
    if background {
        ctx.setFillColor(green)
        ctx.fill(full)
    }
    // The launch logo draws the bubble edge to edge; the icon leaves margin.
    let inset = full.width * (1 - scale) / 2
    let rect = full.insetBy(dx: inset, dy: inset)
    // Filled one at a time so the overlap doesn't cancel out under winding rules.
    ctx.setFillColor(white)
    for path in bubblePaths(in: rect) {
        ctx.addPath(path)
        ctx.fillPath()
    }
    drawWordmark(ctx, in: rect, color: green)

    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: url)
}

let assets = URL(fileURLWithPath: "Koto/Assets.xcassets")
render(size: 1024, background: true, to: assets.appendingPathComponent("AppIcon.appiconset/AppIcon.png"))
// Launch logo is the icon's artwork without the green square, 200pt wide.
for (suffix, px) in [("@2x", 400), ("@3x", 600)] {
    render(size: px, background: false, scale: 1.25,
           to: assets.appendingPathComponent("LaunchLogo.imageset/LaunchLogo\(suffix).png"))
}
