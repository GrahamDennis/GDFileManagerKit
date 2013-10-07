//
//  GDWebDAVClient.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 1/02/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDWebDAVClient.h"
#import "GDWebDAVClientManager.h"
#import "GDWebDAVMetadata.h"

#import "GDHTTPOperation.h"
#import "GDWebDAVUploadOperation.h"

#import "AFKissXMLRequestOperation.h"

#import "DDXML.h"
#import "DDXMLElementAdditions.h"

#import "UIAlertView+Blocks.h"

#import "GDFileManagerResourceBundle.h"

@interface GDWebDAVClient ()

- (NSOperation *)enqueueWebDAVRequestOperationWithMethod:(NSString *)method path:(NSString *)path
                                           urlParameters:(NSDictionary *)urlParameters httpParameters:(NSDictionary *)httpParameters
                                         xmlTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
                                                 success:(void (^)(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument))success
                                                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)updateBaseURLDueToRedirectFromURL:(NSURL *)fromURL toURL:(NSURL *)redirectURL;

@property (nonatomic, strong, readwrite) NSURL *baseURL;

@end

@implementation GDWebDAVClient

@dynamic credential;

- (id)initWithClientManager:(GDClientManager *)clientManager credential:(GDClientCredential *)credential baseURL:(NSURL *)baseURL
{
    if (!baseURL && [credential isKindOfClass:[GDWebDAVCredential class]])
        baseURL = [(GDWebDAVCredential *)credential serverURL];
    
    if (!baseURL)
        return nil;
    
    if ((self = [super initWithClientManager:clientManager credential:credential baseURL:baseURL])) {
        
        [self registerHTTPOperationClass:[AFKissXMLRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"text/xml; charset=\"utf-8\""];
        [self setDefaultHeader:@"Content-Type" value:@"text/xml; charset=\"utf-8\""];
        [self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
    }
    
    return self;
}

- (BOOL)isAuthenticationFailureError:(NSError *)error
{
    return [[error domain] isEqualToString:GDHTTPStatusErrorDomain] && [error code] == 401;
}

#pragma mark -

- (void)updateBaseURLDueToRedirectFromURL:(NSURL *)fromURL toURL:(NSURL *)redirectURL
{
    NSString *oldNetLoc = (__bridge_transfer NSString *)CFURLCopyNetLocation((__bridge CFURLRef)self.baseURL);
    NSString *newNetLoc = (__bridge_transfer NSString *)CFURLCopyNetLocation((__bridge CFURLRef)redirectURL);
    
    if ([oldNetLoc isEqualToString:newNetLoc]) return;
    
    if (![[fromURL path] isEqualToString:[redirectURL path]]) return;
    
    NSString *basePath = [self.baseURL path];
    
    NSString *urlEncodedPath = [basePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *newBaseURL = [[NSURL URLWithString:urlEncodedPath relativeToURL:redirectURL] absoluteURL];
    if (![[newBaseURL absoluteString] hasSuffix:@"/"])
        newBaseURL = [newBaseURL URLByAppendingPathComponent:@""];
    self.baseURL = newBaseURL;
}

- (NSMutableURLRequest *)webDAVRequestWithMethod:(NSString *)method path:(NSString *)path urlParameters:(NSDictionary *)urlParameters httpParameters:(NSDictionary *)httpParameters
                                 xmlTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
{
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:urlParameters];
    
    [httpParameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [request setValue:value forHTTPHeaderField:key];
    }];
    
    if (templateName) {
        request.HTTPBody = [self xmlDataByFillingXMLTemplateName:templateName substitutionVariables:substitutionVariables];
    }
    
    return request;
}

- (NSOperation *)enqueueOperationWithURLRequest:(NSMutableURLRequest *)urlRequest
                         requiresAuthentication:(BOOL)requiresAuthentication
                               shouldRetryBlock:(BOOL (^)(NSError *))shouldRetryBlock
                                        success:(void (^)(AFHTTPRequestOperation *, id))success
                                        failure:(void (^)(AFHTTPRequestOperation *operation, NSError *))failure
                        configureOperationBlock:(void (^)(AFHTTPRequestOperation *))configureOperationBlock
{
    return [super enqueueOperationWithURLRequest:urlRequest
                          requiresAuthentication:requiresAuthentication
                                shouldRetryBlock:shouldRetryBlock
                                         success:success failure:failure
                         configureOperationBlock:^(AFHTTPRequestOperation *operation) {
                             [operation setWillSendRequestForAuthenticationChallengeBlock:^(NSURLConnection *connection, NSURLAuthenticationChallenge *challenge) {
                                 if (self.credential && [challenge previousFailureCount] == 0) {
                                     NSURLCredential *urlCredential = [NSURLCredential credentialWithUser:self.credential.username password:self.credential.password persistence:NSURLCredentialPersistencePermanent];
                                     [[challenge sender] useCredential:urlCredential forAuthenticationChallenge:challenge];
                                 } else {
                                     RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"Cancel"];
                                     RIButtonItem *loginItem = [RIButtonItem itemWithLabel:@"Log in"];
                                     
                                     NSString *title = [NSString stringWithFormat:@"Log in to %@ (%@)", [challenge protectionSpace].host, [challenge protectionSpace].realm];
                                     
                                     UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil cancelButtonItem:cancelItem otherButtonItems:loginItem, nil];
                                     
                                     alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
                                     
                                     loginItem.action = ^{
                                         UITextField *usernameTextField = [alertView textFieldAtIndex:0];
                                         UITextField *passwordTextField = [alertView textFieldAtIndex:1];
                                         
                                         NSString *username = usernameTextField.text;
                                         NSString *password = passwordTextField.text;
                                         
                                         self.credential = [[GDWebDAVCredential alloc] initWithUsername:username password:password serverURL:self.baseURL];
                                         
                                         NSURLCredential *urlCredential = [NSURLCredential credentialWithUser:username password:password persistence:NSURLCredentialPersistencePermanent];
                                         [[challenge sender] useCredential:urlCredential forAuthenticationChallenge:challenge];
                                     };
                                     
                                     cancelItem.action = ^{
                                         [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
                                     };
                                     
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [alertView show];
                                     });
                                 }
                             }];
                             
                             [operation setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
                                 if (!redirectResponse) return request;
                                 
                                 [self updateBaseURLDueToRedirectFromURL:[[connection originalRequest] URL] toURL:[request URL]];
                                 
                                 NSMutableURLRequest *redirectRequest = [urlRequest mutableCopy];
                                 redirectRequest.URL = [request URL];
                                 
                                 return redirectRequest;
                             }];
                             
                             if (configureOperationBlock)
                                 configureOperationBlock(operation);
                         }];
}

