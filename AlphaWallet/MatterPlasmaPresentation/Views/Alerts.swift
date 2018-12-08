//
//  Alerts.swift
//  AlphaWallet
//
//  Created by Anton Grigorev on 08/12/2018.
//

import UIKit

public struct Alerts {
    public func showErrorAlert(for viewController: UIViewController, error: Error?, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            var text: String?
            if let error = error {
                text = error.localizedDescription
            }
            let alert = UIAlertController(title: "Error", message: text ?? error?.localizedDescription, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                completion?()
            }
            alert.addAction(cancelAction)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    public func showSuccessAlert(for viewController: UIViewController, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Success", message: nil, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel) { (_) in
                completion?()
            }
            alert.addAction(cancelAction)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    public func showAccessAlert(for viewController: UIViewController, with text: String?, completion: ((Bool) -> Void)?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: text ?? "Yes?", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Yes", style: .default) { (_) in
                completion?(true)
            }
            let cancelAction = UIAlertAction(title: "No", style: .cancel) { (_) in
                completion?(false)
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    public func sendTxDialog(for viewController: UIViewController,
                             title:String? = nil,
                             subtitle:String? = nil,
                             actionTitle:String? = "Send",
                             cancelTitle:String? = "Cancel",
                             addressInputPlaceholder:String? = nil,
                             amountInputPlaceholder:String? = nil,
                             addressInputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                             amountInputKeyboardType:UIKeyboardType = UIKeyboardType.default,
                             completion: ((_ address: String?, _ amount: String?) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = addressInputPlaceholder
            textField.keyboardType = addressInputKeyboardType
        }
        alert.addTextField { (textField:UITextField) in
            textField.placeholder = amountInputPlaceholder
            textField.keyboardType = amountInputKeyboardType
        }
        alert.addAction(UIAlertAction(title: actionTitle,
                                      style: .destructive,
                                      handler: { (action:UIAlertAction) in
            guard let address = alert.textFields?.first, address.text != nil else {
                completion?(nil, nil)
                return
            }
                                        
            guard let amount = alert.textFields?[1], amount.text != nil else {
                completion?(nil, nil)
                return
            }
                                        
            completion?(address.text!, amount.text!)
        }))
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        
        viewController.present(alert, animated: true, completion: nil)
    }
}
