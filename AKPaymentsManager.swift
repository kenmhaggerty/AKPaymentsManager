//
//  AKPaymentsManager.swift
//  AKPaymentsManager
//
//  Created by Ken M. Haggerty on 5/30/16.
//  Copyright © 2016 Ken M. Haggerty. All rights reserved.
//

import Foundation
import PassKit

class AKPaymentMethod: NSString {
    static var AmericanExpress = "PKPaymentNetworkAmex"
    static var UnionPay = "PKPaymentNetworkChinaUnionPay"
    static var Discover = "PKPaymentNetworkDiscover"
    static var Interac = "PKPaymentNetworkInterac"
    static var MasterCard = "PKPaymentNetworkMasterCard"
    static var StoreAndDebit = "PKPaymentNetworkPrivateLabel"
    static var Visa = "PKPaymentNetworkVisa"
}

private func convertPaymentMethods(methods: [AKPaymentMethod]) -> [String] {
    var networks: [String] = []
    for method in methods {
        networks.append(method as String)
    }
    return networks
}

enum AKPaymentProcessor {
    case AuthorizeNet
}

import ObjectiveC
private var paymentProcessorKey: UInt8 = 0
private var totalAmountKey: UInt8 = 1
extension PKPaymentAuthorizationViewController {
    var paymentProcessor: AKPaymentProcessor {
        get {
            return objc_getAssociatedObject(self, &paymentProcessorKey) as! AKPaymentProcessor
        }
        set(newValue) {
            objc_setAssociatedObject(self, &paymentProcessorKey, newValue as! AnyObject, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    var totalAmount: NSDecimalNumber {
        get {
            return objc_getAssociatedObject(self, &totalAmountKey) as! NSDecimalNumber
        }
        set(newValue) {
            objc_setAssociatedObject(self, &totalAmountKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

class AKPaymentsManager: NSObject, PKPaymentAuthorizationViewControllerDelegate {
    
    // MARK: DEFINITIONS (Public)
    
    // MARK: VARIABLES (Public)
    
    // MARK: VARIABLES (Private)
    
    // MARK: INITIALIZERS
    
    // MARK: FUNCTIONS (Public)
    
    class func applePayEnabled() -> Bool! {
        return PKPaymentAuthorizationViewController.canMakePayments()
    }
    
    class func applePayEnabled(forPaymentMethods methods: [AKPaymentMethod]) -> Bool! {
        let networks = convertPaymentMethods(methods)
        return PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks(networks)
    }
    
    class func transactionViewController(withPaymentRequest request: PKPaymentRequest!, lineItems: [PKPaymentSummaryItem], recipient: String!, paymentProcessor: AKPaymentProcessor!) -> UIViewController {
//        let request = PKPaymentRequest()
//        request.currencyCode = AKCurrency.Dollar.UnitedStates.rawValue
//        request.countryCode = AKCountry.UnitedStates.countryCode.rawValue
//        request.merchantIdentifier = merchantId
//        request.supportedNetworks = convertPaymentMethods(paymentMethods)
//        request.merchantCapabilities = .Capability3DS
//        request.requiredBillingAddressFields = .All
        
//        let donation = PKPaymentSummaryItem(label: "Peter Cicchino Youth Project", amount: NSDecimalNumber(string: "10.00"))
        var totalAmount: NSDecimalNumber
        for lineItem in lineItems {
            totalAmount = totalAmount.decimalNumberByAdding(lineItem.amount)
        }
        let total = PKPaymentSummaryItem(label: recipient, amount: totalAmount)
        var paymentSummaryItems = lineItems
        paymentSummaryItems.append(total)
        request.paymentSummaryItems = paymentSummaryItems
        
        let transactionViewController = PKPaymentAuthorizationViewController(paymentRequest: request)
        transactionViewController.delegate = AKPaymentsManager()
        transactionViewController.paymentProcessor = paymentProcessor
        
        return transactionViewController
    }
    
    // MARK: FUNCTIONS (PKPaymentAuthorizationViewControllerDelegate)
    
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        
        let totalAmount = controller.totalAmount
        
        switch controller.paymentProcessor {
        case .AuthorizeNet:
            processPayment(payment, withTotal:totalAmount, viaAuthorizeWithCompletion:completion)
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: FUNCTIONS (Private)
    
}