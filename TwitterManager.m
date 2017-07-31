//
//  TwitterManager.m
//  StixChat
//
//  Created by NguyenVuHuy on 7/25/17.
//  Copyright © 2017 GIANTY. All rights reserved.
//

#import "TwitterManager.h"
#import "TwitterDefine.h"
#import <TwitterKit/TwitterKit.h>

@interface TwitterManager()

@property (nonatomic, strong) NSString* bearer_token;

@property (nonatomic, strong) NSString* userId;

@end

@implementation TwitterManager

static TwitterManager* instance = nil;

+ (TwitterManager*) shareInstance {
    if (!instance) {
        instance = [[TwitterManager alloc] init];
        // Instantiates TWTROAuthSigning
//        TWTROAuthSigning *headerSigner = [[TWTROAuthSigning alloc] initWithAuthConfig:[Twitter sharedInstance].authConfig authSession:[Twitter sharedInstance].sessionStore.session];
    }
    
    return instance;
}

//-(void)requestOauth {
//    
//    NSString* credentialsString = [NSString stringWithFormat:@"%@:%@",TWTConsumerKey, TWTConsumerSecrectKey];
//    NSData *plainData = [credentialsString dataUsingEncoding:NSUTF8StringEncoding];
//    NSString *credentials = nil;
//    if ([plainData respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
//        credentials = [plainData base64EncodedStringWithOptions:kNilOptions];  // iOS 7+
//    }
//}

// login to twitter
-(void)loginTwitter:(void(^)(BOOL))completion {
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        if (session) {
//            NSString *userID = [Twitter sharedInstance].sessionStore.session.userID;
//            TWTRAPIClient *client = [[TWTRAPIClient alloc] initWithUserID:userID];
            completion(TRUE);
        } else {
            completion(FALSE);
            DLog(@"Login Twitter error: %@", [error localizedDescription]);
        }
    }];
}

// Upload media to twitter server first - get MediaId for post Tweat
-(void)uploadMedia:(NSData*)mediaData contentType:(NSString*)contentType completionBlock:(void(^)(NSString*)) completion {
    TWTRAPIClient *client = [TWTRAPIClient clientWithCurrentUser];
    [client uploadMedia:mediaData contentType:contentType completion:^(NSString * _Nullable mediaID, NSError * _Nullable error) {
        if (error != nil) {
            DLog(@"Upload Media Twitter error: %@", [error localizedDescription]);
            completion(nil);
        } else {
            // upload media successful
            completion(mediaID);
        }
    }];
}

//Post tweat to Twitter: contains message and/ or gif
-(void)postTweat:(NSString*)message withData:(NSData*)imageData completionBlock:(void (^)(BOOL)) completion {
    
    if (imageData != nil) {
        [self uploadMedia:imageData contentType:@"image/gif" completionBlock:^(NSString *mediaId) {
            if (mediaId != nil) {
                TWTRAPIClient *client = [TWTRAPIClient clientWithCurrentUser];
                NSDictionary* content = @{ @"status": message,
                                           @"media_ids": mediaId
                                           };
                NSError* postError;
                NSURLRequest* request = [client URLRequestWithMethod:@"POST" URL:TWTPostTweatEndPoint parameters:content error:&postError];
                [client sendTwitterRequest:request completion:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                    if (connectionError == nil) {
                        DLog("post twitter completed");
                        completion(YES);
                    } else {
                        DLog("post with twitter failed with error: %@", connectionError.localizedDescription);
                        completion(NO);
                    }
                }];
            } else {
                completion(NO);
            }
        }];
    } else {
        TWTRAPIClient *client = [TWTRAPIClient clientWithCurrentUser];
        NSDictionary* content = @{ @"status": message
                                   };
        NSError* postError;
        NSURLRequest* request = [client URLRequestWithMethod:@"POST" URL:TWTPostTweatEndPoint parameters:content error:&postError];
        [client sendTwitterRequest:request completion:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
            if (connectionError == nil) {
                DLog("post twitter completed");
                completion(YES);
            } else {
                DLog("post with twitter failed with error: %@", connectionError.localizedDescription);
                completion(NO);
            }
        }];
    }
}

//Check if user has logged in
-(BOOL)hasLoggin {
    return [Twitter sharedInstance].sessionStore.session != nil;
}

@end
