
import UIKit

//struct Prediction {
//  let classIndex: Int
//  let score: Float
//  let rect: CGRect
//}

class PrePostHangul : NSObject {
    // 설정
    static let inputWidth = 320
    static let inputHeight = 320

    static let outputRow = 6300
    static let outputColumn = 596
    static let threshold : Float = 0.01
    static let nmsLimit = 100
    
    // NMS
    static func nonMaxSuppression(boxes: [Prediction], limit: Int, threshold: Float) -> [Prediction] {

      let sortedIndices = boxes.indices.sorted { boxes[$0].score > boxes[$1].score }

      var selected: [Prediction] = []
      var active = [Bool](repeating: true, count: boxes.count)
      var numActive = active.count

      outer: for i in 0..<boxes.count {
        if active[i] {
          let boxA = boxes[sortedIndices[i]]
          selected.append(boxA)
          if selected.count >= limit { break }

          for j in i+1..<boxes.count {
            if active[j] {
              let boxB = boxes[sortedIndices[j]]
              if IOU(a: boxA.rect, b: boxB.rect) > threshold {
                active[j] = false
                numActive -= 1
                if numActive <= 0 { break outer }
              }
            }
          }
        }
      }
      return selected
    }

    // IOU
    static func IOU(a: CGRect, b: CGRect) -> Float {
      let areaA = a.width * a.height
      if areaA <= 0 { return 0 }

      let areaB = b.width * b.height
      if areaB <= 0 { return 0 }

      let intersectionMinX = max(a.minX, b.minX)
      let intersectionMinY = max(a.minY, b.minY)
      let intersectionMaxX = min(a.maxX, b.maxX)
      let intersectionMaxY = min(a.maxY, b.maxY)
      let intersectionArea = max(intersectionMaxY - intersectionMinY, 0) *
                             max(intersectionMaxX - intersectionMinX, 0)
      return Float(intersectionArea / (areaA + areaB - intersectionArea))
    }

    // 결과 NMS
    static func outputsToNMSPredictions(outputs: [NSNumber], imgScaleX: Double, imgScaleY: Double, ivScaleX: Double, ivScaleY: Double, startX: Double, startY: Double) -> [Prediction] {
        var predictions = [Prediction]()
        for i in 0..<outputRow {
            if Float(truncating: outputs[i*outputColumn+4]) > threshold {
                let x = Double(truncating: outputs[i*outputColumn])
                let y = Double(truncating: outputs[i*outputColumn+1])
                let w = Double(truncating: outputs[i*outputColumn+2])
                let h = Double(truncating: outputs[i*outputColumn+3])
                
                let left = imgScaleX * (x - w/2)
                let top = imgScaleY * (y - h/2)
                let right = imgScaleX * (x + w/2)
                let bottom = imgScaleY * (y + h/2)
                
                var max = Double(truncating: outputs[i*outputColumn+5])
                var cls = 0
                for j in 0 ..< outputColumn-5 {
                    if Double(truncating: outputs[i*outputColumn+5+j]) > max {
                        max = Double(truncating: outputs[i*outputColumn+5+j])
                        cls = j
                    }
                }

                let rect = CGRect(x: startX+ivScaleX*left, y: startY+top*ivScaleY, width: ivScaleX*(right-left), height: ivScaleY*(bottom-top))
                
                let prediction = Prediction(classIndex: cls, score: Float(truncating: outputs[i*596+4]), rect: rect)
                predictions.append(prediction)
            }
        }

        return nonMaxSuppression(boxes: predictions, limit: nmsLimit, threshold: threshold)
    }

    static func cleanDetection(imageView: UIImageView) {
        if let layers = imageView.layer.sublayers {
            for layer in layers {
                if layer is CATextLayer {
                    layer.removeFromSuperlayer()
                }
            }
            for view in imageView.subviews {
                view.removeFromSuperview()
            }
        }
    }

    static func showDetection(imageView: UIImageView, nmsPredictions: [Prediction], classes: [String]) {
        for pred in nmsPredictions {
            let bbox = UIView(frame: pred.rect)
            bbox.backgroundColor = UIColor.clear
            bbox.layer.borderColor = UIColor.yellow.cgColor
            bbox.layer.borderWidth = 2
            imageView.addSubview(bbox)
            
            let textLayer = CATextLayer()
            textLayer.string = String(format: " %@ %.2f", classes[pred.classIndex], pred.score)
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.backgroundColor = UIColor.magenta.cgColor
            textLayer.fontSize = 14
            textLayer.frame = CGRect(x: pred.rect.origin.x, y: pred.rect.origin.y, width:100, height:20)
            imageView.layer.addSublayer(textLayer)
        }
    }
    
    // 한글 후처리
    static func postHangul(nmsPredictions: [Prediction], classes: [String]) -> String {
        var result: String = ""
        let predictions = nmsPredictions.sorted{$0.rect.origin.x < $1.rect.origin.x}
        for pred in predictions {
            result = result + classes[pred.classIndex * 2]
        }
        
        result = result.trimmingCharacters(in: .whitespaces)
        
        return result.trimmingCharacters(in: .whitespaces)
    }
}
