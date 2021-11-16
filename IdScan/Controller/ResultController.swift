import UIKit
import Foundation
import SwiftyJSON

class ResultController: UIViewController {
    @IBOutlet weak var resultCapture: UIImageView!
    
    var resultJson: JSON!
    var resultImage: UIImage!
    var originalImage: UIImage!
    var errorCode = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
                
        resultCapture.image = resultImage
        
        print(resultJson!)

        var lastLabelRect: CGRect!
        
        if resultJson["ocr_result"]["IDENTYPE"] == "JUMIN" {
            lastLabelRect = juminPrint()
        }
        else if resultJson["ocr_result"]["IDENTYPE"] == "JUMIN_TEMP" {
            lastLabelRect = juminTempPrint()
        }
        else if resultJson["ocr_result"]["IDENTYPE"] == "DRIVER" {
            lastLabelRect = driverPrint()
        }
        else if errorCode == 23 {
            let label1 = UILabel(frame: CGRect(x: self.view.frame.minX, y: self.resultCapture.frame.maxY, width: self.view.frame.width, height: self.view.frame.height * 0.05))
            
            self.view.addSubview(label1)
            label1.text = "서버 검출을 위해서 인터넷 연결이 필요합니다"
            label1.font = UIFont.systemFont(ofSize: 12)
            label1.textAlignment = .center
            lastLabelRect = label1.frame
            resultCapture.image = originalImage
        }
        else {
            let label1 = UILabel(frame: CGRect(x: self.view.frame.minX, y: self.resultCapture.frame.maxY, width: self.view.frame.width, height: self.view.frame.height * 0.05))
            
            self.view.addSubview(label1)
            label1.text = "검출 실패"
            label1.textAlignment = .center
            lastLabelRect = label1.frame
            resultCapture.image = originalImage

            print("지원하지 않는 신분증입니다.")
        }
        
        var labelAuthTitle = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: lastLabelRect.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let labelAuth1 = UILabel(frame: CGRect(x: self.view.frame.width * 0.3, y: lastLabelRect.maxY, width: self.view.frame.width * 0.2, height: self.view.frame.height * 0.05))
        let labelAuth2 = UILabel(frame: CGRect(x: self.view.frame.width * 0.5, y: lastLabelRect.maxY, width: self.view.frame.width * 0.2, height: self.view.frame.height * 0.05))
        
        self.view.addSubview(labelAuthTitle)
        self.view.addSubview(labelAuth1)
        self.view.addSubview(labelAuth2)
        
        labelAuthTitle.text = "진위 여부"
        labelAuthTitle.font = UIFont.systemFont(ofSize: 12)
        labelAuthTitle.textAlignment = .right

