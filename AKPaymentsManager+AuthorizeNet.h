//
//  AKPaymentsManager+AuthorizeNet.h
//  pcyp-ios
//
//  Created by Ken M. Haggerty on 6/2/16.
//  Copyright © 2016 Peter Cicchino Youth Project. All rights reserved.
//

#pragma mark - // NOTES (Public) //

#pragma mark - // IMPORTS (Public) //

#import "AKPaymentsManager.h"

#import <PassKit/PKPayment.h>
#import <authorizenet-sdk/AuthNet.h>

#pragma mark - // PROTOCOLS //

@protocol AKPaymentsManager <NSObject>
@optional
+ (instancetype)sharedManager;
@end

#pragma mark - // DEFINITIONS (Public) //

@interface AKPaymentsManager (AuthorizeNet) <AuthNetDelegate, AKPaymentsManager>
+ (void)processPayment:(PKPayment *)payment withTotal:(NSDecimalNumber *)total apiLoginId:(NSString *)apiLoginId transactionSecretKey:(NSString *)transactionSecretKey viaAuthorizeNetWithCompletion:(void (^)(PKPaymentAuthorizationStatus))completionBlock;
@end
