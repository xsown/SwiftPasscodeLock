//
//  PasscodeLockViewController.swift
//  PasscodeLock
//
//  Created by Yanko Dimitrov on 8/28/15.
//  Copyright © 2015 Yanko Dimitrov. All rights reserved.
//

import UIKit
import LocalAuthentication

extension Notification.Name {
    // added by X 20160525
    static let passcodeViewControllerWillAppear =
        Notification.Name(rawValue: "passcodeViewControllerWillAppear")
    static let passcodeViewControllerDidAppear =
        Notification.Name(rawValue: "passcodeViewControllerDidAppear")
    static let passcodeViewControllerWillDisappear =
        Notification.Name(rawValue: "passcodeViewControllerWillDisappear")
    static let passcodeViewControllerDidDisappear =
        Notification.Name(rawValue: "passcodeViewControllerDidDisappear")
    static let passcodePreferredStatusbarStyle =
        Notification.Name(rawValue: "PasscodeViewControllerPreferredStatusbarStyle")
    // ~
    
    // added by X 20171127
    static let passcodePrefersStatusBarHidden = Notification.Name(rawValue: "PasscodeViewControllerPrefersStatusBarHidden")
    // ~
}

open class PasscodeLockViewController: UIViewController, PasscodeLockTypeDelegate {

    public enum LockState {
        case enterPasscode
        case setPasscode
        case changePasscode
        case removePasscode
        
        func getState() -> PasscodeLockStateType {
            
            switch self {
            case .enterPasscode: return EnterPasscodeState()
            case .setPasscode: return SetPasscodeState()
            case .changePasscode: return ChangePasscodeState()
            case .removePasscode: return EnterPasscodeState(allowCancellation: true)
            }
        }
    }
    
    // Added by X 20171026
    @IBOutlet open weak var backgroundImageView: UIImageView!
    // ~
    @IBOutlet open weak var titleLabel: UILabel?
    @IBOutlet open weak var descriptionLabel: UILabel?
    @IBOutlet open var placeholders: [PasscodeSignPlaceholderView] = [PasscodeSignPlaceholderView]()
    @IBOutlet open weak var cancelButton: UIButton?
    @IBOutlet open weak var deleteSignButton: UIButton?
    @IBOutlet open weak var touchIDButton: UIButton?
    @IBOutlet open weak var placeholdersX: NSLayoutConstraint?
    
    open var successCallback: ((_ lock: PasscodeLockType) -> Void)?
    open var dismissCompletionCallback: (() -> Void)?
    open var notificationCenter: NotificationCenter?
    
    internal let passcodeConfiguration: PasscodeLockConfigurationType
    internal var passcodeLock: PasscodeLockType
    internal var isPlaceholdersAnimationCompleted = true
    
    fileprivate var shouldTryToAuthenticateWithBiometrics = true
    
    // MARK: - Initializers
    
    public init(state: PasscodeLockStateType, configuration: PasscodeLockConfigurationType) {
        
        passcodeConfiguration = configuration
        passcodeLock = PasscodeLock(state: state, configuration: configuration)
        
        let nibName = "PasscodeLockView"
        let bundle: Bundle = bundleForResource(nibName, ofType: "nib")
        
        super.init(nibName: nibName, bundle: bundle)
        
        passcodeLock.delegate = self
        notificationCenter = NotificationCenter.default
    }
    
    public convenience init(state: LockState, configuration: PasscodeLockConfigurationType) {
        
        self.init(state: state.getState(), configuration: configuration)
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
        clearEvents()
    }
    
    // MARK: - View
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        updatePasscodeView()
        deleteSignButton?.isEnabled = false
        
        // added by X 20160526
        cancelButton?.setTitle(localizedStringFor("Cancel", comment: ""), for: UIControl.State())
        deleteSignButton?.setTitle(localizedStringFor("Delete", comment: ""), for: UIControl.State())