- (NSOperation *)enqueueWebDAVRequestOperationWithMethod:(NSString *)method path:(NSString *)path
                                           urlParameters:(NSDictionary *)urlParameters httpParameters:(NSDictionary *)httpParameters
                                         xmlTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
                                                 success:(void (^)(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument))success
                                                 failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableURLRequest *request = [self webDAVRequestWithMethod:method path:path urlParameters:urlParameters httpParameters:httpParameters
                                                 xmlTemplateName:templateName substitutionVariables:substitutionVariables];
    
    return [self enqueueOperationWithURLRequest:request
                         requiresAuthentication:NO
                                        success:success
                                        failure:failure];
    
}

- (NSData *)xmlDataByFillingXMLTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
{
    if (!templateName) return nil;
    NSURL *xmlTemplateURL = [GDFileManagerResourcesBundle() URLForResource:templateName withExtension:@"xml"];
    NSData *xmlTemplateData = [NSData dataWithContentsOfURL:xmlTemplateURL];
    
    NSError *error = nil;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithData:xmlTemplateData options:0 error:&error];
    if (!document) {
        NSLog(@"error: %@", error);
        return nil;
    }
    DDXMLElement *rootElement = [document rootElement];
    
    NSNull *Null = [NSNull null];
    
    [substitutionVariables enumerateKeysAndObjectsUsingBlock:^(NSString *variable, NSString *substitution, BOOL *stop) {
        if ([substitution isEqual:Null]) {
            NSLog(@"Missing substitution for variable %@", variable);
            [self deleteChildOfXMLElement:rootElement withName:variable];
        } else {
            [self setString:substitution asContentForElementWithName:variable inXMLElement:rootElement];
        }
    }];
    
    return [document XMLData];
    
}

#define DICTIONARY_SAFE(x) (x ?: [NSNull null])

#pragma mark - Server validation / redirect following
- (void)validateWebDAVServerWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure
{
    [self getPROPFINDResponseForPath:@"" depth:0 success:^(NSArray *results) {
        if (success) success();
    } failure:failure];

//    [self enqueueWebDAVRequestOperationWithMethod:@"OPTIONS" path:@"" urlParameters:nil httpParameters:nil
//                                  xmlTemplateName:nil substitutionVariables:nil
//                                          success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
//                                              NSLog(@"operation: %@, responseDocument: %@", operation, responseDocument);
//                                              NSHTTPURLResponse *response = [operation response];
//                                              NSDictionary *httpHeaders = [response allHeaderFields];
//                                              NSArray *allowedMethods = [httpHeaders[@"Allow"] componentsSeparatedByString:@","];
//                                              if ([allowedMethods containsObject:@"PROPFIND"]) {
//                                                  if (success) success();
//                                              } else {
//                                                  if (failure) failure(nil);
//                                              }
//                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//                                              if (failure)
//                                                  failure(error);
//                                          }];
}

