
import UIKit
import SwiftyJSON

struct Prediction {
  let classIndex: Int
  let score: Float
  let rect: CGRect
}

class PrePostId : NSObject {
    // 설정
    static let inputWidth = 640
    static let inputHeight = 640


    static let outputRow = 25200
    static let outputColumn = 77
    static let threshold : Float = 0.20
    static let nmsLimit = 100
    
    // NMS
    static func nonMaxSuppression(boxes: [Prediction], limit: Int, threshold: Float) -> [Prediction] {

      // Do an argsort on the confidence scores, from high to low.
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

    // 검출 결과 NMS
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
                
                let prediction = Prediction(classIndex: cls, score: Float(truncating: outputs[i*77+4]), rect: rect)
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
    
    static func textDetection(textView: UITextField, nmsPredictions: [Prediction], classes: [String]) {
        var result: String = ""
        for pred in nmsPredictions {
            result = result + classes[pred.classIndex]
        }
        textView.text = result
    }
    
    static func localRename(local: String) -> String {
        if local == "local_busan" {return "부산 "}
        else if local == "local_cb" {return "충북 "}
        else if local == "local_cn" {return "충남 "}
        else if local == "local_daegu" {return "대구 "}
        else if local == "local_daejeon" {return "대전 "}
        else if local == "local_incheon" {return "인천 "}
        else if local == "local_jb" {return "전북 "}
        else if local == "local_jeju" {return "제주 "}
        else if local == "local_jn" {return "전남 "}
        else if local == "local_kangwon" {return "강원 "}
        else if local == "local_kb" {return "경북 "}
        else if local == "local_kn" {return "경남 "}
        else if local == "local_kyounggi" {return "경기 "}
        else if local == "local_seoul" {return "서울 "}
        else if local == "local_ulsan" {return "울산 "}
        else {return ""}
    }
    
    // ID 후처리
    static func PostId(nmsPredictions: [Prediction], classes: [String]) -> (CGRect, [String], CGRect) {
        
        var resultId: [String] = []
        
        var regnumRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var nameRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var issuedateRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var issueplaceRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var encnumRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var driverNumRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var expireRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var check_yesRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        var check_midRect: CGRect = CGRect(x: 1, y: 1, width:1, height:1)
        
        var regnum: String = ""
        var issuedate: String = ""
        var encnum: String = ""
        var driverNum: String = ""
        var title: String = ""
        var expire: String = ""
        var expatriate = ""
        
        for pred in nmsPredictions {
            if classes[pred.classIndex] == "regnum" || classes[pred.classIndex] == "t_jumin_regnum"{
                regnumRect = pred.rect
            }
            if classes[pred.classIndex] == "name" || classes[pred.classIndex] == "t_jumin_name"{
                nameRect = pred.rect
                nameRect = CGRect(x: nameRect.minX - nameRect.height * 0.2, y: nameRect.minY - nameRect.height * 0.2, width: nameRect.width + nameRect.height * 0.2 * 2, height: nameRect.height + nameRect.height * 0.2)
            }
            if classes[pred.classIndex] == "issuedate" || classes[pred.classIndex] == "t_jumin_issue1"{
                issuedateRect = pred.rect
            }
            if classes[pred.classIndex] == "issueplace"{
                issueplaceRect = pred.rect
            }
            if classes[pred.classIndex] == "encnum"{
                encnumRect = pred.rect
            }
            if classes[pred.classIndex] == "licensenum"{
                driverNumRect = pred.rect
            }
            if classes[pred.classIndex] == "t_jumin_expire"{
                expireRect = pred.rect
            }
            if classes[pred.classIndex] == "title_jumin"{
                title = "JUMIN"
            }
            if classes[pred.classIndex] == "title_driver"{
                title = "DRIVER"
            }
            if classes[pred.classIndex] == "title_t_jumin"{
                title = "JUMIN_TEMP"
            }
            if classes[pred.classIndex] == "expatriate"{
                expatriate = "재외국민"
            }
            if classes[pred.classIndex] == "check_yes"{
                check_yesRect = pred.rect
            }
            if classes[pred.classIndex] == "check_mid"{
                check_midRect = pred.rect
            }
        }
        
        let predictions = nmsPredictions.sorted{$0.rect.origin.x < $1.rect.origin.x}
        
        
        for pred in predictions {
            if pred.rect.midX > regnumRect.minX && pred.rect.midY > regnumRect.minY && pred.rect.midX < regnumRect.maxX && pred.rect.midY < regnumRect.maxY && classes[pred.classIndex] != "regnum" && classes[pred.classIndex] != "t_jumin_regnum"{
                regnum = regnum + classes[pred.classIndex]
            }
            if pred.rect.midX > issuedateRect.minX && pred.rect.midY > issuedateRect.minY && pred.rect.midX < issuedateRect.maxX && pred.rect.midY < issuedateRect.maxY && classes[pred.classIndex] != "issuedate" && classes[pred.classIndex] != "t_jumin_issue1"{
                issuedate = issuedate + classes[pred.classIndex]
            }
            if pred.rect.midX > encnumRect.minX && pred.rect.midY > encnumRect.minY && pred.rect.midX < encnumRect.maxX && pred.rect.midY < encnumRect.maxY && classes[pred.classIndex] != "encnum"{
                encnum = encnum + classes[pred.classIndex]
            }
            if pred.rect.midX > driverNumRect.minX && pred.rect.midY > driverNumRect.minY && pred.rect.midX < driverNumRect.maxX && pred.rect.midY < driverNumRect.maxY && classes[pred.classIndex] != "licensenum"{
                
                var className = classes[pred.classIndex]
                if className.contains("local") {
                    className = localRename(local: className)
                }
                
                driverNum = driverNum + className
            }
            if pred.rect.midX > expireRect.minX && pred.rect.midY > expireRect.minY && pred.rect.midX < expireRect.maxX && pred.rect.midY < expireRect.maxY && classes[pred.classIndex] != "t_jumin_expire"{
                expire = expire + classes[pred.classIndex]
            }
        }
    
        if check_yesRect.midX < check_midRect.midX {
            expatriate = "거주자"
        }
        if check_yesRect.midX > check_midRect.midX {
            expatriate = "재외국민"
        }
        
        resultId.append(title.trimmingCharacters(in: .whitespaces))
        resultId.append(regnum.trimmingCharacters(in: .whitespaces))
        resultId.append(issuedate.trimmingCharacters(in: .whitespaces))
        resultId.append(encnum.trimmingCharacters(in: .whitespaces))
        resultId.append(driverNum.trimmingCharacters(in: .whitespaces))
        resultId.append(expatriate.trimmingCharacters(in: .whitespaces))
        resultId.append(expire.trimmingCharacters(in: .whitespaces))
        
        return (nameRect, resultId, regnumRect)
    }

}
