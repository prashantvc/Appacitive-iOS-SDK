//
//  APObject.m
//  Appacitive-iOS-SDK
//
//  Created by Kauserali Hafizji on 29/08/12.
//  Copyright (c) 2012 Appacitive Software Pvt. Ltd. All rights reserved.
//

#import "APObject.h"
#import "Appacitive.h"
#import "APError.h"
#import "APHelperMethods.h"
#import "NSString+APString.h"

@implementation APObject

NSString *const ARTICLE_PATH = @"v0.9/core/Article.svc/v2/";

#define SEARCH_PATH @"/v0.9/core/Search.svc/v2/"

#pragma mark initialization methods

+ (id) objectWithSchemaName:(NSString*)schemaName {
    APObject *object = [[APObject alloc] initWithSchemaName:schemaName];
    return object;
}

- (id) initWithSchemaName:(NSString*)schemaName {
    self = [super init];
    if (self) {
        self.schemaType = schemaName;
    }
    return self;
}

#pragma mark search method

+ (void) searchAllObjectsWithSchemaName:(NSString*) schemaName successHandler:(APResultSuccessBlock)successHandler {
    [APObject searchAllObjectsWithSchemaName:schemaName successHandler:successHandler failureHandler:nil];
}

+ (void) searchAllObjectsWithSchemaName:(NSString*) schemaName successHandler:(APResultSuccessBlock)successHandler failureHandler:(APFailureBlock)failureBlock {
    [APObject searchObjectsWithSchemaName:schemaName withQueryString:nil successHandler:successHandler failureHandler:failureBlock];
}

+ (void) searchObjectsWithSchemaName:(NSString*)schemaName withQueryString:(NSString*)queryString successHandler:(APResultSuccessBlock)successBlock {
    [APObject searchObjectsWithSchemaName:schemaName withQueryString:queryString successHandler:successBlock failureHandler:nil];
}

