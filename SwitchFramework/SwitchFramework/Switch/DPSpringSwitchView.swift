//
//  DPSpringSwitchView.swift
//  SwitchFramework
//
//  Created by Xueqiang Ma on 20/11/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import UIKit

extension DPSpringSwitchView {
    enum AnimationState {
        case top
        case bottom
    }
}

class DPSpringSwitchView: UIView {
    
    @IBOutlet weak var switchBGView: UIView!
    @IBOutlet weak var switchView: UIView!
    
    fileprivate var animator: UIViewPropertyAnimator?
    fileprivate var currentState: AnimationState = .top
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.instanceFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.instanceFromNib()
    }
    
    fileprivate func instanceFromNib() {
        Bundle.main.loadNibNamed("DPSpringSwitchView", owner: self, options: nil)
        self.addSubview(self.switchBGView)
        self.switchBGView.frame = self.bounds
        self.switchBGView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.initGestures()
    }
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
}


extension DPSpringSwitchView {
    fileprivate func initGestures() {
        self.initTapGesture()
        self.initPanGesture()
    }
    
    fileprivate func enableGestures() {
        self.panGestureRecognizer.isEnabled = true
        self.tapGestureRecognizer.isEnabled = true
    }
    
    fileprivate func disableGestures() {
        self.panGestureRecognizer.isEnabled = false
        self.tapGestureRecognizer.isEnabled = false
    }
}

extension DPSpringSwitchView {
    
    fileprivate func initPanGesture() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        self.switchView.addGestureRecognizer(self.panGestureRecognizer)
    }
    
    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.switchBGView)
        switch recognizer.state {
        case .began:
            self.startPanning(recognizer: recognizer)
        case .changed:
            self.scrub(translation: translation)
        case .ended:
            let velocity = recognizer.velocity(in: self.switchBGView)
            self.endPanning(translation: translation, velocity: velocity)
        default:
            break
        }
    }
    
    fileprivate func startPanning(recognizer: UIPanGestureRecognizer) {
        var destY = self.switchBGView.center.y + self.switchView.frame.height/2.0
        switch self.currentState {
        case .top:
            destY = self.switchBGView.center.y + self.switchView.frame.height/2.0
        case .bottom:
            destY = self.switchBGView.center.y - self.switchView.frame.height/2.0
        }
        self.animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.6, animations: {
            self.switchView.center.y = destY
        })
    }
    
    fileprivate func scrub(translation: CGPoint) {
        if let animator = self.animator {
            let yTranslation = self.switchBGView.center.y + translation.y
            var progress: CGFloat = 0
            switch self.currentState {
            case .top:
                progress = (yTranslation / self.switchBGView.center.y) - 1
            case .bottom:
                progress = 1 - (yTranslation / self.switchBGView.center.y)
            }
            progress = max(0.0001, min(0.9999, progress))
            animator.fractionComplete = progress
        }
    }
    
    fileprivate func endPanning(translation: CGPoint, velocity: CGPoint) {
        if let animator = self.animator {
            self.disableGestures()
            let viewHeight = self.switchBGView.frame.size.height
            switch self.currentState {
            case .top:
                if translation.y >= viewHeight / 3 || velocity.y >= 100 {
                    animator.isReversed = false
                    animator.addCompletion({ (position: UIViewAnimatingPosition) in
                        self.currentState = .bottom
                        self.enableGestures()
                    })
                } else {
                    animator.isReversed = true
                    animator.addCompletion({ (position: UIViewAnimatingPosition) in
                        self.currentState = .top
                        self.enableGestures()
                    })
                }
            case .bottom:
                if translation.y <= (-viewHeight) / 3 || velocity.y <= -100 {
                    animator.isReversed = false
                    animator.addCompletion({ (position: UIViewAnimatingPosition) in
                        self.currentState = .top
                        self.enableGestures()
                    })
                } else {
                    animator.isReversed = true
                    animator.addCompletion({ (position: UIViewAnimatingPosition) in
                        self.currentState = .bottom
                        self.enableGestures()
                    })
                }
            }
            let vector = CGVector(dx: 0, dy: velocity.y * 100)
            let springParameters = UISpringTimingParameters(dampingRatio:  0.6, initialVelocity: vector)
            animator.continueAnimation(withTimingParameters: springParameters, durationFactor: 0.5)
        }
    }
    
}

extension DPSpringSwitchView {
    
    fileprivate func initTapGesture() {
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(recognizer:)))
        self.tapGestureRecognizer.numberOfTapsRequired = 1
        self.switchBGView.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    @objc func handleTapGesture(recognizer: UITapGestureRecognizer) {
        var destState: AnimationState = self.currentState
        let position = recognizer.location(in: self.switchBGView)
        var destY = self.switchBGView.center.y + self.switchView.frame.height/2.0
        if position.y > self.switchBGView.frame.size.height / 2 {
            destY = self.switchBGView.center.y + self.switchView.frame.height/2.0
            destState = .bottom
        } else {
            destY = self.switchBGView.center.y - self.switchView.frame.height/2.0
            destState = .top
        }
        self.animator = UIViewPropertyAnimator(duration: 1, dampingRatio: 0.6, animations: {
            self.switchView.center.y = destY
        })
        self.disableGestures()
        self.animator?.fractionComplete = 0.0001
        self.animator?.addCompletion({ (position: UIViewAnimatingPosition) in
            self.currentState = destState
            self.enableGestures()
        })
        let vector = CGVector(dx: 0, dy: 100.0 * 100)
        let springParameters = UISpringTimingParameters(dampingRatio:  0.6, initialVelocity: vector)
        self.animator?.continueAnimation(withTimingParameters: springParameters, durationFactor: 0.5)
    }
}