#pragma mark - Metadata

- (void)getMetadataForPath:(NSString *)path success:(void (^)(GDWebDAVMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    [self getPROPFINDResponseForPath:path depth:0 success:^(NSArray *results) {
        if ([results count] == 1) {
            if (success) success([results lastObject]);
        } else {
            if (failure) failure(nil);
        }
    } failure:failure];
}

- (void)getContentsOfDirectoryAtPath:(NSString *)path success:(void (^)(NSArray *contents))success failure:(void (^)(NSError *error))failure
{
    [self getPROPFINDResponseForPath:path depth:1 success:success failure:failure];
}

- (void)getPROPFINDResponseForPath:(NSString *)path depth:(NSUInteger)depth success:(void (^)(NSArray *results))success failure:(void (^)(NSError *error))failure
{
    NSDictionary *httpParameters = @{@"Depth" : (depth == 0) ? @"0" : @"1"};
    
    NSString *encodedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self enqueueWebDAVRequestOperationWithMethod:@"PROPFIND" path:encodedPath urlParameters:nil httpParameters:httpParameters
                                  xmlTemplateName:@"WebDAVMetadataRequest" substitutionVariables:nil
                                          success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                              NSURL *baseURL = [[operation response] URL];
                                              NSArray *metadataArray = [self metadataArrayFromXMLNode:[responseDocument rootElement] baseURL:baseURL];
                                              if (success) {
                                                  success(metadataArray);
                                              }
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              if (failure) failure(error);
                                          }];
}

#pragma mark - File operations

- (void)deletePath:(NSString *)path success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSString *encodedPath = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self enqueueWebDAVRequestOperationWithMethod:@"DELETE" path:encodedPath urlParameters:nil httpParameters:nil
                                  xmlTemplateName:nil substitutionVariables:nil
                                          success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                              if ([[operation response] statusCode] == 207) {
                                                  // Multi-status, so error
                                                  if (failure) failure(nil);
                                                  return;
                                              }
                                                  
                                              if (success) success();
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              if (failure) failure(error);
                                          }];
}

- (void)copyPath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    return [self copyOrMove:@"COPY" fromPath:sourcePath toPath:destinationPath success:success failure:failure];
}

- (void)movePath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    return [self copyOrMove:@"MOVE" fromPath:sourcePath toPath:destinationPath success:success failure:failure];
}

- (void)copyOrMove:(NSString *)operation fromPath:(NSString *)sourcePath toPath:(NSString *)destinationPath success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSString *encodedSourcePath = [sourcePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *httpParameters = @{@"Destination": [[NSURL URLWithString:[destinationPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                             relativeToURL:self.baseURL] absoluteString]};
    
    [self enqueueWebDAVRequestOperationWithMethod:operation path:encodedSourcePath
                                    urlParameters:nil httpParameters:httpParameters
                                  xmlTemplateName:nil substitutionVariables:nil
                                          success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                              if (success) success();
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              if ([[error domain] isEqualToString:@"DDXMLErrorDomain"] && [error code] == 1) {
                                                  if (success) success();
                                              } else {
                                                  if (failure) failure(error);
                                              }
                                          }];
}



#pragma mark - Downloading

- (NSOperation *)downloadFile:(NSString *)remotePath intoPath:(NSString *)localPath
                     progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                      success:(void (^)(NSString *localPath, GDWebDAVMetadata *metadata))success_
                      failure:(void (^)(NSError *error))failure_
{
    __block GDParentOperation *parentOperation = [GDParentOperation new];
    dispatch_block_t cleanup = ^{[parentOperation finish]; parentOperation = nil;};
    typeof(success_) success = ^(NSString *localPath, GDWebDAVMetadata *metadata){
        dispatch_async(parentOperation.successCallbackQueue, ^{
            if (success_) success_(localPath, metadata);
            cleanup();
        });
    };
    typeof(failure_) failure = ^(NSError *error){
        dispatch_async(parentOperation.failureCallbackQueue, ^{
            if (failure_) failure_(error);
            cleanup();
        });
    };
    
    [self getMetadataForPath:remotePath
                     success:^(GDWebDAVMetadata *metadata) {
                         NSString *encodedRemotePath = [remotePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                         NSMutableURLRequest *urlRequest = [self requestWithMethod:@"GET" path:encodedRemotePath parameters:nil];
                         
                         [urlRequest setValue:@"*/*" forHTTPHeaderField:@"Accept"];
                         NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:localPath append:NO];
                         
                         [self enqueueOperationWithURLRequest:urlRequest
                                       requiresAuthentication:NO
                                             shouldRetryBlock:NULL
                                                      success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                                          success(localPath, metadata);
                                                      }
                                                      failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                                          failure(error);
                                                      }
                                      configureOperationBlock:^(AFHTTPRequestOperation *requestOperation) {
                                          [parentOperation addChildOperation:requestOperation];
                                          
                                          requestOperation.outputStream = outputStream;
                                          [requestOperation setDownloadProgressBlock:progress];
                                      }];
                     } failure:failure];
    
    return parentOperation;
    
}

