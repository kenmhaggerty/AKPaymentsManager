//
//  AKPaymentsManager+AuthorizeNet.m
//  pcyp-ios
//
//  Created by Ken M. Haggerty on 6/2/16.
//  Copyright © 2016 Peter Cicchino Youth Project. All rights reserved.
//

#pragma mark - // NOTES (Private) //

// Almost entirely copied via Authorize.Net example project //
// Source: https://github.com/AuthorizeNet/sdk-ios //

#pragma mark - // IMPORTS (Private) //

#import "AKPaymentsManager+AuthorizeNet.h"

#import <PassKit/PKContact.h>
#import <authorizenet-sdk/CreateTransactionRequest.h>
#import <CommonCrypto/CommonHMAC.h>

#pragma mark - // DEFINITIONS (Private) //

@implementation AKPaymentsManager (AuthorizeNet)

#pragma mark - // SETTERS AND GETTERS //

#pragma mark - // INITS AND LOADS //

#pragma mark - // PUBLIC METHODS //

+ (void)processPayment:(PKPayment *)payment withTotal:(NSDecimalNumber *)total apiLoginId:(NSString *)apiLoginId transactionSecretKey:(NSString *)transactionSecretKey viaAuthorizeNetWithCompletion:(void (^)(PKPaymentAuthorizationStatus))completionBlock {
    
    NSString *base64string = [AKPaymentsManager base64forData:payment.token.paymentData];
    NSDecimalNumber *invoiceNumber = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%d", arc4random() % 10000]];
    
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    
    //-------WARNING!----------------
    // Transaction key should never be stored on the device or embedded in the code.
    // Replace with Your Api log in ID and Transacation Secret Key.
    // This is a test merchant credentials to demo the capability, this would work with Visa cards only. Add a valid Visa card in the Passbook and make a sample transaction.
    
    NSString *dataDescriptor = @"FID=COMMON.APPLE.INAPP.PAYMENT";
    
    //-------WARNING!----------------
    // Transaction key should never be stored on the device or embedded in the code.
    // This part of the code that generates the finger print is present here only to make the sample app work.
    // Finger print generation should be done on the server.
    
    NSString *fpHashValue =[NSString stringWithFormat:@"%@^%ld^%lld^%@^", apiLoginId, (long)invoiceNumber.longValue, (long long)timestamp, total];
    NSString *fingerprintHashValue = [AKPaymentsManager HMAC_MD5_WithTransactionKey:transactionSecretKey fromValue:fpHashValue];
    
    CreateTransactionRequest *transactionRequestObj = [self createTransactionReqObjectWithApiLoginID:apiLoginId
                                                                                 fingerPrintHashData:fingerprintHashValue
                                                                                      sequenceNumber:invoiceNumber.intValue
                                                                                     transactionType:AUTH_ONLY
                                                                                     opaqueDataValue:base64string
                                                                                      dataDescriptor:dataDescriptor
                                                                                       invoiceNumber:invoiceNumber.stringValue
                                                                                         totalAmount:total
                                                                                         fpTimeStamp:timestamp
                                                                                          forPayment:payment];
    
    if (transactionRequestObj) {
        AuthNet *authNet = [AuthNet getInstance];
        [authNet setDelegate:[AKPaymentsManager sharedManager]];
        
        authNet.environment = ENV_TEST;
        // Submit the transaction for AUTH_CAPTURE.
        [authNet purchaseWithRequest:transactionRequestObj];
        
        // Submit the transaction for AUTH_ONLY.
//        [authNet authorizeWithRequest:transactionRequestObj];
    }
    
    completionBlock(PKPaymentAuthorizationStatusSuccess);
}

#pragma mark - // CATEGORY METHODS //

#pragma mark - // DELEGATED METHODS //

#pragma mark - // OVERWRITTEN METHODS //

#pragma mark - // PRIVATE METHODS //

+ (NSString*)base64forData:(NSData*)theData {
    
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] ;
}

+ (NSString *)HMAC_MD5_WithTransactionKey:(NSString *)secret fromValue:(NSString *)value {
    CCHmacContext    ctx;
    const char       *key = [secret UTF8String];
    const char       *str = [value UTF8String];
    unsigned char    mac[CC_MD5_DIGEST_LENGTH];
    char             hexmac[2 * CC_MD5_DIGEST_LENGTH + 1];
    char             *p;
    
    CCHmacInit( &ctx, kCCHmacAlgMD5, key, strlen( key ));
    CCHmacUpdate( &ctx, str, strlen(str) );
    CCHmacFinal( &ctx, mac );
    
    p = hexmac;
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++ ) {
        snprintf( p, 3, "%02x", mac[ i ] );
        p += 2;
    }
    
    return [NSString stringWithUTF8String:hexmac];
}