        if resultJson["prediction"].rawString() != "nil" && resultJson["prediction"].rawString() != "null" && resultJson["prediction"].rawString() != "" && resultJson["prediction"].rawString() != nil &&
            resultJson["prediction"].rawString() != "{\n\n}" {
            labelAuth1.text = resultJson["prediction"]["label"].rawString()
            let prediction = Float(resultJson["prediction"]["probability"].rawString()!)
            labelAuth2.text = String(format: "%.3f", prediction!)
            labelAuth1.font = UIFont.systemFont(ofSize: 14)
            labelAuth2.font = UIFont.systemFont(ofSize: 14)
        }
        else if resultJson["prediction"].rawString() == nil {
            let labelAuth1 = UILabel(frame: CGRect(x: self.view.frame.width * 0.3, y: lastLabelRect.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
            self.view.addSubview(labelAuth1)
            labelAuth1.text = "인증 실패"
            labelAuth1.font = UIFont.systemFont(ofSize: 14)
            labelAuth2.isHidden = true
        }
        else if resultJson["prediction"].rawString() == "{\n\n}" {
            labelAuthTitle.text = ""
            labelAuthTitle = UILabel(frame: CGRect(x: self.view.frame.width * 0.1, y: lastLabelRect.maxY, width: self.view.frame.width * 0.8, height: self.view.frame.height * 0.05))
            labelAuthTitle.font = UIFont.systemFont(ofSize: 12)
            labelAuthTitle.text = "진위 여부 판별을 위해서 인터넷 연결이 필요합니다."
            labelAuth1.isHidden = true
            labelAuth2.isHidden = true
            self.view.addSubview(labelAuthTitle)
        }
        else {
            labelAuthTitle.isHidden = true
            labelAuth1.isHidden = true
            labelAuth2.isHidden = true
        }

    }
    
    
    func juminPrint() -> CGRect {
        var expatriate: String!
        if resultJson["ocr_result"]["EXPATRIATE"].rawString() == "true" {
            expatriate = "재외국민"
        }
        else if resultJson["ocr_result"]["EXPATRIATE"].rawString() == "false" || resultJson["ocr_result"]["EXPATRIATE"].rawString() == "" {
            expatriate = "거주자"
        }
        else {
            expatriate = resultJson["ocr_result"]["EXPATRIATE"].rawString()
        }
        
        let label1 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: self.resultCapture.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label2 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label1.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label3 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label2.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label4 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label3.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label5 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label4.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        
        self.view.addSubview(label1)
        self.view.addSubview(label2)
        self.view.addSubview(label3)
        self.view.addSubview(label4)
        self.view.addSubview(label5)
        
        label1.text = "종류"
        label2.text = "분류"
        label3.text = "이름"
        label4.text = "주민번호"
        label5.text = "발급일자"
        
        label1.font = UIFont.systemFont(ofSize: 14)
        label2.font = UIFont.systemFont(ofSize: 14)
        label3.font = UIFont.systemFont(ofSize: 14)
        label4.font = UIFont.systemFont(ofSize: 14)
        label5.font = UIFont.systemFont(ofSize: 14)
        label1.textAlignment = .right
        label2.textAlignment = .right
        label3.textAlignment = .right
        label4.textAlignment = .right
        label5.textAlignment = .right
        
        let textField1 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: self.resultCapture.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField2 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField1.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField3 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField2.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField4 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField3.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField5 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField4.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        
        self.view.addSubview(textField1)
        self.view.addSubview(textField2)
        self.view.addSubview(textField3)
        self.view.addSubview(textField4)
        self.view.addSubview(textField5)
        
        textField1.text = "주민등록증"
        textField2.text = expatriate
        textField3.text = resultJson["ocr_result"]["NAME"].rawString()
        textField4.text = resultJson["ocr_result"]["REGNUM"].rawString()
        textField5.text = resultJson["ocr_result"]["ISSUE_DATE"].rawString()
    
        textField1.textAlignment = .left
        textField2.textAlignment = .left
        textField3.textAlignment = .left
        textField4.textAlignment = .left
        textField5.textAlignment = .left
        
        textField1.textColor = .black
        textField2.textColor = .black
        textField3.textColor = .black
        textField4.textColor = .black
        textField5.textColor = .black
        
        underLine(textField: textField1)
        underLine(textField: textField2)
        underLine(textField: textField3)
        underLine(textField: textField4)
        underLine(textField: textField5)

        return label5.frame
    }
    
    
    func juminTempPrint() -> CGRect {
        let label1 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: self.resultCapture.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label2 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label1.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label3 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label2.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label4 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label3.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label5 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label4.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label6 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label5.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        
        self.view.addSubview(label1)
        self.view.addSubview(label2)
        self.view.addSubview(label3)
        self.view.addSubview(label4)
        self.view.addSubview(label5)
        self.view.addSubview(label6)
    
        label1.text = "종류"
        label2.text = "이름"
        label3.text = "주민번호"
        label4.text = "분류"
        label5.text = "발급일자"
        label6.text = "유효기한"
        label1.font = UIFont.systemFont(ofSize: 14)
        label2.font = UIFont.systemFont(ofSize: 14)
        label3.font = UIFont.systemFont(ofSize: 14)
        label4.font = UIFont.systemFont(ofSize: 14)
        label5.font = UIFont.systemFont(ofSize: 14)
        label6.font = UIFont.systemFont(ofSize: 14)
        label1.textAlignment = .right
        label2.textAlignment = .right
        label3.textAlignment = .right
        label4.textAlignment = .right
        label5.textAlignment = .right
        label6.textAlignment = .right
        
        let textField1 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: self.resultCapture.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField2 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField1.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField3 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField2.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField4 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField3.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField5 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField4.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField6 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField5.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        
        self.view.addSubview(textField1)
        self.view.addSubview(textField2)
        self.view.addSubview(textField3)
        self.view.addSubview(textField4)
        self.view.addSubview(textField5)
        self.view.addSubview(textField6)
        
        textField1.text = "임시주민등록증"
        textField2.text = resultJson["ocr_result"]["NAME"].rawString()
        textField3.text = resultJson["ocr_result"]["REGNUM"].rawString()
        textField4.text = resultJson["ocr_result"]["EXPATRIATE"].rawString()
        textField5.text = resultJson["ocr_result"]["ISSUE_DATE"].rawString()
        textField6.text = resultJson["ocr_result"]["EXPIRE"].rawString()

        textField1.textAlignment = .left
        textField2.textAlignment = .left
        textField3.textAlignment = .left
        textField4.textAlignment = .left
        textField5.textAlignment = .left
        textField6.textAlignment = .left
        
        textField1.textColor = .black
        textField2.textColor = .black
        textField3.textColor = .black
        textField4.textColor = .black
        textField5.textColor = .black
        textField6.textColor = .black
        
        underLine(textField: textField1)
        underLine(textField: textField2)
        underLine(textField: textField3)
        underLine(textField: textField4)
        underLine(textField: textField5)
        underLine(textField: textField6)
        
        return label6.frame
    }
    

    func driverPrint() -> CGRect {
        let label1 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: self.resultCapture.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label2 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label1.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label3 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label2.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label4 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label3.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label5 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label4.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        let label6 = UILabel(frame: CGRect(x: self.view.frame.width * 0.05, y: label5.frame.maxY, width: self.view.frame.width * 0.15, height: self.view.frame.height * 0.05))
        
        self.view.addSubview(label1)
        self.view.addSubview(label2)
        self.view.addSubview(label3)
        self.view.addSubview(label4)
        self.view.addSubview(label5)
        self.view.addSubview(label6)
        
        label1.text = "종류"
        label2.text = "면허번호"
        label3.text = "이름"
        label4.text = "주민번호"
        label5.text = "암호일련"
        label6.text = "발급일자"
    
        label1.font = UIFont.systemFont(ofSize: 14)
        label2.font = UIFont.systemFont(ofSize: 14)
        label3.font = UIFont.systemFont(ofSize: 14)
        label4.font = UIFont.systemFont(ofSize: 14)
        label5.font = UIFont.systemFont(ofSize: 14)
        label6.font = UIFont.systemFont(ofSize: 14)
        
        label1.textAlignment = .right
        label2.textAlignment = .right
        label3.textAlignment = .right
        label4.textAlignment = .right
        label5.textAlignment = .right
        label6.textAlignment = .right
        
        let textField1 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: self.resultCapture.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField2 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField1.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField3 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField2.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField4 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField3.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField5 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField4.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        let textField6 = UITextField(frame: CGRect(x: self.view.frame.width * 0.3, y: textField5.frame.maxY, width: self.view.frame.width * 0.5, height: self.view.frame.height * 0.05))
        
        self.view.addSubview(textField1)
        self.view.addSubview(textField2)
        self.view.addSubview(textField3)
        self.view.addSubview(textField4)
        self.view.addSubview(textField5)
        self.view.addSubview(textField6)
        
        textField1.text = "운전면허증"
        textField2.text = resultJson["ocr_result"]["LICENSE_NUM"].rawString()
        textField3.text = resultJson["ocr_result"]["NAME"].rawString()
        textField4.text = resultJson["ocr_result"]["REGNUM"].rawString()
        textField5.text = resultJson["ocr_result"]["ENCNUM"].rawString()
        textField6.text = resultJson["ocr_result"]["ISSUE_DATE"].rawString()

        textField1.textAlignment = .left
        textField2.textAlignment = .left
        textField3.textAlignment = .left
        textField4.textAlignment = .left
        textField5.textAlignment = .left
        textField6.textAlignment = .left
        
        textField1.textColor = .black
        textField2.textColor = .black
        textField3.textColor = .black
        textField4.textColor = .black
        textField5.textColor = .black
        textField6.textColor = .black
        
        underLine(textField: textField1)
        underLine(textField: textField2)
        underLine(textField: textField3)
        underLine(textField: textField4)
        underLine(textField: textField5)
        underLine(textField: textField6)
        
        return label6.frame
    }
    
    func underLine(textField: UITextField) {
        textField.borderStyle = .none
        let border = CALayer()
        border.frame = CGRect(x: 0, y: textField.frame.size.height-1, width: textField.frame.width, height: 1)
        border.backgroundColor = UIColor.black.cgColor
        textField.layer.addSublayer((border))
        textField.textColor = UIColor.black
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
         self.view.endEditing(true)

   }
}

