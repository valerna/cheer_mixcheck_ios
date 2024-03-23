import UIKit

class SplashViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.switchToMainScreen), userInfo: nil, repeats: false)
    }
    
    @objc func switchToMainScreen() {
        // Transition to the QR code reader screen
        if let qrReaderVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "QRReaderViewController") as? QRReaderViewController {
            qrReaderVC.modalPresentationStyle = .fullScreen
            qrReaderVC.modalTransitionStyle = .crossDissolve
            present(qrReaderVC, animated: true, completion: nil)
        }
    }
}