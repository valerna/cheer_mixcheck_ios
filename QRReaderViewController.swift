import UIKit
import AVFoundation
import WebKit

class QRReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the capture session
        captureSession = AVCaptureSession()

        // Try to set up the capture device (camera)
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            failed(message: "Failed to get the camera device")
            return
        }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            failed(message: "Failed to create video input: \(error.localizedDescription)")
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed(message: "Unable to add video input to capture session")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed(message: "Unable to add metadata output to capture session")
            return
        }

        // Set up the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Overlay the logo
        let logoImageView = UIImageView(image: UIImage(named: "mixcheck"))
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        view.bringSubviewToFront(logoImageView)

        // Constraints for the logo to position at the top and center
        NSLayoutConstraint.activate([
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100)
        ])

        // Start the capture session
        captureSession.startRunning()
    }

    func failed(message: String) {
        let ac = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            if stringValue.starts(with: "https://mixcheck.app/") {
                print("Valid URL: \(stringValue)")
                displayScanSuccessAnimation()
                if let url = URL(string: stringValue) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        let webViewController = WebViewController(url: url, timeout: 4)
                        self?.present(webViewController, animated: true)
                    }
                }
            } else {
                print("Invalid URL")
                DispatchQueue.main.async { [weak self] in
                    let alert = UIAlertController(title: "Invalid QR Code", message: "The scanned QR code does not contain a valid URL for this app.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self?.captureSession.startRunning()
                    })
                    self?.present(alert, animated: true)
                }
            }
        }
    }

    func displayScanSuccessAnimation() {
        let overlayView = UIView(frame: self.view.bounds)
        overlayView.backgroundColor = UIColor.green.withAlphaComponent(0.3)
        view.addSubview(overlayView)
        UIView.animate(withDuration: 1.0, animations: {
            overlayView.alpha = 0
        }) { _ in
            overlayView.removeFromSuperview()
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

class WebViewController: UIViewController {
    private var webView: WKWebView!
    private var url: URL
    private var timeout: TimeInterval

    init(url: URL, timeout: TimeInterval) {
        self.url = url
        self.timeout = timeout
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: self.view.bounds)
        view.addSubview(webView)

        let request = URLRequest(url: url)
        webView.load(request)

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.dismiss(animated: true, completion: {
                print("Webview dismissed after \(self?.timeout ?? 0) seconds")
            })
        }
    }
}