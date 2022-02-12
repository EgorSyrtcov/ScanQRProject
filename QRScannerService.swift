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
    
    weak var delegate: QRScannerServiceDelegate?
    
    private enum QRScannerCameraPermission {
        case permissionDenied
        case permissionNotDetermined
        case permissionAllowed
    }
    
    private var contentView: QRScannerContentView?
    private var session: AVCaptureSession?
    
    private var currentQRCode: String?
}

extension QRScannerService {
    func start(from view: UIView, type: UrlActionCameraType) {
        let permission = requestPermission()
        guard permission != .permissionDenied else {
            delegate?.permissionDenied()
            return
        }
        
        guard configurateSession() else { return }
        let output = session?.outputs.first as? AVCaptureMetadataOutput
        
        output?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output?.metadataObjectTypes = type.types
        
        guard permission != .permissionDenied else {
            delegate?.permissionDenied()
            return
        }
        
        guard let session = session else {
            delegate?.failed()
            return
        }
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        makeContentView(from: view, previewLayer: videoPreviewLayer, overlayImage: type.icon)
        session.startRunning()
    }
    
    func stop() {
        session?.stopRunning()
        contentView?.stop()
        delegate?.recognize(code: currentQRCode)
        currentQRCode = nil
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
    func makeContentView(from parent: UIView, previewLayer: AVCaptureVideoPreviewLayer, overlayImage: UIImage) {
        let view = QRScannerContentView()
        view.configurate(overlayImage: overlayImage, previewLayer: previewLayer)
        view.completion = { [weak self] in
            self?.stop()
        }
        parent.addSubview(view)
        contentView = view
    }
}

private extension QRScannerService {
    func configurateSession() -> Bool {
        guard session == nil else { return true }
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            delegate?.failed()
            return false
        }
        
        session = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            session?.addInput(input)
        } catch {
            delegate?.failed()
            return false
        }
        
        let output = AVCaptureMetadataOutput()
        session?.addOutput(output)
        return true
    }
}

extension QRScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        let item = metadataObjects.first as? AVMetadataMachineReadableCodeObject
        currentQRCode = item?.stringValue
        contentView?.update(from: item?.stringValue)
    }
}
