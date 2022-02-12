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
    case both = ""
    case square = "qr"
    case bar = "bar"
    
    var icon: UIImage {
        switch self {
        case .both: return UIImage(named: "qr+barcode-view")!
        case .square: return UIImage(named: "qr-view")!
        case .bar: return UIImage(named: "barcode-view")!
        }
    }
    
    var types: [AVMetadataObject.ObjectType] {
        switch self {
        case .both: return [.ean13, .ean8, .dataMatrix]
        case .square: return [.qr, .dataMatrix]
        case .bar: return [.ean13, .ean8]
        }
    }
}

class ViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    private let qrScannerService = QRScannerService()
    private var type: UrlActionCameraType?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        let url = Bundle.main.url(forResource: "receive_1", withExtension: "html")!
        let request = NSMutableURLRequest(url: url)
        webView?.load(request as URLRequest)
        qrScannerService.delegate = self
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, navigationAction.navigationType == .linkActivated,
           let action = action(from: url) {
            qrScannerService.start(from: webView, type: type ?? .both)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    
    
    func action(from url: URL) -> UrlAction? {
        
        type = nil
        
        switch url.scheme?.lowercased() {
        case "hhtp", "https":
            return nil
        case "app":
            switch url.query?.components(separatedBy: "=").first {
            case "camera":
                if let param = url.query?.components(separatedBy: "=").last,
                   let type = UrlActionCameraType(rawValue: param) {
                    self.type = type
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
        let codeComponents = components(from: code)
        
        let date = codeComponents.expiryDate.getDate()
        let dateString = date?.toString() ?? ""
        
        webView.evaluateJavaScript("javascript: " + "updateFromNative(\"" + codeComponents.id + "\",\"" + codeComponents.batch + "\",\"" + dateString + "\")", completionHandler: nil)
    }
    
    func permissionDenied() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .notDetermined: presentAlert(); break
        case .authorized: print("authorized"); break
        case .denied, .restricted: presentAlert(); break
        @unknown default: break
        }
    }
    
    private func components(from code: String) -> (id: String, expiryDate: String, batch: String) {
        
        let code = code.replacingOccurrences(of: "(01)", with: "")
            .replacingOccurrences(of: "(17)", with: " ")
            .replacingOccurrences(of: "(10)", with: " ")
        let components = code.components(separatedBy: " ")
        var id: String {
            return components.first ?? ""
        }
        var expiryDate: String {
            guard components.count > 1 else { return "" }
            return components[1]
        }
        var batch: String {
            guard components.count > 2 else { return "" }
            return components[2]
        }
        return (id, expiryDate, batch)
    }
    
    private func presentAlert() {
        let alert = UIAlertController(title: "Would Like to Access the Camera", message: "We need to access your camera for scanning QR codes", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
           print("OK")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
