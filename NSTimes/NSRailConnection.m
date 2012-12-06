//
//  NSRailConnection.m
//  NSTimes
//
//  Created by Robert Dougan on 11/29/12.
//  Copyright (c) 2012 Robert Dougan. All rights reserved.
//

#import "NSRailConnection.h"

#import "Train.h"

#import "DDXML.h"
#import "AFNetworking.h"
#import "TFHpple.h"

@implementation NSRailConnection

@synthesize from = _from, to = _to;

static NSRailConnection *sharedInstance = nil;

+ (NSRailConnection *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[NSRailConnection alloc] init];
        [sharedInstance setFrom:@"Haarlem"];
        [sharedInstance setTo:@"Amsterdam"];
    }
    
    return sharedInstance;
}

#pragma mark - Fetching

- (void)fetchWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure
{
    NSURLRequest *urlRequest = [self.dataSource requestWithFrom:self.from to:self.to];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        TFHpple *document = [[TFHpple alloc] initWithHTMLData:responseObject];
        NSArray *elements = [document searchWithXPathQuery:[self.dataSource XPathQueryForTrains]];
        
        success([self trainsWithHTMLElements:elements]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    [requestOperation start];
}

- (void)fetchMoreWithSuccess:(void (^)(NSArray *trains))success failure:(void (^)(NSError *error))failure
{
    NSURLRequest *urlRequest = [self.dataSource requestForMoreWithFrom:self.from to:self.to];
    
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        success([self trainsWithXMLData:responseObject]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    [requestOperation start];
}

#pragma mark - Element searching

- (NSArray *)trainsWithHTMLElements:(NSArray *)elements {
    NSMutableArray *trains = [NSMutableArray array];
    BOOL foundSelected = NO;
    
    for (TFHppleElement *element in elements) {
        Train *train = [[Train alloc] init];
        
        // Check if something has been selected
        if (!foundSelected) {
            if ([[element objectForKey:@"class"] isEqualToString:@"selected"]) {
                foundSelected = YES;
            } else {
                continue;
            }
        }
        
        // Simple fields
        [train setPlatform:[self.dataSource train:train platformFromElement:element]];
        [train setTravelTime:[self.dataSource train:train travelTimeFromElement:element]];
        
        // Delays
        [train setDepartureDelay:[self.dataSource train:train departureDelayFromElement:element]];
        [train setArrivalDelay:[self.dataSource train:train arrivalDelayFromElement:element]];
        
        
        [train setDeparture:[self.dataSource train:train departureDateFromElement:element]];
        [train setArrival:[self.dataSource train:train arrivalDateFromElement:element]];
        
        if ([self.dataSource shouldDisplayTrain:train]){
            [trains addObject:train];
        }
    }
    
    return trains;
}

- (NSArray *)trainsWithXMLData:(NSData *)data {
    NSMutableArray *trains = [NSMutableArray array];
    
    // TODO: SM - Need to implement this
    /*DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:data options:0 error:nil];
    NSArray *elements = [document nodesForXPath:@"//reistijden/reizen/reis" error:nil];
    
    for (DDXMLElement *element in elements) {
        Train *train = [[Train alloc] init];
    
        // Simple fields
        [train setPlatform:[self.dataSource train:train platformFromElement:element]];
        [train setTravelTime:[self.dataSource train:train travelTimeFromElement:element]];
        
        // Delays
        [train setDepartureDelay:[self.dataSource train:train departureDelayFromElement:element]];
        [train setArrivalDelay:[self.dataSource train:train arrivalDelayFromElement:element]];
        

        [train setDeparture:[self.dataSource train:train departureDateFromElement:element]];
        [train setArrival:[self.dataSource train:train arrivalDateFromElement:element]];
        
        if ([self.dataSource shouldDisplayTrain:train]){
            [trains addObject:train];
        }
    }*/
    
    return trains;
}

#pragma mark - Helpers

- (NSDate *)dateForString:(NSString *)string
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    [dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    NSDate *sourceDate = [dateFormatter dateFromString:string];
    
    return sourceDate;
}

- (NSString *)normalizeString:(NSString *)string
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
