import UIKit
import AVFoundation
import Alamofire
import SwiftyJSON
import Lottie
import Vision

class DetectionController: UIViewController, AVCapturePhotoCaptureDelegate {
    // UI
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var serverMobileSwitch: UISwitch!
    @IBOutlet weak var authSwitch: UISwitch!
    @IBOutlet weak var serverMobileLabel: UILabel!
    @IBOutlet weak var authLabel: UILabel!
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    // 카메라
    var captureSesssion : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!

    // Detector
    var inferencer: ObjectDetector!
    
    private var guideRect: CGRect?
    
    // 옵션 선택
    private var onDevice = true
    private var idAuth = "1"  // 1 on  0 off
    
    // 효과
    let detectingAni = AnimationView(name: "detecting2")
    
    // 임시 이미지
    private var original: UIImage!
    private var guideCropOri: UIImage!
    
    // 결과 저장
    private var resultId: [String]!
    private var resultName = ""
    private var resultJson: JSON!
    private var resultImage: UIImage!
    private var authJson: JSON!
    private var errorCode = 10
    
    private var finish = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        // 프리뷰 위치 지정
        previewView.frame = CGRect(x: 0 , y: (self.navigationController?.navigationBar.frame.maxY)!, width: self.view.frame.width, height: self.view.frame.width * (4032 / 3024))
        
        // UI 적용, 가이드 적용
        self.setUI()
        
        // 카메라
        captureSesssion = AVCaptureSession()
        captureSesssion.sessionPreset = AVCaptureSession.Preset.photo
        
        cameraOutput = AVCapturePhotoOutput()
        
        let device = AVCaptureDevice.default(for: .video)
        
