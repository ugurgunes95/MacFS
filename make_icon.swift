import AppKit

// macOS-style rounded-square icon: blue gradient + white fullscreen arrows.
// Regenerate with: swift make_icon.swift && sh iconset.sh (see build.sh)

let size = 1024
let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let bounds = NSRect(x: 0, y: 0, width: size, height: size)
let rect = bounds.insetBy(dx: 60, dy: 60)
let tile = NSBezierPath(roundedRect: rect, xRadius: 210, yRadius: 210)
tile.addClip()
NSGradient(starting: NSColor(red: 0.36, green: 0.68, blue: 1.0, alpha: 1),
           ending: NSColor(red: 0.08, green: 0.42, blue: 0.94, alpha: 1))!
    .draw(in: rect, angle: -90)

let c = NSPoint(x: 512, y: 512)
NSColor.white.setStroke()
for (dx, dy) in [(CGFloat(1), CGFloat(1)), (-1, 1), (1, -1), (-1, -1)] {
    let ux = dx * 0.7071, uy = dy * 0.7071, px = -uy, py = ux
    let tip = NSPoint(x: c.x + ux * 300, y: c.y + uy * 300)
    let shaft = NSBezierPath()
    shaft.move(to: NSPoint(x: c.x + ux * 70, y: c.y + uy * 70))
    shaft.line(to: tip)
    shaft.lineWidth = 62
    shaft.lineCapStyle = .round
    shaft.stroke()
    let head = NSBezierPath()
    let wing: CGFloat = 120
    head.move(to: NSPoint(x: tip.x - ux * wing + px * wing, y: tip.y - uy * wing + py * wing))
    head.line(to: tip)
    head.line(to: NSPoint(x: tip.x - ux * wing - px * wing, y: tip.y - uy * wing - py * wing))
    head.lineWidth = 62
    head.lineCapStyle = .round
    head.lineJoinStyle = .round
    head.stroke()
}

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "icon_1024.png"))
print("icon_1024.png written")