- (NSOperation *)uploadFile:(NSString *)localPath mimeType:(NSString *)mimeType toWebDAVPath:(NSString *)destinationPath
                   progress:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progress
                    success:(void (^)(GDWebDAVMetadata *metadata))success
                    failure:(void (^)(NSError *error))failure
{
    GDWebDAVUploadOperation *uploadOperation = [[GDWebDAVUploadOperation alloc] initWithClient:self fromLocalPath:localPath toWebDAVPath:destinationPath
                                                                                             success:success
                                                                                             failure:failure];
    
    uploadOperation.uploadProgressBlock = progress;
    uploadOperation.mimeType = mimeType;
    
    [uploadOperation start];
    
    return uploadOperation;
}


#pragma mark - XML support

- (void)setString:(NSString *)string asContentForElementWithName:(NSString *)elementName inXMLElement:(DDXMLElement *)rootElement
{
    DDXMLElement *childElement = [rootElement elementForName:elementName];
    if (!childElement) {
        NSLog(@"Unable to find child element with name %@", elementName);
        return;
    }
    DDXMLNode *textNode = [DDXMLNode textWithStringValue:string];
    if (!textNode) {
        NSLog(@"Unable to create text node for string %@", string);
        return;
    }
    [childElement setChildren:@[textNode]];
}

- (void)deleteChildOfXMLElement:(DDXMLElement *)rootElement withName:(NSString *)elementName
{
    DDXMLElement *childElement = [rootElement elementForName:elementName];
    [childElement delete:childElement];
}

- (NSString *)contentStringForElementWithName:(NSString *)elementName inXMLElement:(DDXMLElement *)rootElement
{
    DDXMLElement *childElement = [rootElement elementForName:elementName];
    if (!childElement) {
        NSLog(@"Unable to find child element with name %@", elementName);
        return nil;
    }
    return [childElement stringValue];
}

- (id)objectFromXMLNode:(DDXMLNode *)rootNode
{
    if ((rootNode.kind == DDXMLTextKind)
        || (rootNode.childCount == 1 && [(DDXMLNode *)[rootNode.children lastObject] kind] == DDXMLTextKind)) {
        return [rootNode stringValue];
    } else if (rootNode.kind == DDXMLElementKind) {
        if ([rootNode.localName isEqualToString:@"multistatus"]) {
            NSMutableArray *result = [NSMutableArray new];
            for (DDXMLNode *childNode in rootNode.children) {
                id childObject = [self objectFromXMLNode:childNode];
                if (!childObject) {
                    NSLog(@"Failed to decode XML %@ into an object", childNode);
                } else {
                    [result addObject:childObject];
                }
            }
            return [result copy];
        } else {
            NSMutableDictionary *result = [NSMutableDictionary new];
            for (DDXMLNode *childNode in rootNode.children) {
                id childObject = [self objectFromXMLNode:childNode];
                if (!childObject) {
                    NSLog(@"Failed to decode XML %@ into an object", childNode);
                } else {
                    if ([childObject isKindOfClass:[NSDictionary class]]) {
                        id status = childObject[@"status"];
                        if (status && [status isKindOfClass:[NSString class]] && [(NSString *)status rangeOfString:@"200"].location == NSNotFound)
                            continue;
                    }

                    if (result[childNode.localName]) {
                        NSLog(@"An object already exists with localName: %@; result: %@, childObject: %@", childNode.localName, result, childObject);
                    } else {
                        result[childNode.localName] = childObject;
                    }
                }
            }
            return [result copy];
        }
    } else {
        NSLog(@"Don't know how to handle element: %@", rootNode);
    }
    return nil;
}

- (NSArray *)metadataArrayFromXMLNode:(DDXMLNode *)xmlNode baseURL:(NSURL *)baseURL
{
    if (![xmlNode.localName isEqualToString:@"multistatus"]) {
        NSLog(@"Don't understand XML Node: %@", xmlNode);
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:xmlNode.childCount];
    for (DDXMLNode *childNode in xmlNode.children) {
        NSDictionary *metadataDictionary = [self objectFromXMLNode:childNode];
        GDWebDAVMetadata *metadata = [[GDWebDAVMetadata alloc] initWithDictionary:metadataDictionary];
        if (metadata) {
            [result addObject:metadata];
        }
    }
    
    return [result copy];
}


@end
