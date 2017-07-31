//
//  TwitterManager.h
//  StixChat
//
//  Created by NguyenVuHuy on 7/25/17.
//  Copyright © 2017 GIANTY. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TwitterManager : NSObject

+ (TwitterManager*) shareInstance;

-(void)loginTwitter:(void(^)(BOOL))completion;

-(void)postTweat:(NSString*)message withData:(NSData*)imageData completionBlock:(void (^)(BOOL)) completion;

-(BOOL)hasLoggin;
@end
