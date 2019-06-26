//
//  PasscodeLockPresenter.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/29/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit

open class PasscodeLockPresenter {
    
    fileprivate var mainWindow: UIWindow?
    
    fileprivate lazy var passcodeLockWindow: UIWindow = {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        window.windowLevel = UIWindow.Level(rawValue: 0)
        window.makeKeyAndVisible()
        
        return window
    }()
    
    fileprivate let passcodeConfiguration: PasscodeLockConfigurationType
    fileprivate var isPasscodePresented = false
    
    public init(mainWindow window: UIWindow?, configuration: PasscodeLockConfigurationType) {
        
        mainWindow = window
        mainWindow?.windowLevel = UIWindow.Level(rawValue: 1)
        passcodeConfiguration = configuration
    }
    
    open func presentPasscodeLock() {
        
        guard passcodeConfiguration.repository.hasPasscode else { return }
        guard !isPasscodePresented else { return }
        
        isPasscodePresented = true
        passcodeLockWindow.windowLevel = UIWindow.Level(rawValue: 2)
        // added by X 20160203
        passcodeLockWindow.isHidden = false
        // ~
        
        let passcodeLockVC = PasscodeLockViewController(state: .enterPasscode, configuration: passcodeConfiguration)
        
        passcodeLockVC.dismissCompletionCallback = { [weak self] in
            
            self?.dismissPasscodeLock()
        }
        
        passcodeLockWindow.rootViewController = passcodeLockVC
    }
    
    fileprivate func dismissPasscodeLock() {
        
        isPasscodePresented = false
        mainWindow?.windowLevel = UIWindow.Level(rawValue: 1)
        mainWindow?.makeKeyAndVisible()
        
        // Modified by X 20171026
//        UIView.animate(
//            withDuration: 0.5,
//            delay: 0,
//            usingSpringWithDamping: 1,
//            initialSpringVelocity: 0,
//            options: UIViewAnimationOptions(),
//            animations: { [weak self] in
//
//                self?.passcodeLockWindow.alpha = 0
//            },
//            completion: { [weak self] _ in
//
//                self?.passcodeLockWindow.windowLevel = 0
//                self?.passcodeLockWindow.rootViewController = nil
//                self?.passcodeLockWindow.alpha = 1
//                // added by X 20160203
//                self?.passcodeLockWindow.isHidden = true
//                // ~
//            }
//        )
        UIView.animate(withDuration: 0.4, animations: {
            self.passcodeLockWindow.alpha = 0
        }) { (finished) in
            self.passcodeLockWindow.windowLevel = UIWindow.Level(rawValue: 0)
            self.passcodeLockWindow.rootViewController = nil
            self.passcodeLockWindow.alpha = 1
            // added by X 20160203
            self.passcodeLockWindow.isHidden = true
            // ~
        }
        // ~
    }
}
