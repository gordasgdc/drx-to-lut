#!/usr/bin/env swift
// Generează ghidul PDF (A4) dintr-un fișier Markdown simplu, local, cu AppKit/CoreText (Regula 38).
//   swift scripts/generate-guide.swift <ghid.md> <folder capturi> <ro|en|es> <versiune> <iesire.pdf> <pictograma.png>
// Blocuri: "# titlu", "## secțiune", "- listă", "1. listă numerotată", "![nume]" (captura nume-<limba>-dark.png), paragraf.
import AppKit
import CoreText

let a = CommandLine.arguments
guard a.count >= 7 else { print("argumente lipsă"); exit(2) }
let (mdPath, shots, lang, version, outPath, iconPath) = (a[1], a[2], a[3], a[4], a[5], a[6])
let text = (try! String(contentsOfFile: mdPath, encoding: .utf8)).replacingOccurrences(of: "{{VERSION}}", with: version)

let pageW: CGFloat = 595.28, pageH: CGFloat = 841.89
let mL: CGFloat = 56, mR: CGFloat = 56, mT: CGFloat = 60, mB: CGFloat = 64
let contentW = pageW - mL - mR
let accent = NSColor(srgbRed: 0.659, green: 0.357, blue: 0.137, alpha: 1)
let ink = NSColor(srgbRed: 0.086, green: 0.09, blue: 0.098, alpha: 1)
let muted = NSColor(srgbRed: 0.40, green: 0.41, blue: 0.42, alpha: 1)

func font(_ size: CGFloat, _ weight: NSFont.Weight = .regular) -> NSFont { NSFont.systemFont(ofSize: size, weight: weight) }
func attr(_ s: String, _ f: NSFont, _ c: NSColor, indent: CGFloat = 0, first: CGFloat = 0, after: CGFloat = 6, line: CGFloat = 3) -> NSAttributedString {
    let p = NSMutableParagraphStyle()
    p.headIndent = indent; p.firstLineHeadIndent = first; p.paragraphSpacing = after; p.lineSpacing = line
    return NSAttributedString(string: s, attributes: [.font: f, .foregroundColor: c, .paragraphStyle: p])
}

