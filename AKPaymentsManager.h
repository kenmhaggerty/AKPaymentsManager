//
//  AKPaymentsManager.h
//  AKPaymentsManager
//
//  Created by Ken M. Haggerty on 6/2/16.
//  Copyright © 2016 Peter Cicchino Youth Project. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import <Foundation/Foundation.h>

#import <PassKit/PKPaymentAuthorizationViewController.h>

#pragma mark - // PROTOCOLS (Public) //

#pragma mark - // DEFINITIONS (Public) //

typedef enum : NSUInteger {
    AKPaymentMethodAmericanExpress,
    AKPaymentMethodChinaUnionPay,
    AKPaymentMethodDiscover,
    AKPaymentMethodInterac,
    AKPaymentMethodMasterCard,
    AKPaymentMethodStoreAndDebit,
    AKPaymentMethodVisa
} AKPaymentMethod;

typedef enum : NSUInteger {
    AKPaymentProcessorNone = 0,
    AKPaymentProcessorAuthorizeNet
} AKPaymentProcessor;

@interface PKPaymentAuthorizationViewController (AKPaymentsManager)
@property (nonatomic) AKPaymentProcessor paymentProcessor;
@property (nonatomic, strong) NSDecimalNumber *total;
@property (nonatomic) void (^completionBlock)(PKPaymentAuthorizationStatus);
@end

@interface AKPaymentsManager : NSObject

// GENERIC //

+ (NSString *)stringForAuthorizationStatus:(PKPaymentAuthorizationStatus)status;

// VALIDATION //

+ (BOOL)applePayEnabled;
+ (BOOL)applePayEnabledForPaymentMethod:(AKPaymentMethod)paymentMethod;

// TRANSACTION //

+ (PKPaymentRequest *)paymentRequestForRecipient:(NSString *)recipient withMerchantId:(NSString *)merchantId lineItems:(NSArray <PKPaymentSummaryItem *> *)lineItems currency:(NSString *)currencyCode country:(NSString *)countryCode paymentMethods:(NSArray <NSNumber *> *)paymentMethods requiredBillingFields:(PKAddressField)billingFields shippingFields:(PKAddressField)shippingFields billingContact:(PKContact *)billingContact shippingContact:(PKContact *)shippingContact;
+ (void)presentTransactionViewControllerWithPaymentRequest:(PKPaymentRequest *)request paymentProcessor:(AKPaymentProcessor)processor completion:(void(^)(PKPaymentAuthorizationStatus))completionBlock;

@end
