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

NSString *const ARTICLE_PATH = @"article/";

#define SEARCH_PATH @"search/"

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

- (id) initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (self) {
        [self setPropertyValuesFromDictionary:dictionary];
    }
    return self;
}

#pragma mark search method

+ (void) searchAllObjectsWithSchemaName:(NSString*) schemaName successHandler:(APObjectsSuccessBlock)successBlock {
    [APObject searchAllObjectsWithSchemaName:schemaName successHandler:successBlock failureHandler:nil];
}

+ (void) searchAllObjectsWithSchemaName:(NSString*) schemaName successHandler:(APObjectsSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    [APObject searchObjectsWithSchemaName:schemaName withQueryString:nil successHandler:successBlock failureHandler:failureBlock];
}

+ (void) searchObjectsWithSchemaName:(NSString*)schemaName withQueryString:(NSString*)queryString successHandler:(APObjectsSuccessBlock)successBlock {
    [APObject searchObjectsWithSchemaName:schemaName withQueryString:queryString successHandler:successBlock failureHandler:nil];
}

+ (void) searchObjectsWithSchemaName:(NSString*)schemaName withQueryString:(NSString*)queryString successHandler:(APObjectsSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/find/all", schemaName];
        
        NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
        [queryParams setObject:NSStringFromBOOL(sharedObject.enableDebugForEachRequest) forKey:@"debug"];
        
        if (queryString) {
            NSDictionary *queryStringParams = [queryString queryParameters];
            [queryStringParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
                [queryParams setObject:obj forKey:key];
            }];
        }
        
        path = [path stringByAppendingQueryParameters:queryParams];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:nil httpMethod:@"GET" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation){
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(){
                        
                        NSArray *articles = [completedOperation.responseJSON objectForKey:@"articles"];
                        NSMutableArray *apObjects = [NSMutableArray arrayWithCapacity:articles.count];
                        
                        for (NSDictionary *article in articles) {
                            APObject *object = [[APObject alloc] initWithDictionary:article];
                            [apObjects addObject:object];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            successBlock(apObjects);
                        });
                    });
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }

        } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*) error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

#pragma mark delete methods

+ (void) deleteObjectsWithIds:(NSArray*)objectIds schemaName:(NSString*)schemaName failureHandler:(APFailureBlock)failureBlock {
    [APObject deleteObjectsWithIds:objectIds schemaName:schemaName successHandler:nil failureHandler:failureBlock];
}

+ (void) deleteObjectsWithIds:(NSArray*)objectIds schemaName:(NSString*)schemaName successHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/bulkdelete", schemaName];
        
        NSDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)};
        path = [path stringByAppendingQueryParameters:queryParams];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:objectIds forKey:@"idlist"];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:params httpMethod:@"POST" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op addCompletionHandler:^(MKNetworkOperation *completionOperation) {
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
        } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error){
            if (failureBlock != nil) {
                failureBlock((APError*) error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

- (void) deleteObject {
    [self deleteObjectWithSuccessHandler:nil failureHandler:nil];
}

- (void) deleteObjectWithFailureHandler:(APFailureBlock)failureBlock {
    [self deleteObjectWithSuccessHandler:nil failureHandler:failureBlock];
}

- (void) deleteObjectWithSuccessHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    [self deleteObjectWithSuccessHandler:successBlock failureHandler:failureBlock deleteConnectingConnections:NO];
}

- (void) deleteObjectWithConnectingConnections {
    [self deleteObjectWithSuccessHandler:nil failureHandler:nil deleteConnectingConnections:YES];
}

- (void) deleteObjectWithConnectingConnections:(APFailureBlock)failureBlock {
    [self deleteObjectWithSuccessHandler:nil failureHandler:failureBlock deleteConnectingConnections:YES];
}

- (void) deleteObjectWithConnectingConnectionsSuccessHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    [self deleteObjectWithSuccessHandler:successBlock failureHandler:failureBlock deleteConnectingConnections:YES];
}

- (void) deleteObjectWithSuccessHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock deleteConnectingConnections:(BOOL)deleteConnections {
    
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%lld", self.schemaType, [self.objectId longLongValue]];
        
        NSDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest), @"deleteconnections":deleteConnections?@"true":@"false"};
        path = [path stringByAppendingQueryParameters:queryParams];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:nil httpMethod:@"DELETE" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
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
        }  errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

#pragma mark fetch methods

+ (void) fetchObjectWithObjectId:(NSNumber*)objectId schemaName:(NSString*)schemaName successHandler:(APObjectsSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    [APObject fetchObjectsWithObjectIds:@[objectId] schemaName:schemaName successHandler:successBlock failureHandler:failureBlock];
}

