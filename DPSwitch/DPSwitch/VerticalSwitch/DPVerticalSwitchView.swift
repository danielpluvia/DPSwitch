//
//  DPVerticalSwitchView.swift
//  DPSwitch
//
//  Created by Xueqiang Ma on 21/11/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import UIKit
import RxSwift

extension DPVerticalSwitchView {
    public enum AnimationState {
        case top
        case bottom
    }
}

public class DPVerticalSwitchView: UIView {
    
    public var statePS: PublishSubject = PublishSubject<AnimationState>()   // It will publish the current if there is a change of it
    
    @IBOutlet weak var tapGestureView: UIView!
    @IBOutlet public weak var switchBGView: UIView!
    @IBOutlet public weak var switchView: UIView!
    @IBOutlet public weak var topLabel: UILabel!
    @IBOutlet public weak var bottomLabel: UILabel!
    
    fileprivate var animator: UIViewPropertyAnimator?
    fileprivate var currentState: AnimationState = .top {
        didSet {
            guard self.currentState != oldValue else {
                return
            }
            self.statePS.onNext(currentState)
        }
    }
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    
    fileprivate var dampingRatio: CGFloat = 0.4                         // 0 -> More bouncing animation
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.instanceFromNib()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.instanceFromNib()
    }
    
    deinit {
        self.statePS.onCompleted()
    }
    
    fileprivate func instanceFromNib() {
        let bundle = Bundle(for: self.classForCoder)
        bundle.loadNibNamed("DPVerticalSwitchView", owner: self, options: nil)
        self.addSubview(self.switchBGView)
        self.switchBGView.frame = self.bounds
        self.switchBGView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.initGestures()
    }
    
}


// MARK: - Gestures management
extension DPVerticalSwitchView {
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

// MARK: - PanGesture
extension DPVerticalSwitchView {
    
    fileprivate func initPanGesture() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(recognizer:)))
        self.switchView.addGestureRecognizer(self.panGestureRecognizer)
    }
    
    @objc func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.tapGestureView)
        switch recognizer.state {
        case .began:
            self.startPanning(recognizer: recognizer)
        case .changed:
            self.scrub(translation: translation, recognizer: recognizer)
        case .ended:
            let velocity = recognizer.velocity(in: self.tapGestureView)
            self.endPanning(translation: translation, velocity: velocity)
        default:
            break
        }
    }
    
    fileprivate func startPanning(recognizer: UIPanGestureRecognizer) {
        var destY = self.tapGestureView.center.y + self.switchView.frame.height/2.0
        switch self.currentState {
        case .top:
            destY = self.tapGestureView.center.y + self.switchView.frame.height/2.0
        case .bottom:
            destY = self.tapGestureView.center.y - self.switchView.frame.height/2.0
        }
        self.animator = UIViewPropertyAnimator(duration: 1, dampingRatio: self.dampingRatio, animations: {
            self.switchView.center.y = destY
        })
    }
    
    fileprivate func scrub(translation: CGPoint, recognizer: UIPanGestureRecognizer) {
        if let animator = self.animator {
            let yTranslation = self.tapGestureView.center.y + translation.y
            var progress: CGFloat = 0
            switch self.currentState {
            case .top:
                progress = (yTranslation / self.tapGestureView.center.y) - 1
            case .bottom:
                progress = 1 - (yTranslation / self.tapGestureView.center.y)
            }
            progress = max(0.0001, min(0.9999, progress))
            if progress > 0.7 {
                let velocity = recognizer.velocity(in: self.tapGestureView)
                self.endPanning(translation: translation, velocity: velocity)
            } else {
                animator.fractionComplete = progress
            }
        }
    }
    
    fileprivate func endPanning(translation: CGPoint, velocity: CGPoint) {
        if let animator = self.animator {
            guard animator.fractionComplete != 1.0 else {
                self.enableGestures()
                return
            }
            self.disableGestures()
            let viewHeight = self.tapGestureView.frame.size.height
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
            let springParameters = UISpringTimingParameters(dampingRatio:  self.dampingRatio, initialVelocity: vector)
            animator.continueAnimation(withTimingParameters: springParameters, durationFactor: 0.5)
        }
    }
    
}

// MARK: - TapGesture
extension DPVerticalSwitchView {
    
    fileprivate func initTapGesture() {
        self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleTapGesture(recognizer:)))
        self.tapGestureRecognizer.numberOfTapsRequired = 1
        self.tapGestureView.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    @objc func handleTapGesture(recognizer: UITapGestureRecognizer) {
        self.disableGestures()
        var destState: AnimationState = self.currentState
        let position = recognizer.location(in: self.tapGestureView)
        var destY = self.tapGestureView.center.y + self.switchView.frame.height/2.0
        if position.y > self.tapGestureView.frame.size.height / 2 {
            destY = self.tapGestureView.center.y + self.switchView.frame.height/2.0
            destState = .bottom
        } else {
            destY = self.tapGestureView.center.y - self.switchView.frame.height/2.0
            destState = .top
        }
        self.animator = UIViewPropertyAnimator(duration: 1, dampingRatio: self.dampingRatio, animations: {
            self.switchView.center.y = destY
        })
        self.animator?.fractionComplete = 0.0001
        self.animator?.addCompletion({ (position: UIViewAnimatingPosition) in
            self.currentState = destState
            self.enableGestures()
        })
        let vector = CGVector(dx: 0, dy: 100.0 * 100)
        let springParameters = UISpringTimingParameters(dampingRatio:  self.dampingRatio, initialVelocity: vector)
        self.animator?.continueAnimation(withTimingParameters: springParameters, durationFactor: 0.5)
    }
    
}

