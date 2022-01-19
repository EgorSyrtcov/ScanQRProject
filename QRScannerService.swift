//
//  QRScannerService.swift
//  ScanQRProject
//
//  Created by Egor Syrtcov on 17.01.22.
//
import UIKit
import AVFoundation

protocol QRScannerServiceDelegate: AnyObject {
    func failed()
    func recognize(code: String?)
    func permissionDenied()
}

final class QRScannerService: NSObject {
    
    private enum QRScannerCameraPermission {
        case permissionDenied
        case permissionNotDetermined
        case permissionAllowed
    }
    
    var overlayImage: UIImage!
    
    private var contentView: QRScannerContentView?
    private let session = AVCaptureSession()
    
    weak var delegate: QRScannerServiceDelegate?
}

extension QRScannerService {
    func start(from view: UIView, type: UrlActionCameraType) {
        let permission = requestPermission()
        guard permission != .permissionDenied else {
            delegate?.permissionDenied()
            return
        }
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            delegate?.failed()
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            session.addInput(input)
        } catch {
            delegate?.failed()
        }
        
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        
        
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        switch type {
        case .both:
            output.metadataObjectTypes = [.ean13, .qr, .dataMatrix]
            overlayImage = UIImage(named: "qr+barcode-view")
        case .bar:
            output.metadataObjectTypes = [.ean13, .qr]
            overlayImage = UIImage(named: "barcode-view")
        case .square:
            output.metadataObjectTypes = [.ean13, .dataMatrix]
            overlayImage = UIImage(named: "qr-view")
        }
        
        guard permission != .permissionDenied else {
            delegate?.permissionDenied()
            return
        }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        contentView = makeContentView(from: view, previewLayer: videoPreviewLayer)
        
        contentView?.completion = { [weak self] in
            self?.stop()
        }
        view.addSubview(contentView!)
        session.startRunning()
    }
    
    func stop() {
        guard let contentView = contentView else { return }
        contentView.removeFromSuperview()
        session.stopRunning()
    }
}

private extension QRScannerService {
    private func requestPermission() -> QRScannerCameraPermission {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .notDetermined: return .permissionNotDetermined
        case .authorized: return .permissionAllowed
        case .denied, .restricted: return .permissionDenied
        @unknown default: return .permissionNotDetermined
        }
    }
}

private extension QRScannerService {
    func makeContentView(from parent: UIView, previewLayer: AVCaptureVideoPreviewLayer) -> QRScannerContentView {
        parent.layoutIfNeeded()
        let view = QRScannerContentView()
        view.frame = parent.bounds
        view.imageView.image = overlayImage
        parent.addSubview(view)
        
        previewLayer.frame = parent.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        parent.layer.addSublayer(previewLayer)
        return view
    }
}

extension QRScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let item = metadataObjects.first as? AVMetadataMachineReadableCodeObject
        delegate?.recognize(code: item?.stringValue ?? nil)
        stop()
    }
}
