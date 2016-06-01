//
//  AKPaymentsManager+AuthorizeNet.swift
//  pcyp-ios
//
//  Created by Ken M. Haggerty on 5/31/16.
//  Copyright © 2016 Peter Cicchino Youth Project. All rights reserved.
//

import Foundation
import PassKit

extension AKPaymentsManager {
    func processPayment(payment: PKPayment, withTotal total: NSDecimalNumber, viaAuthorizeWithCompletion completion:(PKPaymentAuthorizationStatus) -> Void) {
        let billingContact = payment.billingContact!
        let email = billingContact.emailAddress
        let name = billingContact.name
        let postalAddress = billingContact.postalAddress
        let streetAddress = postalAddress?.street
        let city = postalAddress?.city
        let state = postalAddress?.state
        let zipCode = postalAddress?.postalCode
        let country = postalAddress?.country
        let countryCode = postalAddress?.ISOCountryCode
        
        NSString *base64string = [CreditCardViewController  base64forData:payment.token.paymentData];
        NSDecimalNumber* invoiceNumber = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%d", arc4random() % 10000]];
        
        let timestamp = NSDate().timeIntervalSince1970
        
        //-------WARNING!----------------
        // Transaction key should never be stored on the device or embedded in the code.
        // Replace with Your Api log in ID and Transacation Secret Key.
        // This is a test merchant credentials to demo the capability, this would work with Visa cards only. Add a valid Visa card in the Passbook and make a sample transaction.
        
        let apiLoginID = Authorize.APILoginID // replace with YOUR_APILOGIN_ID
        let transactionSecretKey = Authorize.TransactionKey // replace with YOUR_TRANSACTION_SECRET_KEY
        
        NSString *dataDescriptor                 = @"FID=COMMON.APPLE.INAPP.PAYMENT";
        
        //-------WARNING!----------------
        // Transaction key should never be stored on the device or embedded in the code.
        // This part of the code that generates the finger print is present here only to make the sample app work.
        // Finger print generation should be done on the server.
        
        NSString *fingerprintHashValue = [self prepareFPHashValueWithApiLoginID:apiLogInID
            transactionSecretKey:transactionSecretKey
            sequenceNumber:invoiceNumber.longValue
            totalAmount:amount
            timeStamp:fingerprintTimestamp];
        
        CreateTransactionRequest
        
        CreateTransactionRequest * transactionRequestObj = [self createTransactionReqObjectWithApiLoginID:apiLogInID
            fingerPrintHashData:fingerprintHashValue
            sequenceNumber:invoiceNumber.intValue
            transactionType:AUTH_ONLY
            opaqueDataValue:encryptedPaymentData
            dataDescriptor:dataDescriptor
            invoiceNumber:invoiceNumber.stringValue
            totalAmount:amount
            fpTimeStamp:fingerprintTimestamp];
        if (transactionRequestObj != nil)
        {
            
            AuthNet *authNet = [AuthNet getInstance];
            [authNet setDelegate:self];
            
            authNet.environment = ENV_TEST;
            // Submit the transaction for AUTH_CAPTURE.
            [authNet purchaseWithRequest:transactionRequestObj];
            
            // Submit the transaction for AUTH_ONLY.
            //[authNet authorizeWithRequest:transactionRequestObj];
        }
        
        completion(PKPaymentAuthorizationStatusSuccess);
    }
}

func convertDataToString(data: NSData) -> String {
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

func convertDataToString(data: NSData) -> String {
    let input: UInt8 = UInt8(data.bytes)
    var length: Int = data.characters.count
    var table: Character = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    var data: NSMutableData = NSMutableData.dataWithLength(((length + 2) / 3) * 4)
    var output: UInt8 = UInt8(data.mutableBytes)
    var i: Int
    for i = 0; i < length; i += 3 {
        var value: Int = 0
        var j: Int
        for j = i; j < (i + 3); j++ {
            value <<= 8
            if j < length {
                value |= (0xFF & input[j])
            }
        }
        var theIndex: Int = (i / 3) * 4
        output[theIndex + 0] = table[(value >> 18) & 0x3F]
        output[theIndex + 1] = table[(value >> 12) & 0x3F]
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6) & 0x3F] : "="
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0) & 0x3F] : "="
    }
    return String(data: data, encoding: NSASCIIStringEncoding)
}

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