+ (void) fetchObjectsWithObjectIds:(NSArray*)objectIds schemaName:(NSString *)schemaName successHandler:(APObjectsSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        __block NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/multiget/", schemaName];
        
        [objectIds enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSNumber *number = (NSNumber*) obj;
            path = [path stringByAppendingFormat:@"%lld", number.longLongValue];
            if (idx != objectIds.count - 1) {
                path = [path stringByAppendingString:@","];
            }
        }];
        
        NSMutableDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:nil httpMethod:@"GET" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                if (successBlock) {
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(){
                        
                        NSArray *articles = [completedOperation.responseJSON objectForKey:@"articles"];
                        NSMutableArray *apObjects = [NSMutableArray arrayWithCapacity:articles.count];
                        
                        for (NSDictionary *article in articles) {
                            APObject *object = [[APObject alloc] initWithDictionary:article];
                            [apObjects addObject:object];
                        }
                        dispatch_async(dispatch_get_main_queue(), ^(){
                            successBlock(apObjects);
                        });
                    });
                }
            } else {
                if (failureBlock) {
                    failureBlock(error);
                }
            }
        }  errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock) {
                failureBlock((APError*) error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

- (void) fetch {
    [self fetchWithFailureHandler:nil];
}

- (void) fetchWithFailureHandler:(APFailureBlock)failureBlock {
    [self fetchWithSuccessHandler:nil failureHandler:failureBlock];
}

- (void) fetchWithSuccessHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%lld", self.schemaType, [self.objectId longLongValue]];
        
        NSMutableDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:nil httpMethod:@"GET" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                [self setNewPropertyValuesFromDictionary:completedOperation.responseJSON];
                if (successBlock != nil) {
                    successBlock();
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        }  errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

#pragma mark save methods

- (void) saveObject {
    [self saveObjectWithSuccessHandler:nil failureHandler:nil];
}

- (void) saveObjectWithFailureHandler:(APFailureBlock)failureBlock {
    [self saveObjectWithSuccessHandler:nil failureHandler:failureBlock];
}

- (void) saveObjectWithSuccessHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@", self.schemaType];
        NSMutableDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
                
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:[self postParamerters] httpMethod:@"PUT" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                [self setNewPropertyValuesFromDictionary:completedOperation.responseJSON];
                
                if (successBlock != nil) {
                    successBlock();
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        }  errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

#pragma mark update methods

- (void) updateObject {
    [self updateObjectWithSuccessHandler:nil failureHandler:nil];
}

- (void) updateObjectWithFailureHandler:(APFailureBlock)failureBlock {
    [self updateObjectWithSuccessHandler:nil failureHandler:failureBlock];
}

- (void) updateObjectWithSuccessHandler:(APSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        NSString *path = [ARTICLE_PATH stringByAppendingFormat:@"%@/%@", self.schemaType, self.objectId.description];
        NSMutableDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:[self postParamertersUpdate] httpMethod:@"POST" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
            APError *error = [APHelperMethods checkForErrorStatus:completedOperation.responseJSON];
            
            BOOL isErrorPresent = (error != nil);
            
            if (!isErrorPresent) {
                [self setNewPropertyValuesFromDictionary:completedOperation.responseJSON];
                
                if (successBlock != nil) {
                    successBlock();
                }
            } else {
                if (failureBlock != nil) {
                    failureBlock(error);
                }
            }
        }  errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

#pragma mark graph query method

+ (void) applyFilterGraphQuery:(NSString*)query successHandler:(APResultSuccessBlock)successBlock {
    [APObject applyFilterGraphQuery:query successHandler:successBlock failureHandler:nil];
}

+ (void) applyFilterGraphQuery:(NSString*)query successHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        NSString *path = [SEARCH_PATH stringByAppendingString:@"filter"];
        
        NSMutableDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        NSError *error;
        NSMutableDictionary *postParams = [NSJSONSerialization JSONObjectWithData:[query dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            DLog(@"Error creating JSON, please check the syntax of the graph query");
            return;
        }
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:postParams httpMethod:@"POST" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
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
        }  errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

+ (void) applyProjectionGraphQuery:(NSString*)query successHandler:(APResultSuccessBlock)successBlock {
    [APObject applyProjectionGraphQuery:query successHandler:successBlock failureHandler:nil];
}

+ (void) applyProjectionGraphQuery:(NSString *)query successHandler:(APResultSuccessBlock)successBlock failureHandler:(APFailureBlock)failureBlock {
    Appacitive *sharedObject = [Appacitive sharedObject];
    
    if (sharedObject.session) {
        
        NSString *path = [SEARCH_PATH stringByAppendingString:@"project"];
        
        NSMutableDictionary *queryParams = @{@"debug":NSStringFromBOOL(sharedObject.enableDebugForEachRequest)}.mutableCopy;
        path = [path stringByAppendingQueryParameters:queryParams];
        
        NSError *error;
        NSMutableDictionary *postParams = [NSJSONSerialization JSONObjectWithData:[query dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
        if (error) {
            DLog(@"Error created JSON, please check the syntax of the graph query");
            return;
        }
        MKNetworkOperation *op = [sharedObject operationWithPath:path params:postParams httpMethod:@"POST" ssl:YES];
        [APHelperMethods addHeadersToMKNetworkOperation:op];
        
        op.postDataEncoding = MKNKPostDataEncodingTypeJSON;
        
        [op addCompletionHandler:^(MKNetworkOperation *completedOperation) {
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
        }  errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
            if (failureBlock != nil) {
                failureBlock((APError*)error);
            }
        }];
        [sharedObject enqueueOperation:op];
    } else {
        DLog(@"Initialize the Appactive object with your API_KEY in the - application: didFinishLaunchingWithOptions: method of the AppDelegate");
        if (failureBlock != nil) {
            failureBlock([APHelperMethods errorForSessionNotCreated]);
        }
    }
}

#pragma mark add properties method

- (void) addPropertyWithKey:(NSString*) keyName value:(id) object {
    if (!self.properties) {
        _properties = [NSMutableArray array];
    }
    [_properties addObject:@{keyName: object}.mutableCopy];
}

#pragma mark update properties method

- (void) updatePropertyWithKey:(NSString*) keyName value:(id) object {
    [self.properties enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *dict = (NSMutableDictionary *)obj;
        if ([dict objectForKey:keyName] != nil) {
            [dict setObject:object forKey:keyName];
            *stop = YES;
        }
    }];
}

#pragma mark delete property

- (void) removePropertyWithKey:(NSString*) keyName {
    [self.properties enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *dict = (NSMutableDictionary *)obj;
        if ([dict objectForKey:keyName] != nil) {
            [dict setObject:[NSNull null] forKey:keyName];
            *stop = YES;
        }
    }];
}

#pragma mark retrieve property

- (id) getPropertyWithKey:(NSString*) keyName {
    __block id property;
    [self.properties enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *dict = (NSMutableDictionary *)obj;
        if ([dict objectForKey:keyName] != nil) {
            property = [dict objectForKey:keyName];
            *stop = YES;
        }
    }];
    return property;
}

