
import UIKit

// 모델, 클래스 로드
class ObjectDetector {
    lazy var id_module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource: "id_0924_m2_160.torchscript", ofType: "pt"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()
    
    lazy var hangul_module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource: "hangul_591s7.torchscript", ofType: "pt"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model!")
        }
    }()
    
    lazy var id_classes: [String] = {
        if let filePath = Bundle.main.path(forResource: "id_classes", ofType: "txt"),
            let classes = try? String(contentsOfFile: filePath) {
            return classes.components(separatedBy: .newlines)
        } else {
            fatalError("classes file was not found.")
        }
    }()
    
    lazy var hangul_classes: [String] = {
        if let filePath = Bundle.main.path(forResource: "hangul591_list", ofType: "txt"),
            let classes = try? String(contentsOfFile: filePath) {
            return classes.components(separatedBy: .newlines)
        } else {
            fatalError("classes file was not found.")
        }
    }()
}
