//
//  ViewController.swift
//  ScanQRProject
//
//  Created by Egor Syrtcov on 17.01.22.
//

import UIKit
import AVFoundation
import WebKit

enum UrlAction {
    case camera(UrlActionCameraType)
}

enum UrlActionCameraType: String {
    case both
    case square
    case bar
}

class ViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    private let qrScannerService = QRScannerService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        let url = Bundle.main.url(forResource: "receive", withExtension: "html")!
        let request = NSMutableURLRequest(url: url)
        webView?.load(request as URLRequest)
        qrScannerService.delegate = self
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated,
           let action = action(from: url) {
            qrScannerService.start(from: webView, type: .both)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    
    
    func action(from url: URL) -> UrlAction? {
        switch url.scheme?.lowercased() {
        case "hhtp", "https":
            return nil
        case "app":
            switch url.query?.components(separatedBy: "=").first {
            case "camera":
                if let param = url.query?.components(separatedBy: "=").last,
                    let type = UrlActionCameraType(rawValue: param) {
                    return .camera(type)
                }
                return .camera(.both)
            default:
                return nil
            }
        
        default:
            return nil
        }
    }
}

extension ViewController: QRScannerServiceDelegate {
    
    func failed() {
        print("Failed")
    }
    
    func recognize(code: String?) {
        guard let code = code else { return }
    }
    
    func permissionDenied() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .notDetermined: print("notDetermined"); break
        case .authorized: print("authorized"); break
        case .denied, .restricted: print("denied"); break
        @unknown default: break
        }
    }
    
    
}
