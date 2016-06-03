//
//  AKPaymentsManager.m
//  AKPaymentsManager
//
//  Created by Ken M. Haggerty on 6/2/16.
//  Copyright © 2016 Peter Cicchino Youth Project. All rights reserved.
//

#pragma mark - // NOTES (Private) //

#pragma mark - // IMPORTS (Private) //

#import "AKPaymentsManager.h"

#import "pcyp_ios-Swift.h"
#import <objc/runtime.h>

@import PassKit;

#pragma mark - // PROTOCOLS (Private) //

@protocol AKPaymentsProcessor <NSObject>
@optional
+ (void)processPayment:(PKPayment *)payment withTotal:(NSDecimalNumber *)total apiLoginId:(NSString *)apiLoginId transactionSecretKey:(NSString *)transactionSecretKey viaAuthorizeNetWithCompletion:(void (^)(PKPaymentAuthorizationStatus))completionBlock;
@end

#pragma mark - // DEFINITIONS (Private) //

@interface AKPaymentsManager () <PKPaymentAuthorizationViewControllerDelegate, AKPaymentsProcessor>

// GENERAL //

+ (instancetype)sharedManager;

// CONVERTERS //

+ (NSString *)networkForPaymentMethod:(AKPaymentMethod)paymentMethod;

@end

@implementation PKPaymentAuthorizationViewController (AKPaymentsManager)

