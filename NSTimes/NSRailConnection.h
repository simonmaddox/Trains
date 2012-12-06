//
//  NSRailConnection.h
//  NSTimes
//
//  Created by Robert Dougan on 11/29/12.
//  Copyright (c) 2012 Robert Dougan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Train, TFHppleElement;

@protocol NSRailConnectionDelegate <NSObject>

- (NSURLRequest *)requestWithFrom:(NSString *)from to:(NSString *)to;
- (NSURLRequest *)requestForMoreWithFrom:(NSString *)from to:(NSString *)to;

- (NSString *)XPathQueryForTrains;

- (NSDate *)departureDateFromElement:(TFHppleElement *)element;
- (NSDate *)arrivalDateFromElement:(TFHppleElement *)element;
- (NSString *)platformFromElement:(TFHppleElement *)element;
- (NSString *)travelTimeFromElement:(TFHppleElement *)element;
- (NSString *)departureDelayFromElement:(TFHppleElement *)element;
- (NSString *)arrivalDelayFromElement:(TFHppleElement *)element;
- (BOOL)shouldDisplayTrain:(Train *)train;

@end

@interface NSRailConnection : NSObject

@property (nonatomic, assign) NSString *from;
@property (nonatomic, assign) NSString *to;

+ (NSRailConnection *)sharedInstance;

#pragma mark - Fetching

- (void)fetchWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure;
- (void)fetchMoreWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure;

@end
