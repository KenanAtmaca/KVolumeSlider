//
//
//  Copyright © 2018 Kenan Atmaca. All rights reserved.
//  kenanatmaca.com
//
//

import UIKit
import MediaPlayer
import AVFoundation

fileprivate class CustomProgressView: UIProgressView {
    
    var height:CGFloat = 1.0
    var weight:CGFloat = 10.0
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let size:CGSize = CGSize.init(width: weight, height: height)
        return size
    }
}

fileprivate enum Keys {
    static let AVAudioSessionOutputKey = "outputVolume"
}

class KVolumeSlider: UIView {
    
    private var session:AVAudioSession = AVAudioSession.sharedInstance()
    private var kWindow:UIWindow!
    private var volumeView:MPVolumeView = MPVolumeView(frame: CGRect.zero)
    private var progressView:CustomProgressView!
    private let screen = (UIScreen.main.bounds.size.width,UIScreen.main.bounds.size.height)
    private var hiddenBarCounter:Int = 0
    
    var backColor:UIColor = UIColor.gray.withAlphaComponent(0.3) {
        didSet {
            progressView.backgroundColor = backColor
        }
    }
    
    init() {
        let viewFrame = CGRect.init(x: 10, y: 10, width: screen.0 * 0.15, height: 5)
        super.init(frame: viewFrame)
        setupViews()
        setupAVSession()
        setupObservers()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupAVSession()
        setupObservers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        self.backgroundColor = .clear
        
        kWindow = UIApplication.shared.delegate?.window!
        
        progressView = CustomProgressView(progressViewStyle: .bar)
        progressView.height = 7
        progressView.weight = self.frame.width
        progressView.layer.cornerRadius = round(progressView.height / 2)
        progressView.clipsToBounds = true
        progressView.frame = self.frame
        progressView.tintColor = UIColor.gray.withAlphaComponent(0.3)
        progressView.progress = session.outputVolume
        progressView.backgroundColor = backColor
        progressView.alpha = 1
        addSubview(progressView)
        
        volumeView.setVolumeThumbImage(UIImage(), for: UIControlState())
        volumeView.isUserInteractionEnabled = false
        volumeView.alpha = 0.0001
        volumeView.showsRouteButton = false
        volumeView.backgroundColor = .clear
        addSubview(volumeView)
    }
    
    private func setupAVSession() {
        
        do {
            try session.setActive(true)
        } catch {
            print(error.localizedDescription)
        }
        
        session.addObserver(self, forKeyPath: Keys.AVAudioSessionOutputKey, options: .new, context: nil)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(notification:)), name: .UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
    }

    private func showProgressView(_ val:Float) {
        
        if hiddenBarCounter == 0 {
            kWindow.windowLevel = UIWindowLevelStatusBar + 1
        }
        
        hiddenBarCounter += 1
      
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn], animations: {
            self.progressView.alpha = 1
            self.progressView.progress = val
        }, completion: { (finish) in
            UIView.animate(withDuration: 2, animations: {
                self.progressView.alpha = 0
            }, completion: { (finish) in
                self.hiddenBarCounter -= 1
                if self.hiddenBarCounter == 0 {
                    self.kWindow.windowLevel = UIWindowLevelNormal
                }
            })
        })
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let change = change, let value = change[.newKey] as? Float, keyPath == Keys.AVAudioSessionOutputKey else {
            return
        }
 
        showProgressView(value)
    }
    
    @objc func applicationWillResignActive(notification: Notification) {
        session.removeObserver(self, forKeyPath: Keys.AVAudioSessionOutputKey, context: nil)
    }
    
    @objc func applicationDidBecomeActive(notification: Notification) {
        showProgressView(session.outputVolume)
        setupAVSession()
    }
    
    deinit {
        session.removeObserver(self, forKeyPath: Keys.AVAudioSessionOutputKey, context: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
    }
}//
