//
//  APIRequestData.m
//  APIEngine
//
//  Created by Георгий Малюков on 10.02.17.
//  Copyright © 2017 Georgiy Malyukov. All rights reserved.
//

#import "APIRequestData.h"


@implementation APIRequestData


#pragma mark - Common

- (StringDictionary *)params {
    return @{};
}

- (StringArray *)validate {
    return @[];
}

@end

// C-style

id wrap_param(id input) {
    return (input) ? input : [NSNull null];
}