        if let input = try? AVCaptureDeviceInput(device: device!) {
            if (captureSesssion.canAddInput(input)) {
                captureSesssion.addInput(input)
                if (captureSesssion.canAddOutput(cameraOutput)) {
                    captureSesssion.addOutput(cameraOutput)
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
                    previewLayer.frame = previewView.bounds
                    previewView.layer.addSublayer(previewLayer)
                    captureSesssion.startRunning()
                }
            } else {
                print("에러 발생 : 20")
            }
        } else {
            print("에러 발생 : 21")
        }
    }

    // 이미지 촬영
    @IBAction func didPressTakePhoto(_ sender: UIButton) {
        self.captureButton.isEnabled = false
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [
             kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
             kCVPixelBufferWidthKey as String: 160,
             kCVPixelBufferHeightKey as String: 160
        ]
        settings.previewPhotoFormat = previewFormat
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    
    // Output 콜백
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        captureSesssion.stopRunning()
        
        self.view.addSubview(detectingAni)
        detectingAni.frame = detectingAni.superview!.bounds
        detectingAni.contentMode = .scaleAspectFit
        detectingAni.play()
        detectingAni.loopMode = .loop
        
        if error != nil {
        print("에러 발생 : 15")
    }
        
    if  let sampleBuffer = photoSampleBuffer,
        let previewBuffer = previewPhotoSampleBuffer,
        let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {

        let dataProvider = CGDataProvider(data: dataImage as CFData)
        let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        let original_image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImage.Orientation.right)
        
        original = original_image
        

        // 가이드 크롭
        let imageViewScale = max(original_image.size.width / self.view.frame.width,
                                 original_image.size.height / previewView.frame.height)
        
        let cropRatio = original_image.size.width / previewView.frame.width
        
        let cropImageW = self.guideRect!.width * cropRatio
        let cropImageH = self.guideRect!.height * cropRatio
        let cropImageX = self.guideRect!.minX * cropRatio
        let cropImageY = (self.guideRect!.minY - (self.navigationController?.navigationBar.frame.maxY)!) * cropRatio
  
        let cropRect = CGRect(x: cropImageY, y: cropImageX, width: cropImageH, height: cropImageW)

        let imageRef = original_image.cgImage!.cropping(to: cropRect)
        var image = UIImage(cgImage: imageRef!, scale: original_image.scale, orientation: UIImage.Orientation.right)
        
        guideCropOri = image.copy() as! UIImage
        resultImage = image
    
//        // perspective transform
//        var newImage: UIImage!
//        // iOS 15 이상 적용(perspective transform)
//        if (UIDevice.current.systemVersion.hasPrefix("15")){
//            // UIImage to CIImage
//            var ciImage = CIImage(image: image)
//
//            ciImage = ciImage?.oriented(forExifOrientation: 6)
//            if #available(iOS 15.0, *) {
//                ciImage = Perspective.init(inputImage: ciImage).perspective_transform()
////                newImage = Perspective.init(inputImage: ciImage).pointCrop()
//            } else {
//                // Fallback on earlier versions
//            }
//            // CIImage to UIImage
//            newImage = UIImage(ciImage: ciImage!)
//
//        }
//        else {
//            newImage = image
//        }
    
//        resultImage = newImage

        // id 검출
        // 모바일
        if onDevice {
            if idAuth == "1" {
                self.sendIdAuth(image: image)
            }
            detect_id(newImage: image)
        }
        // 서버
        else {
            image = self.rotate(image: image, degree: 360)!
            if idAuth == "1" {
                self.sendIdAuth(image: image)
            }
            sendServer(image: image, auth_on: idAuth)
        }
    } else {
        print("에러 발생 : 16")
    }
}

    // id 검출
    func detect_id(newImage: UIImage){
        if newImage.size.width < newImage.size.height {
            resultImage = newImage
            self.resultJson = ["err_code": 99]
            detectingFinish()
            return
        }
        
        let squareImage = self.makeSquareGrayImage(image: newImage)

        // 검출용 이미지 resize(640*640)
        let det_image = squareImage.resized(to: CGSize(width: CGFloat(PrePostId.inputWidth), height: CGFloat(PrePostId.inputHeight)))

        let imgScaleX = Double(squareImage.size.width / CGFloat(PrePostId.inputWidth));
        let imgScaleY = Double(squareImage.size.height / CGFloat(PrePostId.inputHeight));

        let ivScaleX: Double = 1.0
        let ivScaleY: Double = 1.0
        let startX = 0.0
        let startY = 0.0

        // 이미지 normalized
        guard var pixelBuffer = det_image.normalized() else {
            return
        }

        DispatchQueue.global().async {
            // 검출
            guard let outputs = self.inferencer.id_module.detect(image: &pixelBuffer) else {
                return
            }
            // NMS
            let nmsPredictions = PrePostId.outputsToNMSPredictions(outputs: outputs, imgScaleX: imgScaleX, imgScaleY: imgScaleY, ivScaleX: ivScaleX, ivScaleY: ivScaleY, startX: startX, startY: startY)

            DispatchQueue.main.async {
                // 결과 출력
                var nameRect: CGRect!
                var regnumRect: CGRect!

                (nameRect, self.resultId, regnumRect) = PrePostId.PostId(nmsPredictions: nmsPredictions, classes: self.inferencer.id_classes)

                // 이미지 마스킹
                let makingImage = newImage
                regnumRect = CGRect(x: regnumRect.minX + regnumRect.width / 2, y: regnumRect.minY, width: regnumRect.width / 2, height: regnumRect.height)
                self.resultImage = self.masking(image: makingImage, rect: regnumRect)
                
                // 이름 크롭
                if (self.resultId[0] == "JUMIN"){
                    nameRect = CGRect(x: nameRect.minX, y: nameRect.minY, width: nameRect.width / 2, height: nameRect.height)
                }

                let nameRef = squareImage.cgImage!.cropping(to: nameRect)
                var nameImage = UIImage(cgImage: nameRef!, scale: squareImage.scale, orientation: squareImage.imageOrientation)

                
                if nameImage.size.width < nameImage.size.height {
                    self.resultJson = ["err_code": 99]
                    self.detectingFinish()
                    return
                }
                
                if nameImage.size.width * nameImage.size.height > 1.0 {
                nameImage = self.makeSquareGrayImage(image: nameImage)
                }

                self.detect_hangul(hangulImage: nameImage)
            }
        }
    }
    
    
    // hangul - 검출
    func detect_hangul(hangulImage: UIImage) {
        // 검출용 이미지 resize(320*320)
        let det_image_han = hangulImage.resized(to: CGSize(width: CGFloat(PrePostHangul.inputWidth), height: CGFloat(PrePostHangul.inputHeight)))
        
        let imgScaleX_han = Double(hangulImage.size.width / CGFloat(PrePostHangul.inputWidth))
        let imgScaleY_han = Double(hangulImage.size.height / CGFloat(PrePostHangul.inputHeight))
    
        let ivScaleX_han: Double = 1.0
        let ivScaleY_han: Double = 1.0
        let startX_han = 0.0
        let startY_han = 0.0

        guard var pixelBuffer_han = det_image_han.normalized() else {
            return
        }

        DispatchQueue.global().async {
            guard let outputs_han = self.inferencer.hangul_module.detectHangul(image: &pixelBuffer_han) else {
                return
            }
            let nmsPredictions_han = PrePostHangul.outputsToNMSPredictions(outputs: outputs_han, imgScaleX: imgScaleX_han, imgScaleY: imgScaleY_han, ivScaleX: ivScaleX_han, ivScaleY: ivScaleY_han, startX: startX_han, startY: startY_han)
        
            DispatchQueue.main.async {
                let hangul = PrePostHangul.postHangul(nmsPredictions: nmsPredictions_han, classes: self.inferencer.hangul_classes)
                self.resultName = hangul
                
                if (self.idAuth == "0") || (self.finish) {
                    self.makeIdJson()
                    self.detectingFinish()
                }
                else {
                    self.finish = true
                }
            }
        }
    }
    
    // 이미지 정사각형으로 변환 후 빈칸 회색 적용
    func makeSquareGrayImage(image: UIImage) -> UIImage {
        // 회색 이미지 만들기
        let color = UIColor.gray
        let sizes = CGSize(width: image.size.width, height: image.size.width - image.size.height)

        UIGraphicsBeginImageContextWithOptions(sizes, false, 0.0)
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(origin: .zero, size: sizes))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 이미지 합성
        let ori_img = image
        let grayImage = colorImage!

        let size = CGSize(width: image.size.width, height: image.size.width)
        UIGraphicsBeginImageContext(size)

        let oriSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let graySize = CGRect(x: 0, y: image.size.height, width: image.size.width, height: image.size.width - image.size.height)
        ori_img.draw(in: oriSize)
        grayImage.draw(in: graySize)

        let newImages:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImages
    }

    // 이미지 마스킹
    func masking(image: UIImage, rect: CGRect) -> UIImage? {
        // 회색 이미지 만들기
        let color = UIColor.gray
        let sizes = CGSize(width: rect.width, height: rect.height)

        UIGraphicsBeginImageContextWithOptions(sizes, false, 0.0)
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(origin: .zero, size: sizes))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 이미지 합성
        let ori_img = image
        let grayImage = colorImage!

        let size = CGSize(width: image.size.width, height: image.size.height)
        UIGraphicsBeginImageContext(size)

        let oriSize = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let graySize = rect
        ori_img.draw(in: oriSize)
        grayImage.draw(in: graySize)

        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    func rotate(image: UIImage, degree: Int) -> UIImage? {
        
        let radians = Float(degree) / (180.0 / Float.pi)
        
        var newSize = CGRect(origin: CGPoint.zero, size: image.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        let context = UIGraphicsGetCurrentContext()!

        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        image.draw(in: CGRect(x: -image.size.width/2, y: -image.size.height/2, width: image.size.width, height: image.size.height))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    
    // 검출 서버 통신
    func sendServer(image: UIImage, auth_on: String) {
        let userName = "code1system"
        let url = "http://49.254.96.114:5000/id-scan"

        let imgData = image.jpegData(compressionQuality: 0.2)!

        let parameters = [
        "userName" : userName
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
        
            for (key, value) in parameters {

            multipartFormData.append("\(value)".data(using: .utf8)!, withName: key, mimeType: "text/plain")

            }
            
            multipartFormData.append(imgData, withName: "file_param_1", fileName: "\(userName).jpg", mimeType: "image/jpg")
            multipartFormData.append(auth_on.data(using: .utf8)!, withName: "auth_on", fileName: "auth_on", mimeType: "text/plain")
            
        }, to: url).responseJSON { response in
            switch response.result {
            case .success(let value):
                self.resultJson = JSON(value)

                if (self.idAuth == "0") || self.finish {
                    self.makeIdJson()
                    self.detectingFinish()
                }
                else {
                    self.finish = true
                }
                
            default:
                print("Json 파싱 실패")
                print("에러 23")
                self.errorCode = 23
                self.detectingFinish()
            }
        }
    }
    
    // 인증 서버 통신
    func sendIdAuth(image: UIImage) {
        let userName = "code1system"
        let url = "http://115.178.87.240:5090/menesdemo/predict"
        let imgData = image.jpegData(compressionQuality: 0.2)!

        let parameters = [
        "userName" : userName
        ]
        
        AF.upload(multipartFormData: { multipartFormData in
//            for (key, value) in parameters {
//
//            multipartFormData.append("\(value)".data(using: .utf8)!, withName: key, mimeType: "text/plain")
//
//            }
            multipartFormData.append(imgData, withName: "file", fileName: "\(userName).jpg", mimeType: "image/jpg")

        }, to: url).responseJSON { response in
            switch response.result {
            case .success(let value):
                self.authJson = JSON(value)["prediction"]
            default:
                print("Json 파싱 실패")
                print("에러 111")
            }
            
            if self.finish {
                self.makeIdJson()
                self.detectingFinish()
            }
            else {
                self.finish = true
            }
            
        }
    }
    
    // 결과 JSON 파싱
    func makeIdJson() {
        let ocrInnerJson: JSON!
        if onDevice {
            ocrInnerJson  = ["IDENTYPE": self.resultId[0], "NAME": self.resultName, "REGNUM": self.resultId[1], "ISSUE_DATE": self.resultId[2], "ENCNUM": self.resultId[3], "LICENSE_NUM": self.resultId[4], "EXPATRIATE": self.resultId[5], "EXPIRE": self.resultId[6]]
        }
        else {
            
            if self.resultJson["err_code"] == 10 {
                ocrInnerJson = self.resultJson["ocr_result"]
                let w = self.resultJson["masking"]["width"].rawValue as! CGFloat / 2.0
                let h = self.resultJson["masking"]["height"].rawValue as! CGFloat
                let x = self.resultJson["masking"]["x"].rawValue as! CGFloat + w
                let y = self.resultJson["masking"]["y"].rawValue as! CGFloat
                
                let rect = CGRect(x: x, y: y, width: w, height: h)
                self.resultImage = self.masking(image: self.resultImage, rect: rect)
            }
            else {
                ocrInnerJson = self.resultJson["err_code"]
            }
        }
        
        if idAuth == "1" {
            self.resultJson = ["err_code": 10, "ocr_result": ocrInnerJson, "prediction": self.authJson]
        }
        else {
            self.resultJson = ["err_code": 10, "ocr_result": ocrInnerJson]
        }
    }
    
    // 검출 이벤트, 애니메이션 종료, 결과 뷰페이지 전송
    func detectingFinish(){
        self.detectingAni.stop()
        self.detectingAni.removeFromSuperview()
        self.performSegue(withIdentifier: "showResult", sender: self)
    }
    
    @IBAction func serverMobileSwitchAction(_ sender: Any) {
        if serverMobileSwitch.isOn {
            serverMobileLabel.text = "모바일"
            onDevice = true
        }
        else {
            serverMobileLabel.text = "서버"
            onDevice = false
        }
    }
    
    @IBAction func authSwitchAction(_ sender: Any) {
        if authSwitch.isOn {
            authLabel.text = "인증"
            idAuth = "1"
        }
        else {
            authLabel.text = "인증안함"
            idAuth = "0"
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.destination is ResultController{
            let newController = segue.destination as? ResultController
            newController?.resultJson = self.resultJson
            newController?.resultImage = self.resultImage
            newController?.originalImage = self.guideCropOri
            newController?.errorCode = self.errorCode
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.captureButton.isEnabled = true
        resultId = [String] ()
        resultName = ""
        resultJson = JSON()
        resultImage = UIImage()
        authJson = JSON()
        errorCode = 10
        self.finish = false
        captureSesssion.startRunning()
    }
    
    // 가이드 세팅
    func setupIdGuide(guideRect: CGRect) {
        // 가이드 레이어 추가
        let frameColor : UIColor = UIColor.red
        let subLayer = CAShapeLayer()
        subLayer.lineWidth = 2.0
        subLayer.strokeColor = frameColor.cgColor
        subLayer.path = UIBezierPath(roundedRect: guideRect, cornerRadius: 10.0).cgPath
        subLayer.fillColor = nil
        self.view.layer.addSublayer(subLayer)
        
        //뒷배경 색깔 및 투명도
        let maskLayerColor: UIColor = UIColor.white
        let maskLayerAlpha: CGFloat = 0.7

        // 신분증 가이드 백그라운드 설정
        let backLayer = CALayer()
        backLayer.frame = view.bounds
        backLayer.backgroundColor = maskLayerColor.withAlphaComponent(maskLayerAlpha).cgColor

        // 신분증 가이드 구역 설정
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: self.guideRect!, cornerRadius: 10.0)
        path.append(UIBezierPath(rect: view.bounds))
        maskLayer.path = path.cgPath
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        backLayer.mask = maskLayer
        self.view.layer.addSublayer(backLayer)
        
        self.view.bringSubviewToFront(captureButton)
        self.view.bringSubviewToFront(serverMobileSwitch)
        self.view.bringSubviewToFront(authSwitch)
        self.view.bringSubviewToFront(serverMobileLabel)
        self.view.bringSubviewToFront(authLabel)
    }
    
    func setUI() {
        // 신분증 타이틀
        let titleLabel = UILabel(frame: CGRect(x: self.previewView.frame.minX, y: self.previewView.frame.minY, width: self.view.frame.width, height: self.view.frame.height * 0.07))
        self.view.addSubview(titleLabel)
        titleLabel.text = "신분증 촬영"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .black
        titleLabel.backgroundColor = .white
        titleLabel.font = .systemFont(ofSize: 20)
        
        // 상단 주의 문구
        let notice1Label = UILabel(frame: CGRect(x: titleLabel.frame.minX, y: titleLabel.frame.maxY, width: self.view.frame.width, height: self.view.frame.height * 0.1))
        self.view.addSubview(notice1Label)
        notice1Label.text = "빨강색 사각형 안에 신분증을 바르게 놓고 \n 촬영바랍니다."
        notice1Label.numberOfLines = 0
        notice1Label.textAlignment = .center
        notice1Label.textColor = .black

        // 촬영 가이드
        let frameWidth = self.view.frame.size.width
        let idCardRatio: CGFloat = 1.59
        let guideWidth = frameWidth * 0.9
        let guideHeight = guideWidth / idCardRatio
        let guideX = frameWidth * 0.05
        let guideY = notice1Label.frame.maxY
        guideRect = CGRect(x: guideX, y: guideY, width: guideWidth, height: guideHeight)
        self.setupIdGuide(guideRect: guideRect!)
        
        // 하단 주의 문구
        let notice2Label = UILabel(frame: CGRect(x: titleLabel.frame.minX, y: guideRect!.maxY, width: self.view.frame.width, height: self.view.frame.height * 0.2))
        self.view.addSubview(notice2Label)
        notice2Label.text = "※ 촬영 시 주의 사항 \n - 빛 반사가 생기지 않도록 기울기를 조절하여 \n 촬영하세요 \n \n - 어두운 바탕에 신분증을 놓고 촬영하세요"
        notice2Label.numberOfLines = 0
        notice2Label.textAlignment = .center
        notice2Label.textColor = .black
        
        
        self.view.bringSubviewToFront(titleLabel)
        self.view.bringSubviewToFront(notice1Label)
        self.view.bringSubviewToFront(notice2Label)
        self.view.bringSubviewToFront(captureButton)
        self.view.bringSubviewToFront(serverMobileSwitch)
        self.view.bringSubviewToFront(authSwitch)
        self.view.bringSubviewToFront(serverMobileLabel)
        self.view.bringSubviewToFront(authLabel)
    }
    
}
