#!/usr/bin/env swift
// Randează paginile unui PDF în PNG (verificare vizuală locală): render-pdf-pages.swift <pdf> <folder> [scară]
import AppKit
import PDFKit
let a = CommandLine.arguments
guard a.count >= 3, let doc = PDFDocument(url: URL(fileURLWithPath: a[1])) else { print("PDF ilizibil"); exit(2) }
let scale = a.count > 3 ? CGFloat(Double(a[3]) ?? 1.2) : 1.2
try? FileManager.default.createDirectory(atPath: a[2], withIntermediateDirectories: true)
for i in 0..<doc.pageCount {
    guard let page = doc.page(at: i) else { continue }
    let r = page.bounds(for: .mediaBox)
    let img = page.thumbnail(of: CGSize(width: r.width * scale, height: r.height * scale), for: .mediaBox)
    guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) else { continue }
    try? png.write(to: URL(fileURLWithPath: "\(a[2])/page-\(i + 1).png"))
}
print("pagini: \(doc.pageCount)")