- (void)setPaymentProcessor:(AKPaymentProcessor)paymentProcessor {
    
    objc_setAssociatedObject(self, @selector(paymentProcessor), [NSNumber numberWithInteger:paymentProcessor], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AKPaymentProcessor)paymentProcessor {
    
    NSNumber *paymentProcessorValue = objc_getAssociatedObject(self, @selector(paymentProcessor));
    return paymentProcessorValue.integerValue;
}

- (void)setTotal:(NSDecimalNumber *)total {
    
    objc_setAssociatedObject(self, @selector(total), total, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDecimalNumber *)total {
    
    return objc_getAssociatedObject(self, @selector(total));
}

- (void)setCompletionBlock:(void (^)(PKPaymentAuthorizationStatus))completionBlock {
    
    objc_setAssociatedObject(self, @selector(completionBlock), completionBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(PKPaymentAuthorizationStatus))completionBlock {
    
    return objc_getAssociatedObject(self, @selector(completionBlock));
}

@end

@implementation AKPaymentsManager

#pragma mark - // SETTERS AND GETTERS //

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS (Generic) //

+ (NSString *)stringForAuthorizationStatus:(PKPaymentAuthorizationStatus)status {
    
    switch (status) {
        case PKPaymentAuthorizationStatusInvalidShippingContact:
            return @"Invalid shipping contact";
        case PKPaymentAuthorizationStatusInvalidShippingPostalAddress:
            return @"Invalid shipping address";
        case PKPaymentAuthorizationStatusInvalidBillingPostalAddress:
            return @"Invalid billing address";
        case PKPaymentAuthorizationStatusPINRequired:
            return @"PIN required";
        case PKPaymentAuthorizationStatusPINIncorrect:
            return @"PIN incorrect";
        case PKPaymentAuthorizationStatusPINLockout:
            return @"Too many PIN attempts";
        case PKPaymentAuthorizationStatusSuccess:
            return @"Transaction complete";
        case PKPaymentAuthorizationStatusFailure:
            return @"Transaction failed";
    }
}

#pragma mark - // PUBLIC METHODS (Validation) //

+ (BOOL)applePayEnabled {
    
    return [PKPaymentAuthorizationViewController canMakePayments];
}

+ (BOOL)applePayEnabledForPaymentMethod:(AKPaymentMethod)paymentMethod {
    
    NSString *network = [AKPaymentsManager networkForPaymentMethod:paymentMethod];
    return [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:@[network]];
}

#pragma mark - // PUBLIC METHODS (Transaction) //

+ (PKPaymentRequest *)paymentRequestForRecipient:(NSString *)recipient withMerchantId:(NSString *)merchantId lineItems:(NSArray <PKPaymentSummaryItem *> *)lineItems currency:(NSString *)currencyCode country:(NSString *)countryCode paymentMethods:(NSArray <NSNumber *> *)paymentMethods requiredBillingFields:(PKAddressField)billingFields shippingFields:(PKAddressField)shippingFields billingContact:(PKContact *)billingContact shippingContact:(PKContact *)shippingContact {
    
    NSMutableArray *networks = [NSMutableArray arrayWithCapacity:paymentMethods.count];
    AKPaymentMethod paymentMethod;
    NSString *network;
    for (NSNumber *paymentMethodValue in paymentMethods) {
        paymentMethod = (AKPaymentMethod)paymentMethodValue.integerValue;
        network = [AKPaymentsManager networkForPaymentMethod:paymentMethod];
        [networks addObject:network];
    }
    
    NSDecimalNumber *totalAmount = [NSDecimalNumber zero];
    for (PKPaymentSummaryItem *lineItem in lineItems) {
        totalAmount = [totalAmount decimalNumberByAdding:lineItem.amount];
    }
    PKPaymentSummaryItem *total = [PKPaymentSummaryItem summaryItemWithLabel:recipient amount:totalAmount];
    NSArray *paymentSummaryItems = [lineItems arrayByAddingObject:total];
    
    PKPaymentRequest *paymentRequest = [[PKPaymentRequest alloc] init];
    paymentRequest.currencyCode = currencyCode;
    paymentRequest.countryCode = countryCode;
    paymentRequest.merchantIdentifier = merchantId;
    paymentRequest.supportedNetworks = networks;
    paymentRequest.merchantCapabilities = PKMerchantCapability3DS;
    paymentRequest.requiredBillingAddressFields = billingFields;
    paymentRequest.billingContact = billingContact;
    paymentRequest.requiredShippingAddressFields = shippingFields;
    paymentRequest.shippingContact = shippingContact;
    paymentRequest.paymentSummaryItems = paymentSummaryItems;
    
    return paymentRequest;
}

+ (void)presentTransactionViewControllerWithPaymentRequest:(PKPaymentRequest *)request paymentProcessor:(AKPaymentProcessor)processor completion:(void(^)(PKPaymentAuthorizationStatus))completionBlock {
    
    NSDecimalNumber *total = request.paymentSummaryItems.lastObject.amount;
    
    PKPaymentAuthorizationViewController *transactionViewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:request];
    transactionViewController.delegate = [AKPaymentsManager sharedManager];
    transactionViewController.total = total;
    transactionViewController.paymentProcessor = processor;
    transactionViewController.completionBlock = completionBlock;
    
    UIViewController *rootViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [rootViewController presentViewController:transactionViewController animated:YES completion:nil];
}

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS (PKPaymentAuthorizationViewControllerDelegate) //

//- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingContact:(PKContact *)contact completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKShippingMethod *> * _Nonnull, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
//    
//    //
//}
//
//- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectShippingMethod:(PKShippingMethod *)shippingMethod completion:(void (^)(PKPaymentAuthorizationStatus, NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
//    
//    //
//}
//
//- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didSelectPaymentMethod:(PKPaymentMethod *)paymentMethod completion:(void (^)(NSArray<PKPaymentSummaryItem *> * _Nonnull))completion {
//    
//    //
//}
//
//- (void)paymentAuthorizationViewControllerWillAuthorizePayment:(PKPaymentAuthorizationViewController *)controller {
//    
//    //
//}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller didAuthorizePayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
    NSDecimalNumber *total = controller.total;
    AKPaymentProcessor processor = controller.paymentProcessor;
    void (^completionBlock)(PKPaymentAuthorizationStatus) = controller.completionBlock;
    
    switch (processor) {
        case AKPaymentProcessorAuthorizeNet: {
            [AKPaymentsManager processPayment:payment withTotal:total apiLoginId:[Authorize apiLoginId] transactionSecretKey:[Authorize secretKey] viaAuthorizeNetWithCompletion:^(PKPaymentAuthorizationStatus status) {
                completionBlock(status);
                [controller.delegate paymentAuthorizationViewControllerDidFinish:controller];
            }];
            break;
        }
        default:
            break;
    }
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS (General) //

+ (instancetype)sharedManager {
    
    static AKPaymentsManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[AKPaymentsManager alloc] init];
    });
    return _sharedManager;
}

#pragma mark - // PRIVATE METHODS (Converters) //

+ (NSString *)networkForPaymentMethod:(AKPaymentMethod)paymentMethod {
    
    switch (paymentMethod) {
        case AKPaymentMethodAmericanExpress:
            return PKPaymentNetworkAmex;
        case AKPaymentMethodChinaUnionPay:
            return PKPaymentNetworkChinaUnionPay;
        case AKPaymentMethodDiscover:
            return PKPaymentNetworkDiscover;
        case AKPaymentMethodInterac:
            return PKPaymentNetworkInterac;
        case AKPaymentMethodMasterCard:
            return PKPaymentNetworkMasterCard;
        case AKPaymentMethodStoreAndDebit:
            return PKPaymentNetworkPrivateLabel;
        case AKPaymentMethodVisa:
            return PKPaymentNetworkVisa;
    }
    
    return nil;
}

@end
