import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
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

    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let request = URLRequest(url: url)
        webView.load(request)

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) { [weak self] in
            self?.dismiss(animated: true, completion: {
                print("Webview dismissed after \(self?.timeout ?? 0) seconds")
            })
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Webview failed to load with error: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Webview finished loading")
    }
}