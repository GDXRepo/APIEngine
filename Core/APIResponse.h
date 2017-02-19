//
//  APIResponse.h
//  APIEngine
//
//  Created by Георгий Малюков on 10.02.17.
//  Copyright © 2017 Georgiy Malyukov. All rights reserved.
//

#import <JSONModel/JSONModel.h>


@interface APIResponse : JSONModel {
    
}

#pragma mark - Special

- (__kindof JSONModel<Optional> *)data;

@end
