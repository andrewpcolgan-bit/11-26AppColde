//
//  ImageCleanup.swift
//

import UIKit
import Vision
import CoreImage

struct ImageCleanup {

    static func process(_ image: UIImage) -> UIImage {
        let fixed = normalize(image)
        let cropped = cropTextBlock(fixed) ?? fixed
        return enhance(cropped)
    }

    private static func normalize(_ img: UIImage) -> UIImage {
        if img.imageOrientation == .up { return img }
        UIGraphicsBeginImageContextWithOptions(img.size, true, img.scale)
        img.draw(in: CGRect(origin: .zero, size: img.size))
        let out = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return out ?? img
    }

    private static func cropTextBlock(_ image: UIImage) -> UIImage? {
        guard let cg = image.cgImage else { return nil }

        let req = VNDetectRectanglesRequest()
        req.minimumConfidence = 0.65
        req.maximumObservations = 1

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([req])

        guard let box = req.results?.first?.boundingBox else { return nil }

        let W = CGFloat(cg.width)
        let H = CGFloat(cg.height)

        let rect = CGRect(
            x: box.minX * W,
            y: (1 - box.maxY) * H,
            width: box.width * W,
            height: box.height * H
        )

        guard let crop = cg.cropping(to: rect) else { return nil }
        return UIImage(cgImage: crop)
    }

    private static func enhance(_ image: UIImage) -> UIImage {
        guard let ci = CIImage(image: image) else { return image }

        let f = CIFilter(name: "CIColorControls")!
        f.setValue(ci, forKey: kCIInputImageKey)
        f.setValue(1.1, forKey: kCIInputBrightnessKey)
        f.setValue(1.3, forKey: kCIInputContrastKey)
        f.setValue(1.0, forKey: kCIInputSaturationKey)

        let ctx = CIContext()
        guard let out = f.outputImage,
              let cg = ctx.createCGImage(out, from: out.extent)
        else { return image }

        return UIImage(cgImage: cg)
    }
}
