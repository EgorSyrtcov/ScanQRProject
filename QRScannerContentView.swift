//
//  QRScannerContentView.swift
//  ScanQRProject
//
//  Created by Egor Syrtcov on 19.01.22.
//

import UIKit
import AVFoundation

final class QRScannerContentView: UIView {
   
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var productID: UILabel!
    @IBOutlet weak var batch: UILabel!
    @IBOutlet weak var expireDate: UILabel!
    
    var completion: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = superview,
              let contentView = subviews.first,
              let previewLayer = videoView.layer.sublayers?.first else { return }
        frame = superview.bounds
        contentView.frame = superview.bounds
        videoView.frame = superview.bounds
        previewLayer.frame = superview.bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        let bundle = Bundle.init(for: QRScannerContentView.self)
        if let viewToAdd = bundle.loadNibNamed("QRScannerContentView", owner: self, options: nil), let contentView = viewToAdd.first as? UIView {
            addSubview(contentView)
        }
    }
    
    @IBAction func tapedOkButton(_ sender: UIButton) {
        completion?()
    }
    
}

extension QRScannerContentView {
    func configurate(overlayImage: UIImage, previewLayer: AVCaptureVideoPreviewLayer) {
        imageView.image = overlayImage
        previewLayer.videoGravity = .resizeAspectFill
        videoView.layer.insertSublayer(previewLayer, at: 0)
    }
    
    func stop() {
        removeFromSuperview()
        videoView.layer.sublayers?.first?.removeFromSuperlayer()
    }
    
    func update(from code: String?) {
        
        guard let code = code else { return }
        let codeComponents = components(from: code)
        
        productID.text = codeComponents.id
        batch.text = codeComponents.batch
        
        let date = codeComponents.expiryDate.getDate()
        let dateString = date?.toString()
        
        expireDate.text = dateString
    }
    
    func components(from code: String) -> (id: String, expiryDate: String, batch: String) {
        
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
}


extension Date {
    
    func toString(format: String = "dd/MM/yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

extension String {
    
    func getDate(with format: String = "yyyyMMdd") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = NSTimeZone(name: "UTC") as TimeZone?
        dateFormatter.dateFormat = format
        dateFormatter.locale = .current
        guard
            let date = dateFormatter.date(from: self)
        else {
            return nil
        }
        return date
    }
}
