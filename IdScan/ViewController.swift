import UIKit


class ViewController: UIViewController {
    
    private var inferencer: ObjectDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        // 모델 로드
        inferencer = ObjectDetector()
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.destination is DetectionController{
            let newController = segue.destination as? DetectionController
            newController?.inferencer = self.inferencer
        }
    }
}