enum Block { case h1(String), sub(String), h2(String), p(String), bullet(String), num(String, String), image(String) }
var blocks: [Block] = []
var seenH1 = false
for raw in text.split(separator: "\n", omittingEmptySubsequences: true) {
    let l = String(raw)
    if l.hasPrefix("## ") { blocks.append(.h2(String(l.dropFirst(3)))) }
    else if l.hasPrefix("# ") { blocks.append(.h1(String(l.dropFirst(2)))); seenH1 = true }
    else if l.hasPrefix("![") { blocks.append(.image(String(l.dropFirst(2).dropLast()))) }
    else if l.hasPrefix("- ") { blocks.append(.bullet(String(l.dropFirst(2)))) }
    else if let r = l.range(of: #"^\d+\. "#, options: .regularExpression) { blocks.append(.num(String(l[r]).trimmingCharacters(in: .whitespaces), String(l[r.upperBound...]))) }
    else if seenH1, case .h1 = blocks.last! { blocks.append(.sub(l)) }
    else { blocks.append(.p(l)) }
}

var box = CGRect(x: 0, y: 0, width: pageW, height: pageH)
let ctx = CGContext(URL(fileURLWithPath: outPath) as CFURL, mediaBox: &box, [
    kCGPDFContextTitle as String: "DRX to LUT — \(lang.uppercased()) \(version)",
    kCGPDFContextAuthor as String: "Dumitru Cristinel Gordas (GDC)"] as CFDictionary)!
var pageNo = 0
var y: CGFloat = 0   // distanța de la marginea de sus a conținutului
var words = 0, sections = 0, images = 0

func footer() {
    let s = attr("DRX to LUT \(version)   ·   \(pageNo)", font(8.5), muted)
    let setter = CTFramesetterCreateWithAttributedString(s)
    let path = CGPath(rect: CGRect(x: mL, y: 28, width: contentW, height: 20), transform: nil)
    CTFrameDraw(CTFramesetterCreateFrame(setter, CFRange(location: 0, length: 0), path, nil), ctx)
}
func newPage() {
    if pageNo > 0 { footer(); ctx.endPDFPage() }
    pageNo += 1; ctx.beginPDFPage(nil); y = 0
}
func drawText(_ s: NSAttributedString, splittable: Bool = true, x: CGFloat = mL, width: CGFloat = contentW) {
    let setter = CTFramesetterCreateWithAttributedString(s)
    var loc = 0
    while loc < s.length {
        let avail = pageH - mT - mB - y
        var fit = CFRange()
        let need = CTFramesetterSuggestFrameSizeWithConstraints(setter, CFRange(location: loc, length: 0), nil, CGSize(width: width, height: .greatestFiniteMagnitude), &fit).height
        if need > avail && (!splittable || avail < 60) { newPage(); continue }
        let h = min(need, avail)
        let rect = CGRect(x: x, y: pageH - mT - y - h, width: width, height: h + 0.5)
        let frame = CTFramesetterCreateFrame(setter, CFRange(location: loc, length: 0), CGPath(rect: rect, transform: nil), nil)
        CTFrameDraw(frame, ctx)
        let vis = CTFrameGetVisibleStringRange(frame)
        if vis.length == 0 { newPage(); continue }
        loc += vis.length
        y += h
        if loc < s.length { newPage() }
    }
}
func drawImage(_ name: String) {
    let file = "\(shots)/\(name)-\(lang)-dark.png"
    guard let img = NSImage(contentsOfFile: file), let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { print("LIPSĂ captură \(file)"); exit(3) }
    let ratio = CGFloat(cg.height) / CGFloat(cg.width)
    var w: CGFloat = 380, h = w * ratio
    if h > 400 { h = 400; w = h / ratio }
    if h + 18 > pageH - mT - mB - y { newPage() }
    let x = mL + (contentW - w) / 2
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -2), blur: 6, color: NSColor.black.withAlphaComponent(0.25).cgColor)
    ctx.draw(cg, in: CGRect(x: x, y: pageH - mT - y - h, width: w, height: h))
    ctx.restoreGState()
    y += h + 14; images += 1
}

newPage()
// Pictogramă (sursa aprobată, doar redimensionată)
if let icon = NSImage(contentsOfFile: iconPath), let cg = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) {
    ctx.draw(cg, in: CGRect(x: mL, y: pageH - mT - 56, width: 56, height: 56))
}
var first = true
for b in blocks {
    switch b {
    case .h1(let t):
        if first { y = 66; first = false }
        drawText(attr(t, font(26, .semibold), ink, after: 4), splittable: false)
    case .sub(let t): drawText(attr(t, font(10.5), muted, after: 14), splittable: false); words += t.split(separator: " ").count
    case .h2(let t):
        sections += 1
        if pageH - mT - mB - y < 110 { newPage() }
        y += 8
        drawText(attr(t, font(14.5, .semibold), accent, after: 4), splittable: false)
    case .p(let t): drawText(attr(t, font(10.5), ink, after: 6)); words += t.split(separator: " ").count
    case .bullet(let t): drawText(attr("•\t" + t, font(10.5), ink, indent: 16, first: 2, after: 3)); words += t.split(separator: " ").count
    case .num(let n, let t): drawText(attr(n + "\t" + t, font(10.5), ink, indent: 18, first: 0, after: 3)); words += t.split(separator: " ").count
    case .image(let name): drawImage(name)
    }
}
footer(); ctx.endPDFPage(); ctx.closePDF()

let banned = try! NSRegularExpression(pattern: #"\b(price|buy|sale|preț|pret|cumpără|cumpara|vânzare|vanzare|precio|comprar|venta)\b"#, options: .caseInsensitive)
let hits = banned.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
print("PDF \(outPath): pagini=\(pageNo) secțiuni=\(sections) imagini=\(images) cuvinte≈\(words) margini=\(Int(mL))/\(Int(mR))/\(Int(mT))/\(Int(mB))pt cuvinte_interzise=\(hits)")
exit(hits == 0 ? 0 : 1)
