#!/usr/bin/swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
  fputs("Usage: generate-app-icon.swift <AppIcon.iconset>\n", stderr)
  exit(2)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let variants: [(String, Int)] = [
  ("icon_16x16.png", 16),
  ("icon_16x16@2x.png", 32),
  ("icon_32x32.png", 32),
  ("icon_32x32@2x.png", 64),
  ("icon_128x128.png", 128),
  ("icon_128x128@2x.png", 256),
  ("icon_256x256.png", 256),
  ("icon_256x256@2x.png", 512),
  ("icon_512x512.png", 512),
  ("icon_512x512@2x.png", 1024),
]

func render(size: Int) throws -> Data {
  guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
  ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    throw NSError(domain: "CodexDreamSkinIcon", code: 1)
  }

  let scale = CGFloat(size) / 512
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  context.imageInterpolation = .high
  NSColor.clear.setFill()
  NSRect(x: 0, y: 0, width: size, height: size).fill()

  let canvas = NSRect(x: 20 * scale, y: 20 * scale, width: 472 * scale, height: 472 * scale)
  let canvasPath = NSBezierPath(roundedRect: canvas, xRadius: 126 * scale, yRadius: 126 * scale)
  NSColor(calibratedRed: 0.055, green: 0.059, blue: 0.082, alpha: 1).setFill()
  canvasPath.fill()

  let palette = NSBezierPath()
  palette.move(to: NSPoint(x: 116 * scale, y: 292 * scale))
  palette.curve(
    to: NSPoint(x: 284 * scale, y: 112 * scale),
    controlPoint1: NSPoint(x: 116 * scale, y: 194 * scale),
    controlPoint2: NSPoint(x: 189 * scale, y: 112 * scale)
  )
  palette.curve(
    to: NSPoint(x: 430 * scale, y: 238 * scale),
    controlPoint1: NSPoint(x: 366 * scale, y: 112 * scale),
    controlPoint2: NSPoint(x: 430 * scale, y: 168 * scale)
  )
  palette.curve(
    to: NSPoint(x: 360 * scale, y: 312 * scale),
    controlPoint1: NSPoint(x: 430 * scale, y: 284 * scale),
    controlPoint2: NSPoint(x: 398 * scale, y: 312 * scale)
  )
  palette.line(to: NSPoint(x: 330 * scale, y: 312 * scale))
  palette.curve(
    to: NSPoint(x: 307 * scale, y: 344 * scale),
    controlPoint1: NSPoint(x: 312 * scale, y: 312 * scale),
    controlPoint2: NSPoint(x: 300 * scale, y: 327 * scale)
  )
  palette.line(to: NSPoint(x: 316 * scale, y: 372 * scale))
  palette.curve(
    to: NSPoint(x: 280 * scale, y: 414 * scale),
    controlPoint1: NSPoint(x: 323 * scale, y: 395 * scale),
    controlPoint2: NSPoint(x: 306 * scale, y: 414 * scale)
  )
  palette.curve(
    to: NSPoint(x: 116 * scale, y: 292 * scale),
    controlPoint1: NSPoint(x: 190 * scale, y: 414 * scale),
    controlPoint2: NSPoint(x: 116 * scale, y: 367 * scale)
  )
  let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.38, alpha: 1),
    NSColor(calibratedRed: 0.84, green: 0.25, blue: 0.22, alpha: 1),
  ])
  gradient?.draw(in: palette, angle: -45)

  let dots: [(CGFloat, CGFloat, CGFloat, NSColor)] = [
    (200, 212, 24, NSColor(calibratedRed: 1, green: 0.91, blue: 0.84, alpha: 1)),
    (275, 180, 22, NSColor(calibratedRed: 0.34, green: 0.89, blue: 0.70, alpha: 1)),
    (346, 218, 21, NSColor(calibratedRed: 0.34, green: 0.73, blue: 1, alpha: 1)),
    (370, 280, 19, NSColor(calibratedRed: 0.96, green: 0.77, blue: 0.36, alpha: 1)),
  ]
  for (x, y, radius, color) in dots {
    color.setFill()
    NSBezierPath(
      ovalIn: NSRect(
        x: (x - radius) * scale,
        y: (512 - y - radius) * scale,
        width: radius * 2 * scale,
        height: radius * 2 * scale
      )
    ).fill()
  }

  NSColor(calibratedRed: 0.055, green: 0.059, blue: 0.082, alpha: 1).setFill()
  NSBezierPath(
    ovalIn: NSRect(x: 185 * scale, y: 172 * scale, width: 61 * scale, height: 61 * scale)
  ).fill()

  context.flushGraphics()
  NSGraphicsContext.restoreGraphicsState()
  guard let data = bitmap.representation(using: .png, properties: [:]) else {
    throw NSError(domain: "CodexDreamSkinIcon", code: 2)
  }
  return data
}

for (filename, size) in variants {
  try render(size: size).write(to: output.appendingPathComponent(filename), options: .atomic)
}