        if #available(iOS 11.0, *) {
            switch biometryType() {
            case .faceID:
                touchIDButton?.setTitle(localizedStringFor("UseFaceID", comment: ""), for: UIControl.State())
            default:
                touchIDButton?.setTitle(localizedStringFor("UseTouchID", comment: ""), for: UIControl.State())
            }
        }
        else {
            touchIDButton?.setTitle(localizedStringFor("UseTouchID", comment: ""), for: UIControl.State())
        }
        // ~
        
        setupEvents()
    }
    
    // added by X 20171129
    @available(iOS 11.0, *)
    fileprivate func biometryType() -> LABiometryType {
        let context = LAContext()
        var error: NSError? = nil
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType
        }
        else {
            if let error = error {
                print(error.localizedDescription)
            }
            return .LABiometryNone
        }
    }
    // ~
  
  // added by X 20181120
  override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    switch UIDevice.current.userInterfaceIdiom {
    case .pad:
      return .all
    default:
      return .portrait
    }
  }
  // ~
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // added by X 20160525
        //        NotificationCenter.default.post(
        //            name: Notification.Name(rawValue: type(of: self).NotificationNamePasscodeViewControllerWillAppear), object: self)
        NotificationCenter.default.post(name: .passcodeViewControllerWillAppear, object: self)
        // ~
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // added by X 20171219
        NotificationCenter.default.post(name: .passcodeViewControllerDidAppear, object: self)
        // ~
        
        if shouldTryToAuthenticateWithBiometrics {
            authenticateWithBiometrics()
        }
    }
    
    // added by X 20171219
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: .passcodeViewControllerWillDisappear, object: self)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .passcodeViewControllerDidDisappear, object: self)
    }
    // ~
    
    // added by X 20160526
    open var statusBarStyle: UIStatusBarStyle = .default
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        NotificationCenter.default.post(name: Notification.Name.passcodePreferredStatusbarStyle, object: self)
        return statusBarStyle
    }
    // ~
    
    // added by X 20171127
    open var isStatusBarHidden: Bool = false
    open override var prefersStatusBarHidden: Bool {
        NotificationCenter.default.post(name: Notification.Name.passcodePrefersStatusBarHidden, object: self)
        return isStatusBarHidden
    }
    // ~

    internal func updatePasscodeView() {
        
        titleLabel?.text = passcodeLock.state.title
        descriptionLabel?.text = passcodeLock.state.description
        cancelButton?.isHidden = !passcodeLock.state.isCancellableAction
        touchIDButton?.isHidden = !passcodeLock.isTouchIDAllowed
    }
    
    // MARK: - Events
    
    fileprivate func setupEvents() {
        
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appWillEnterForegroundHandler(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.addObserver(self, selector: #selector(PasscodeLockViewController.appDidEnterBackgroundHandler(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    fileprivate func clearEvents() {
        
        notificationCenter?.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter?.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc open func appWillEnterForegroundHandler(_ notification: Notification) {
        
        authenticateWithBiometrics()
    }
    
    @objc open func appDidEnterBackgroundHandler(_ notification: Notification) {
        
        shouldTryToAuthenticateWithBiometrics = false
    }
    
    // MARK: - Actions
    
    @IBAction func passcodeSignButtonTap(_ sender: PasscodeSignButton) {
        
        guard isPlaceholdersAnimationCompleted else {
            return
        }
        
        passcodeLock.addSign(sender.passcodeSign)
    }
    
    @IBAction func cancelButtonTap(_ sender: UIButton) {
        
        dismissPasscodeLock(passcodeLock)
    }
    
    @IBAction func deleteSignButtonTap(_ sender: UIButton) {
        
        passcodeLock.removeSign()
    }
    
    @IBAction func touchIDButtonTap(_ sender: UIButton) {
        
        passcodeLock.authenticateWithBiometrics()
    }
    
    fileprivate func authenticateWithBiometrics() {
        
        if passcodeConfiguration.shouldRequestTouchIDImmediately && passcodeLock.isTouchIDAllowed {
            
            passcodeLock.authenticateWithBiometrics()
        }
    }
    
    internal func dismissPasscodeLock(_ lock: PasscodeLockType) {
        
        if navigationController != nil {
            
            navigationController?.popViewController(animated: true)
            
        }
        else {
            
            dismiss(animated: true, completion: nil)
        }
        
        dismissCompletionCallback?()
    }
    
    // MARK: - Animations
    
    internal func animateWrongPassword() {
        
        deleteSignButton?.isEnabled = false
        isPlaceholdersAnimationCompleted = false
        
        animatePlaceholders(placeholders, toState: .error)
        
        placeholdersX?.constant = -40
        view.layoutIfNeeded()
        
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.2,
            initialSpringVelocity: 0,
            options: [],
            animations: {
                
                self.placeholdersX?.constant = 0
                self.view.layoutIfNeeded()
        },
            completion: { completed in
                
                self.isPlaceholdersAnimationCompleted = true
                self.animatePlaceholders(self.placeholders, toState: .inactive)
        })
    }
    
    internal func animatePlaceholders(_ placeholders: [PasscodeSignPlaceholderView], toState state: PasscodeSignPlaceholderView.State) {
        
        for placeholder in placeholders {
            
            placeholder.animateState(state)
        }
    }
    
    fileprivate func animatePlacehodlerAtIndex(_ index: Int, toState state: PasscodeSignPlaceholderView.State) {
        
        guard index < placeholders.count && index >= 0 else {
            return
        }
        
        placeholders[index].animateState(state)
    }
    
    // MARK: - PasscodeLockDelegate
    
    open func passcodeLockDidSucceed(_ lock: PasscodeLockType) {
        
        deleteSignButton?.isEnabled = true
        animatePlaceholders(placeholders, toState: .inactive)
        dismissPasscodeLock(lock)
        successCallback?(lock)
    }
    
    open func passcodeLockDidFail(_ lock: PasscodeLockType) {
        
        animateWrongPassword()
    }
    
    open func passcodeLockDidChangeState(_ lock: PasscodeLockType) {
        
        updatePasscodeView()
        animatePlaceholders(placeholders, toState: .inactive)
        deleteSignButton?.isEnabled = false
    }
    
    open func passcodeLock(_ lock: PasscodeLockType, addedSignAtIndex index: Int) {
        
        animatePlacehodlerAtIndex(index, toState: .active)
        deleteSignButton?.isEnabled = true
    }
    
    open func passcodeLock(_ lock: PasscodeLockType, removedSignAtIndex index: Int) {
        
        animatePlacehodlerAtIndex(index, toState: .inactive)
        
        if index == 0 {
            
            deleteSignButton?.isEnabled = false
        }
    }
}

