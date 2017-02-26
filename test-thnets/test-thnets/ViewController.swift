//
//  ViewController.swift
//  test-thnets
//
//  Created by Eugenio Culurciello on 2/25/17.
//  Copyright © 2017 Eugenio Culurciello. All rights reserved.
//

import UIKit

import AVFoundation

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}


