//
//  ViewController.swift
//  Example
//
//  Created by Xueqiang Ma on 20/11/17.
//  Copyright © 2017 Daniel Ma. All rights reserved.
//

import UIKit
import DPSwitch
import RxSwift

class ViewController: UIViewController {

    @IBOutlet weak var switchView: DPVerticalSwitchView!
    var observable: Observable<DPVerticalSwitchView.AnimationState>!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observable = self.switchView.statePS
        self.observable
            .subscribe(onNext: { (state) in
                print(state)
            }, onError: { (error) in
                
            }, onCompleted: {
                
            })
            .disposed(by: self.disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.switchView.moveSwitch(to: .bottom)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func didTapBtn(_ sender: UIButton) {
        switch self.switchView.currentState {
        case .top:
            self.switchView.moveSwitch(to: .bottom)
        case .bottom:
            self.switchView.moveSwitch(to: .top)
        }
    }
}