+ (void) searchObjectsWithSchemaName:(NSString*)schemaName withQueryString:(NSString*)queryString successHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%@/find/all", sharedObject.deploymentId, schemaName];
        
        NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
        [queryParams setObject:sharedObject.session forKey:@"session"];
        [queryParams setObject:NSStringFromBOOL(sharedObject.enableDebugForEachRequest) forKey:@"debug"];
        
        if (queryString) {
            NSDictionary *queryStringParams = [queryString queryParameters];
            [queryStringParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
                [queryParams setObject:obj forKey:key];
            }];
        }
        
        path = [path stringByAppendingQueryParameters:queryParams];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path];
        [op onCompletion:^(MKNetworkOperation *completedOperation){
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock) {
                    successBlock(completedOperation.responseJSON);
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }

        } onError:^(NSError *error){
            if (failureBlock != nil) {
                failureBlock((APError*) error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

#pragma mark delete methods

+ (void) deleteObjectsWithIds:(NSArray*)objectIds schemaName:(NSString*)schemaName failureHandler:(APFailureBlock)failureBlock {
    [APObject deleteObjectsWithIds:objectIds schemaName:schemaName successHandler:nil failureHandler:failureBlock];
}

+ (void) deleteObjectsWithIds:(NSArray*)objectIds schemaName:(NSString*)schemaName successHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%@/_bulk", sharedObject.deploymentId, schemaName];
        
        NSDictionary *queryParams = @{@"session":sharedObject.session, @"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)};
        path = [path stringByAppendingQueryParameters:queryParams];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:objectIds forKey:@"Id"];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:params httpMethod:@"POST"];
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op onCompletion:^(MKNetworkOperation *completionOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completionOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock) {
                    successBlock();
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        } onError:^(NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*) error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

- (void) deleteObject {
    [self deleteObjectWithSuccessHandler:nil failureHandler:nil];
}

- (void) deleteObjectWithFailureHandler:(APFailureBlock)failureBlock {
    [self deleteObjectWithSuccessHandler:nil failureHandler:failureBlock];
}

- (void) deleteObjectWithSuccessHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%@/%lld", sharedObject.deploymentId, self.schemaType, [self.objectId longLongValue]];
        
        NSDictionary *queryParams = @{@"session":sharedObject.session, @"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)};
        path = [path stringByAppendingQueryParameters:queryParams];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:nil httpMethod:@"DELETE"];
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock != nil) {
                    successBlock();
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        } onError:^(NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

#pragma mark fetch methods

+ (void) fetchObjectWithObjectId:(NSNumber*)objectId schemaName:(NSString*)schemaName successHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    [APObject fetchObjectsWithObjectIds:@[objectId] schemaName:schemaName successHandler:successBlock failureHandler:failureBlock];
}

+ (void) fetchObjectsWithObjectIds:(NSArray*)objectIds schemaName:(NSString *)schemaName successHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        __block NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%@/find/byidlist", sharedObject.deploymentId, schemaName];
        
        NSMutableDictionary *queryParams = @{@"session":sharedObject.session, @"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        path = [path stringByAppendingString:@"&idlist="];
        
        [objectIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSNumber *number = (NSNumber*) obj;
            path = [path stringByAppendingFormat:@"%lld", number.longLongValue];
            if (idx != objectIds.count - 1) {
                path = [path stringByAppendingString:@","];
            }
        }];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path];
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock) {
                    successBlock(completedOperation.responseJSON);
                }
            } else {
                if (failureBlock) {
                    failureBlock(error);
                }
            }
        } onError:^(NSError *error) {
            if (failureBlock) {
                failureBlock((APError*) error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

- (void) fetch {
    [self fetchWithFailureHandler:nil];
}

- (void) fetchWithFailureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%@/%lld", sharedObject.deploymentId, self.schemaType, [self.objectId longLongValue]];
        
        NSMutableDictionary *queryParams = @{@"session":sharedObject.session, @"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];

        MKNetworkOperation *op = [sharedObject operationWithPath:path];
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                [self setNewPropertyValuesFromDictionary:completedOperation.responseJSON];
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        } onError:^(NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

#pragma mark save methods

- (void) saveObject {
    [self saveObjectWithSuccessHandler:nil failureHandler:nil];
}

- (void) saveObjectWithFailureHandler:(APFailureBlock)failureBlock {
    [self saveObjectWithSuccessHandler:nil failureHandler:failureBlock];
}

- (void) saveObjectWithSuccessHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%@", sharedObject.deploymentId, self.schemaType];
        NSMutableDictionary *queryParams = @{@"session":sharedObject.session, @"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
                
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:[self postParamerters] httpMethod:@"PUT"];
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                [self setNewPropertyValuesFromDictionary:completedOperation.responseJSON];
                
                if (successBlock != nil) {
                    successBlock(completedOperation.responseJSON);
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        } onError:^(NSError *error){
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

#pragma mark graph query method

+ (void) applyFilterGraphQuery:(NSString*)query successHandler:(APResultSuccessBlock)successBlock {
    [APObject applyFilterGraphQuery:query successHandler:successBlock failureHandler:nil];
}

+ (void) applyFilterGraphQuery:(NSString*)query successHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        NSString *path = [SEARCH_PATH stringByAppendingFormat:@"%@/filter", sharedObject.deploymentId];
        
        NSMutableDictionary *queryParams = @{@"session":sharedObject.session, @"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        NSError *error;
        NSMutableDictionary *postParams = [NSJSONSerialization JSONObjectWithData:[query dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            DLog(@"Error created JSON, please check the syntax of the graph query");
            return;
        }
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:postParams httpMethod:@"POST"];
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock != nil) {
                    successBlock(completedOperation.responseJSON);
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        } onError:^(NSError *error){
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

+ (void) applyProjectionGraphQuery:(NSString*)query successHandler:(APResultSuccessBlock)successBlock {
    [APObject applyProjectionGraphQuery:query successHandler:successBlock failureHandler:nil];
}

+ (void) applyProjectionGraphQuery:(NSString *)query successHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    if (sharedObject) {
        NSString *path = [SEARCH_PATH stringByAppendingFormat:@"%@/project", sharedObject.deploymentId];
        
        NSMutableDictionary *queryParams = @{@"session":sharedObject.session, @"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        NSError *error;
        NSMutableDictionary *postParams = [NSJSONSerialization JSONObjectWithData:[query dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            DLog(@"Error created JSON, please check the syntax of the graph query");
            return;
        }
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:postParams httpMethod:@"POST"];
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock != nil) {
                    successBlock(completedOperation.responseJSON);
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        } onError:^(NSError *error){
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY and DEPLOYMENT_ID in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
    }
}

#pragma mark add properties method

- (void) addPropertyWithKey:(NSString*) keyName value:(id) object {
    if (!self.properties) {
        _properties = [NSMutableArray array];
    }
    [_properties addObject:@{keyName: object}];
}

#pragma mark add attributes method

- (void) addAttributeWithKey:(NSString*) keyName value:(id) object {
    if (!self.attributes) {
        _attributes = [NSMutableArray array];
    }
    [_attributes addObject:@{keyName: object}];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"Object Id:%lld, Created by:%@, Last modified by:%@, UTC date created:%@, UTC date updated:%@, Revision:%d, Properties:%@, Attributes:%@, SchemaId:%d, SchemaType:%@, Tag:%@", [self.objectId longLongValue], self.createdBy, self.lastModifiedBy, self.utcDateCreated, self.utcLastUpdatedDate, [self.revision intValue], self.properties, self.attributes, [self.schemaId intValue], self.schemaType, self.tags];
}

#pragma mark private methods

- (void) setNewPropertyValuesFromDictionary:(NSDictionary*) dictionary {
    NSDictionary *article = dictionary[@"article"];
    _createdBy = (NSString*) article[@"__createdby"];
    _objectId = (NSNumber*) article[@"__id"];
    _lastModifiedBy = (NSString*) article[@"__lastmodifiedby"];
    _revision = (NSNumber*) article[@"__revision"];
    _schemaId = (NSNumber*) article[@"__schemaid"];
    _utcDateCreated = [self deserializeJsonDateString:article[@"__utcdatecreated"]];
    _utcLastUpdatedDate = [self deserializeJsonDateString:article[@"__utclastupdateddate"]];
    _attributes = article[@"__attributes"];
    _tags = article[@"__tags"];
    _schemaType = article[@"__schematype"];
    
    _properties = [APHelperMethods arrayOfPropertiesFromJSONResponse:dictionary].mutableCopy;
}

- (NSDate *) deserializeJsonDateString: (NSString *)jsonDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    return [dateFormatter dateFromString:jsonDateString];
}

- (NSMutableDictionary*) postParamerters {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
    if (self.attributes)
        postParams[@"__attributes"] = self.attributes;
    
    if (self.createdBy)
        postParams[@"__createdby"] = self.createdBy;
    
    if (self.revision)
        postParams[@"__revision"] = self.revision;

    for(NSDictionary *prop in self.properties) {
        [prop enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            [postParams setObject:obj forKey:key];
            *stop = YES;
        }];
    }
    
    if (self.schemaType)
        postParams[@"__schematype"] = self.schemaType;

    if (self.tags)
        postParams[@"__tags"] = self.tags;
    return postParams;
}
@end