#pragma mark add attributes method

- (void) addAttributeWithKey:(NSString*) keyName value:(id) object {
    if (!self.attributes) {
        _attributes = [NSMutableDictionary dictionary];
    }
    [_attributes setObject:object forKey:keyName];
}

- (void) updateAttributeWithKey:(NSString*) keyName value:(id) object {
    [_attributes setObject:object forKey:keyName];
}

- (void) removeAttributeWithKey:(NSString*) keyName {
    [_attributes setObject:[NSNull null] forKey:keyName];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"Object Id:%lld, Created by:%@, Last modified by:%@, UTC date created:%@, UTC date updated:%@, Revision:%d, Properties:%@, Attributes:%@, SchemaId:%d, SchemaType:%@, Tag:%@", [self.objectId longLongValue], self.createdBy, self.lastModifiedBy, self.utcDateCreated, self.utcLastUpdatedDate, [self.revision intValue], self.properties, self.attributes, [self.schemaId intValue], self.schemaType, self.tags];
}

#pragma mark private methods

- (void) setNewPropertyValuesFromDictionary:(NSDictionary*) dictionary {
    NSDictionary *article = dictionary[@"article"];
    [self setPropertyValuesFromDictionary:article];
}

- (void) setPropertyValuesFromDictionary:(NSDictionary*) dictionary {
    _createdBy = (NSString*) dictionary[@"__createdby"];
    _objectId = (NSNumber*) dictionary[@"__id"];
    _lastModifiedBy = (NSString*) dictionary[@"__lastmodifiedby"];
    _revision = (NSNumber*) dictionary[@"__revision"];
    _schemaId = (NSNumber*) dictionary[@"__schemaid"];
    _utcDateCreated = [APHelperMethods deserializeJsonDateString:dictionary[@"__utcdatecreated"]];
    _utcLastUpdatedDate = [APHelperMethods deserializeJsonDateString:dictionary[@"__utclastupdateddate"]];
    _attributes = [dictionary[@"__attributes"] mutableCopy];
    _tags = dictionary[@"__tags"];
    _schemaType = dictionary[@"__schematype"];
    
    _properties = [APHelperMethods arrayOfPropertiesFromJSONResponse:dictionary].mutableCopy;
}

- (NSMutableDictionary*) postParamerters {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
    
    if (self.objectId)
        postParams[@"__id"] = self.objectId.description;
    
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

- (NSMutableDictionary*) postParamertersUpdate {
    NSMutableDictionary *postParams = [NSMutableDictionary dictionary];
    
    if (self.attributes && [self.attributes count] > 0)
        postParams[@"__attributes"] = self.attributes;
    
    for(NSDictionary *prop in self.properties) {
        [prop enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            [postParams setObject:obj forKey:key];
            *stop = YES;
        }];
    }
    return postParams;
}
@end
