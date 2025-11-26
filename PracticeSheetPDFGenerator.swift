//
//  PracticeSheetPDFGenerator.swift
//  Commit-style PDF generator (header + body, multi-page)
//

import UIKit
import PDFKit

struct PracticeSheetPDFGenerator {

    // MARK: - Storage

    private static var pdfDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("PracticePDFs", isDirectory: true)

        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func pdfURL(for practiceID: String) -> URL {
        pdfDirectory.appendingPathComponent("PracticeSheet_\(practiceID).pdf")
    }

    // MARK: - Public API

    /// Build a clean Commit-style PDF from the recognized text of the sheet.
    static func generateSheetPDF(from fullText: String, practiceID: String) -> URL? {

        let pdfURL = pdfURL(for: practiceID)

        // US Letter page
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        // Layout constants tuned to match Commit sheets
        let leftMargin: CGFloat   = 45
        let rightMargin: CGFloat  = 45
        let topMargin: CGFloat    = 40
        let bottomMargin: CGFloat = 60

        // Fonts
        let headerFont = UIFont.systemFont(ofSize: 11) // small centered header
        let bodyFont   = UIFont(name: "Helvetica", size: 13) ?? UIFont.systemFont(ofSize: 13)

        // Line metrics
        let headerLineHeight: CGFloat = headerFont.lineHeight + 2      // tight stack
        let bodyLineHeight: CGFloat   = bodyFont.lineHeight + 4        // Commit-ish spacing

        // Split into lines and separate header (first 3 non-empty lines) from body
        let allLines = fullText.components(separatedBy: .newlines)

        var headerLines: [String] = []
        var bodyLines: [String] = []

        for line in allLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if headerLines.count < 3 && !trimmed.isEmpty {
                headerLines.append(line)
            } else {
                bodyLines.append(line)
            }
        }

        // If OCR didn’t give us a header, treat everything as body
        if headerLines.isEmpty {
            bodyLines = allLines
        }

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in

            // Helper to draw the header block only on the first page
            func drawHeader(on page: CGRect) -> CGFloat {
                guard !headerLines.isEmpty else { return topMargin }

                var y = topMargin

                for header in headerLines {
                    let text = header.replacingOccurrences(of: "\t", with: " ")
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: headerFont,
                        .foregroundColor: UIColor.black
                    ]
                    let size = (text as NSString).size(withAttributes: attrs)
                    let x = (page.width - size.width) / 2.0
                    (text as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
                    y += headerLineHeight
                }

                // Divider line just under header block
                let dividerY = y + 6
                let path = UIBezierPath()
                path.move(to: CGPoint(x: leftMargin, y: dividerY))
                path.addLine(to: CGPoint(x: page.width - rightMargin, y: dividerY))
                path.lineWidth = 1.0
                UIColor.black.setStroke()
                path.stroke()

                // First body line starts a bit below the divider
                return dividerY + 14
            }

            // MARK: - Start first page

            context.beginPage()
            UIColor.white.setFill()
            context.fill(pageRect)

            var cursorY: CGFloat = drawHeader(on: pageRect)

            // MARK: - Draw body text, line by line

            // Commit-style spacing constants
            let blankLineExtra: CGFloat = 10        // extra gap on truly blank lines
            let blockTopPadding: CGFloat = 18       // above block headers like "Kick", "Drill", "Main Set"
            let setStarterPadding: CGFloat = 10     // before lines like "2X", "3X", etc.

            for rawLine in bodyLines {

                let line = rawLine.replacingOccurrences(of: "\t", with: "    ")
                let trimmed = rawLine.trimmingCharacters(in: .whitespaces)

                // Handle page break
                if cursorY > pageRect.height - bottomMargin {
                    context.beginPage()
                    UIColor.white.setFill()
                    context.fill(pageRect)
                    cursorY = topMargin
                }

                // 1. FULL BLANK LINE
                if trimmed.isEmpty {
                    cursorY += bodyLineHeight + blankLineExtra
                    continue
                }

                // 2. SECTION HEADER (Kick, Drill, Main Set, Warm Down, Technique & Recovery...)
                let lowercase = trimmed.lowercased()
                let isBlockHeader =
                    lowercase == "kick" ||
                    lowercase == "drill" ||
                    lowercase == "main set" ||
                    lowercase == "warm down" ||
                    lowercase == "warm-up" ||
                    lowercase == "warm up" ||
                    lowercase == "technique & recovery" ||
                    lowercase == "pull" ||
                    lowercase == "sprint finisher" ||
                    lowercase == "pre set" ||
                    lowercase == "pre-set"

                if isBlockHeader {
                    cursorY += blockTopPadding
                }

                // 3. MULTI-REPEAT STARTERS (2X, 3X, 4X, etc.)
                let isSetStarter =
                    trimmed.uppercased().hasSuffix("X") &&
                    trimmed.count <= 4 &&
                    Int(trimmed.replacingOccurrences(of: "X", with: "")) != nil

                if isSetStarter {
                    cursorY += setStarterPadding
                }

                // Draw line
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: bodyFont,
                    .foregroundColor: UIColor.black
                ]

                let point = CGPoint(x: leftMargin, y: cursorY)
                let attributed = NSAttributedString(string: line, attributes: attrs)
                attributed.draw(at: point)

                cursorY += bodyLineHeight
            }

        }

        do {
            try data.write(to: pdfURL, options: .atomic)
            print("📄 Commit-style PDF saved at:", pdfURL.path)
            return pdfURL
        } catch {
            print("❌ Error saving PDF:", error)
            return nil
        }
    }
}
