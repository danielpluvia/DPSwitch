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
    public fileprivate(set) var currentState: AnimationState = .top
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    
    fileprivate let dampingRatio: CGFloat = 0.5                         // 0 -> More bouncing animation
    fileprivate let animationDuration: TimeInterval = 0.8
    
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

extension DPVerticalSwitchView {
    
    /// Change the state of the switch
    ///
    /// - Parameters:
    ///   - state: AnimationState
    ///   - withNotification: Should it use publish subject to emit event or not? False by default.
    public func moveSwitch(to state: AnimationState, withNotification: Bool = false) {
        guard state != self.currentState else {
            return
        }
        var destY = self.tapGestureView.center.y + self.switchView.frame.height/2.0
        switch state {
        case .top:
            destY = self.tapGestureView.center.y - self.switchView.frame.height/2.0
        case .bottom:
            destY = self.tapGestureView.center.y + self.switchView.frame.height/2.0
        }
        self.disableGestures()
        self.animator = UIViewPropertyAnimator(duration: self.animationDuration, dampingRatio: self.dampingRatio, animations: {
            self.switchView.center.y = destY
        })
        self.animator?.fractionComplete = 0.0001
        self.animator?.addCompletion({ (position: UIViewAnimatingPosition) in
            self.change(state: state, withNotification: withNotification)
        })
        let vector = CGVector(dx: 0, dy: 100.0 * 100)
        let springParameters = UISpringTimingParameters(dampingRatio:  self.dampingRatio, initialVelocity: vector)
        self.animator?.continueAnimation(withTimingParameters: springParameters, durationFactor: CGFloat(self.animationDuration / 2))
    }
    
    fileprivate func change(state destDtate: AnimationState, withNotification: Bool = true) {
        var stateChanged = false
        if self.currentState != destDtate {
            stateChanged = true
        }
        self.currentState = destDtate
        self.enableGestures()
        if withNotification && stateChanged {
            self.statePS.onNext(destDtate)
        }
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
        self.animator = UIViewPropertyAnimator(duration: self.animationDuration, dampingRatio: self.dampingRatio, animations: {
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
            if progress > 0.5 {
                let velocity = recognizer.velocity(in: self.tapGestureView)
                self.endPanning(translation: translation, velocity: velocity, needSameDirection: true)
            } else {
                animator.fractionComplete = progress
            }
        }
    }
    
    /// Actions should be done after ending panning.
    ///
    /// - Parameters:
    ///   - translation: CGPoint
    ///   - velocity: CGPoint
    ///   - needSameDirection: Should keep the same direction or not. true for keeping same direction, false for not matter.
    fileprivate func endPanning(translation: CGPoint, velocity: CGPoint, needSameDirection: Bool = false) {
        if let animator = self.animator {
            guard animator.fractionComplete < 1.0 else {
                self.enableGestures()
                return
            }
            if animator.fractionComplete == 0.0 {
                animator.fractionComplete = 0.0001
            }
            self.disableGestures()
            let viewHeight = self.tapGestureView.frame.size.height
            var destState: AnimationState = self.currentState
            switch self.currentState {
            case .top:
                if needSameDirection {
                    animator.isReversed = false
                    destState = .bottom
                } else {
                    if translation.y >= viewHeight / 3 || velocity.y >= 100 {
                        animator.isReversed = false
                        destState = .bottom
                    } else {
                        animator.isReversed = true
                        destState = .top
                    }
                }
            case .bottom:
                if needSameDirection {
                    animator.isReversed = false
                    destState = .top
                } else {
                    if translation.y <= (-viewHeight) / 3 || velocity.y <= -100 {
                        animator.isReversed = false
                        destState = .top
                    } else {
                        animator.isReversed = true
                        destState = .bottom
                    }
                }
            }
            animator.addCompletion({ (position: UIViewAnimatingPosition) in
                self.change(state: destState)
            })
            let vector = CGVector(dx: 0, dy: velocity.y * 10000)
            let springParameters = UISpringTimingParameters(dampingRatio:  self.dampingRatio, initialVelocity: vector)
            animator.continueAnimation(withTimingParameters: springParameters, durationFactor: CGFloat(self.animationDuration / 2))
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
        let position = recognizer.location(in: self.tapGestureView)
        if position.y > self.tapGestureView.frame.size.height / 2 {
            self.moveSwitch(to: .bottom, withNotification: true)
        } else {
            self.moveSwitch(to: .top, withNotification: true)
        }
    }
    
}

