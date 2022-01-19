//
//  QRScannerContentView.swift
//  ScanQRProject
//
//  Created by Egor Syrtcov on 19.01.22.
//

import UIKit

final class QRScannerContentView: UIView {
   
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    var completion: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        let bundle = Bundle.init(for: QRScannerContentView.self)
        if let viewToAdd = bundle.loadNibNamed("QRScannerContentView", owner: self, options: nil), let contentView = viewToAdd.first as? UIView {
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
    @IBAction func tapedOkButton(_ sender: UIButton) {
        completion?()
    }
    
}
