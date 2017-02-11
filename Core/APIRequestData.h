//
//  APIRequestData.h
//  APIEngine
//
//  Created by Георгий Малюков on 10.02.17.
//  Copyright © 2017 Georgiy Malyukov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSDictionary<NSString *, NSString *> StringDictionary;
typedef NSArray<NSString *> StringArray;


@interface APIRequestData : NSObject {
    
}

#pragma mark - Common

- (StringDictionary *)params;
- (StringArray *)validate;

@end

// C-style

id wrap_param(id input);
