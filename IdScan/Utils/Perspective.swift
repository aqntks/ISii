import CoreImage
import Vision
import UIKit

@available(iOS 15.0, *)
public struct Perspective {
    var inputImage: CIImage?

    var string: String? {
        guard let inputImage = inputImage else {
            return nil
        }
        let requestHandler = VNImageRequestHandler(ciImage: inputImage)
        let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
        do {
            try requestHandler.perform([documentDetectionRequest])
        } catch {
            print(error)
            return nil
        }
        guard let document = documentDetectionRequest.results?.first,
              let documentImage = perspectiveCorrectedImage(
                from: inputImage,
                rectangleObservation: document) else {
                  fatalError("Unable to get document image.")
              }
        let documentRequestHandler = VNImageRequestHandler(ciImage: documentImage)
        var textBlocks: [VNRecognizedTextObservation] = []
        let ocrRequest = VNRecognizeTextRequest { request, _ in
            textBlocks = request.results as? [VNRecognizedTextObservation] ?? []
        }
        if textBlocks.isEmpty {
            return nil
        }
        do {
            try documentRequestHandler.perform([ocrRequest])
        } catch {
            print(error)
        }
        textBlocks.forEach {
            if let first = $0.topCandidates(1).first {
                print(first.string)
            } else {
                print("OCR: no top candidates found")
            }
        }
        return textBlocks.first?.topCandidates(1).first?.string
    }

    private func perspectiveCorrectedImage(
        from inputImage: CIImage,
        rectangleObservation: VNRectangleObservation
    )
    -> CIImage? {
        let imageSize = inputImage.extent.size

        // Verify detected rectangle is valid.
        let boundingBox = rectangleObservation.boundingBox.scaled(to: imageSize)
        guard inputImage.extent.contains(boundingBox) else {
            print("invalid detected rectangle")
            return nil
        }
        // Rectify the detected image and reduce it to inverted grayscale for applying model.
        let topLeft = rectangleObservation.topLeft.scaled(to: imageSize)
        let topRight = rectangleObservation.topRight.scaled(to: imageSize)
        let bottomLeft = rectangleObservation.bottomLeft.scaled(to: imageSize)
        let bottomRight = rectangleObservation.bottomRight.scaled(to: imageSize)
        let correctedImage = inputImage
            .cropped(to: boundingBox)
            .applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: topLeft),
                "inputTopRight": CIVector(cgPoint: topRight),
                "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                "inputBottomRight": CIVector(cgPoint: bottomRight)
            ])
        return correctedImage
    }
    
    func detectingPoint() -> VNRectangleObservation {
       
        let requestHandler = VNImageRequestHandler(ciImage: inputImage!)
        let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
        do {
            try requestHandler.perform([documentDetectionRequest])
        } catch {
            print(error)
        }
        let document = documentDetectionRequest.results?.first
    
        return document!
    }
    
    func pointCrop() -> UIImage? {
        let document = detectingPoint()
        
        var boundingBox = document.boundingBox.scaled(to: (inputImage?.extent.size)!)
        
        guard inputImage!.extent.contains(boundingBox) else {
            print("invalid detected rectangle")
            return nil
        }
        
        let topLeft = document.topLeft.scaled(to: (inputImage?.extent.size)!)
        let topRight = document.topRight.scaled(to: (inputImage?.extent.size)!)
        let bottomLeft = document.bottomLeft.scaled(to: (inputImage?.extent.size)!)
        let bottomRight = document.bottomRight.scaled(to: (inputImage?.extent.size)!)
    
        
        let minX = min(min(topLeft.x, topRight.x), min(bottomLeft.x, bottomRight.x))
        let minY = min(min(topLeft.y, topRight.y), min(bottomLeft.y, bottomRight.y))
        let maxX = max(max(topLeft.x, topRight.x), max(bottomLeft.x, bottomRight.x))
        let maxY = max(max(topLeft.y, topRight.y), max(bottomLeft.y, bottomRight.y))
        
        print(boundingBox)
        boundingBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        print(boundingBox)
        let ciContext = CIContext(options: nil)
//        let cgImage = ciContext.createCGImage(inputImage!, from: inputImage!.extent)!.cropping(to: boundingBox)
        let cgImage = ciContext.createCGImage(inputImage!, from: inputImage!.extent)!
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: UIImage.Orientation.up)
        
//        let correctedImage = inputImage!
//            .cropped(to: CGRect(x: boundingBox.minX, y: boundingBox.minY, width: boundingBox.width, height: boundingBox.height))
//
//
        
        
        //
//        print(inputImage?.extent.size)
//        print(correctedImage.extent.size)
//
   
        return uiImage
    }
    
    
    func perspective_transform() -> CIImage {
        let requestHandler = VNImageRequestHandler(ciImage: inputImage!)
        let documentDetectionRequest = VNDetectDocumentSegmentationRequest()
        do {
            try requestHandler.perform([documentDetectionRequest])
        } catch {
            print(error)
        }
        guard let document = documentDetectionRequest.results?.first,
              let documentImage = perspectiveCorrectedImage(
                from: inputImage!,
                rectangleObservation: document) else {
                  fatalError("Unable to get document image.")
              }
        return documentImage
    }
}

extension CGPoint {
    func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}

extension CGRect {
    func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
}