+ (CreateTransactionRequest *)createTransactionReqObjectWithApiLoginID:(NSString *)apiLoginID
                                                   fingerPrintHashData:(NSString *)fpHashData
                                                        sequenceNumber:(NSInteger)sequenceNumber
                                                       transactionType:(AUTHNET_ACTION)transactionType
                                                       opaqueDataValue:(NSString*)opaqueDataValue
                                                        dataDescriptor:(NSString *)dataDescriptor
                                                         invoiceNumber:(NSString *)invoiceNumber
                                                           totalAmount:(NSDecimalNumber *)totalAmount
                                                           fpTimeStamp:(NSTimeInterval)fpTimeStamp
                                                            forPayment:(PKPayment *)payment {
    // create the transaction.
    CreateTransactionRequest *transactionRequestObj = [CreateTransactionRequest createTransactionRequest];
    TransactionRequestType *transactionRequestType = [TransactionRequestType transactionRequest];
    
    transactionRequestObj.transactionRequest = transactionRequestType;
    transactionRequestObj.transactionType = transactionType;
    
    // Set the fingerprint.
    // Note: Finger print generation requires transaction key.
    // Finger print generation must happen on the server.
    
    FingerPrintObjectType *fpObject = [FingerPrintObjectType fingerPrintObjectType];
    fpObject.hashValue = fpHashData;
    fpObject.sequenceNumber = (int)sequenceNumber;
    fpObject.timeStamp = fpTimeStamp;
    
    transactionRequestObj.anetApiRequest.merchantAuthentication.fingerPrint = fpObject;
    transactionRequestObj.anetApiRequest.merchantAuthentication.name = apiLoginID;
    
    // Set the Opaque data
    OpaqueDataType *opaqueData = [OpaqueDataType opaqueDataType];
    opaqueData.dataValue= opaqueDataValue;
    opaqueData.dataDescriptor = dataDescriptor;
    
    PaymentType *paymentType = [PaymentType paymentType];
    paymentType.creditCard= nil;
    paymentType.bankAccount= nil;
    paymentType.trackData= nil;
    paymentType.swiperData= nil;
    paymentType.opData = opaqueData;
    
    // Billing address
    [AKPaymentsManager setAddress:transactionRequestObj.transactionRequest.billTo usingContact:payment.billingContact];
    
    // Shipping address
    [AKPaymentsManager setAddress:transactionRequestObj.transactionRequest.shipTo usingContact:payment.shippingContact];
    
    // Customer info
    transactionRequestObj.transactionRequest.customer.email = payment.shippingContact.emailAddress;
    
    transactionRequestType.amount = [NSString stringWithFormat:@"%@",totalAmount];
    transactionRequestType.payment = paymentType;
    transactionRequestType.retail.marketType = @"0"; //0
    transactionRequestType.retail.deviceType = @"7";
    
    OrderType *orderType = [OrderType order];
    orderType.invoiceNumber = invoiceNumber;
    NSLog(@"Invoice Number Before Sending the Request %@", orderType.invoiceNumber);
    
    return transactionRequestObj;
}

+ (void)setAddress:(NameAndAddressType *)address usingContact:(PKContact *)contact {
    
    NSPersonNameComponents *fullName = contact.name;
    NSString *firstName = fullName.givenName;
    NSString *lastName = fullName.familyName;
    
    CNPostalAddress *postalAddress = contact.postalAddress;
    NSString *streetAddress = postalAddress.street;
    NSString *city = postalAddress.city;
    NSString *zip = postalAddress.postalCode;
    NSString *state = postalAddress.state;
    NSString *country = postalAddress.country;
    
    NSString *phoneNumber = contact.phoneNumber.stringValue;
    
    address.firstName = firstName;
    address.lastName = lastName;
    address.address = streetAddress;
    address.city = city;
    address.state = state;
    address.zip = zip;
    address.country = country;
    
    if ([address isKindOfClass:[CustomerAddressType class]]) {
        ((CustomerAddressType *)address).phoneNumber = phoneNumber;
    }
}

@end
