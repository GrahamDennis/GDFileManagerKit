//
//  GDSugarSyncClient.m
//  GDFileManagerExample
//
//  Created by Graham Dennis on 27/01/13.
//  Copyright (c) 2013 Graham Dennis. All rights reserved.
//

#import "GDSugarSyncClient.h"
#import "GDSugarSyncCredential.h"

#import "GDSugarSyncAccountInfo.h"
#import "GDSugarSyncMetadata.h"

#import "AFKissXMLRequestOperation.h"

#import "ISO8601DateFormatter.h"
#import "DDXML.h"
#import "DDXMLElementAdditions.h"
#import "GDHTTPOperation.h"

#import "GDSugarSyncDownloadOperation.h"
#import "GDSugarSyncUploadOperation.h"

#import "GDFileManagerResourceBundle.h"

@interface GDSugarSyncClient ()

- (void)enqueueSugarSyncRequestOperationWithMethod:(NSString *)method path:(NSString *)path urlParameters:(NSDictionary *)urlParameters
                                   xmlTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
                                           success:(void (^)(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument))success
                                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

- (void)enqueueSugarSyncRequestOperationWithMethod:(NSString *)method path:(NSString *)path urlParameters:(NSDictionary *)urlParameters
                                   xmlTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
                               requiresAccessToken:(BOOL)requiresAccessToken
                                           success:(void (^)(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument))success
                                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

@property (nonatomic, strong, readonly) ISO8601DateFormatter *dateFormatter;
@property (nonatomic, strong, readonly) GDSugarSyncAccountInfo *cachedAccountInfo;
@property (nonatomic, strong, readonly) NSDictionary *fixedMetadataByObjectID;

@end

@implementation GDSugarSyncClient

@dynamic credential, apiToken;

- (id)initWithClientManager:(GDClientManager *)clientManager credential:(GDClientCredential *)credential baseURL:(NSURL *)baseURL
{
    if (!baseURL)
        baseURL = [NSURL URLWithString:@"https://api.sugarsync.com"];
    
    if ((self = [super initWithClientManager:clientManager credential:credential baseURL:baseURL])) {
        _dateFormatter = [ISO8601DateFormatter new];
        
        [self registerHTTPOperationClass:[AFKissXMLRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/xml; charset=UTF-8"];
        [self setDefaultHeader:@"Content-Type" value:@"application/xml; charset=UTF-8"];
        [self setDefaultHeader:@"Accept-Encoding" value:@"gzip"];
        
        if (self.userID) {
            NSArray *fixedMetadata = @[self.rootMetadata, self.syncFoldersMetadata, self.workspacesMetadata];
            NSMutableDictionary *fixedMetadataByObjectID = [NSMutableDictionary new];
            for (GDSugarSyncMetadata *metadata in fixedMetadata) {
                fixedMetadataByObjectID[metadata.objectID] = metadata;
            }
            _fixedMetadataByObjectID = [fixedMetadataByObjectID copy];
        }
    }
    
    return self;
}

#pragma mark -

- (void)enqueueSugarSyncRequestOperationWithMethod:(NSString *)method path:(NSString *)path urlParameters:(NSDictionary *)urlParameters
                                   xmlTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
                                           success:(void (^)(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument))success
                                           failure:(void (^)(AFHTTPRequestOperation *, NSError *error))failure
{
    return [self enqueueSugarSyncRequestOperationWithMethod:method path:path urlParameters:urlParameters
                                            xmlTemplateName:templateName substitutionVariables:substitutionVariables
                                        requiresAccessToken:YES
                                                    success:success failure:failure];
}

- (void)enqueueSugarSyncRequestOperationWithMethod:(NSString *)method path:(NSString *)path urlParameters:(NSDictionary *)urlParameters
                                   xmlTemplateName:(NSString *)templateName substitutionVariables:(NSDictionary *)substitutionVariables
                               requiresAccessToken:(BOOL)requiresAccessToken
                                           success:(void (^)(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument))success
                                           failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:urlParameters];

    if (templateName) {
        request.HTTPBody = [self xmlDataByFillingXMLTemplateName:templateName substitutionVariables:substitutionVariables];
    }
    
    [self enqueueOperationWithURLRequest:request
                  requiresAuthentication:requiresAccessToken
                                 success:success failure:failure];
}

- (BOOL)authorizeRequest:(NSMutableURLRequest *)urlRequest
{
    if ([self.credential isAccessTokenValid]) {
        [urlRequest setValue:self.credential.accessToken forHTTPHeaderField:@"Authorization"];
        return YES;
    }
    return NO;
}

- (BOOL)isAuthenticationFailureError:(NSError *)error
{
    return [[error domain] isEqualToString:GDHTTPStatusErrorDomain] && [error code] == 401;
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

#pragma mark - Refresh Token

- (void)getRefreshTokenWithUsername:(NSString *)username password:(NSString *)password
                            success:(void (^)(GDSugarSyncCredential *credential))success failure:(void (^)(NSError *error))failure
{
    NSDictionary *substitutions = @{
    @"application"      : DICTIONARY_SAFE(self.apiToken.appID),
    @"accessKeyId"      : DICTIONARY_SAFE(self.apiToken.key),
    @"privateAccessKey" : DICTIONARY_SAFE(self.apiToken.secret),
    @"username"         : DICTIONARY_SAFE(username),
    @"password"         : DICTIONARY_SAFE(password)
    };
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"POST"
                                                path:@"/app-authorization"
                                       urlParameters:nil
                                     xmlTemplateName:@"SugarSyncRefreshTokenRequest"
                               substitutionVariables:substitutions
                                 requiresAccessToken:NO
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 NSDictionary *httpHeaders = [[operation response] allHeaderFields];
                                                 NSString *refreshToken = httpHeaders[@"Location"];
                                                 if (refreshToken) {
                                                     GDSugarSyncCredential *credential = [[GDSugarSyncCredential alloc] initWithUserID:nil
                                                                                                                              apiToken:self.apiToken
                                                                                                                          refreshToken:refreshToken
                                                                                                                           accessToken:nil
                                                                                                             accessTokenExpirationDate:nil];
                                                     if (success && credential) {
                                                         return success(credential);
                                                     }
                                                     if (failure)
                                                         return failure(nil); // FIXME
                                                 }
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}

#pragma mark - Access Token

- (void)getAccessTokenWithSuccess:(void (^)(GDSugarSyncCredential *credential))success failure:(void (^)(NSError *error))failure
{
    NSDictionary *substitutions = @{
    @"accessKeyId"      : DICTIONARY_SAFE(self.apiToken.key),
    @"privateAccessKey" : DICTIONARY_SAFE(self.apiToken.secret),
    @"refreshToken"     : DICTIONARY_SAFE(self.credential.refreshToken)
    };
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"POST"
                                                path:@"/authorization"
                                       urlParameters:nil
                                     xmlTemplateName:@"SugarSyncAccessTokenRequest"
                               substitutionVariables:substitutions
                                 requiresAccessToken:NO
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 NSDictionary *httpHeaders = [[operation response] allHeaderFields];
                                                 NSString *accessToken = httpHeaders[@"Location"];
                                                 NSDate *accessTokenExpirationDate = nil;
                                                 NSString *userResourceURLString = nil;
                                                 
                                                 if (responseDocument) {
                                                     DDXMLElement *rootElement = [responseDocument rootElement];
                                                     NSString *expirationString = [self contentStringForElementWithName:@"expiration"
                                                                                                           inXMLElement:rootElement];
                                                     userResourceURLString = [self contentStringForElementWithName:@"user"
                                                                                                      inXMLElement:rootElement];
                                                     
                                                     accessTokenExpirationDate = [self.dateFormatter dateFromString:expirationString];
                                                 }
                                                 
                                                 NSString *userID = [userResourceURLString lastPathComponent];
                                                 
                                                 GDSugarSyncCredential *credential = [[GDSugarSyncCredential alloc] initWithUserID:userID
                                                                                                                          apiToken:self.apiToken
                                                                                                                      refreshToken:self.credential.refreshToken
                                                                                                                       accessToken:accessToken
                                                                                                         accessTokenExpirationDate:accessTokenExpirationDate];
                                                 
                                                 if (success) success(credential);
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}


#pragma mark - Account operations

- (void)getAccountInfoWithSuccess:(void (^)(GDSugarSyncAccountInfo *))success failure:(void (^)(NSError *))failure
{
    if (!self.credential.userID) {
        if (failure) failure(nil);
        return;
    }
    NSString *path = [@"/user" stringByAppendingPathComponent:self.credential.userID];
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"GET" path:path urlParameters:nil
                                     xmlTemplateName:nil substitutionVariables:nil
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 NSDictionary *response = [self objectFromXMLNode:[responseDocument rootElement]];
                                                 GDSugarSyncAccountInfo *accountInfo = [[GDSugarSyncAccountInfo alloc] initWithDictionary:response];
                                                 
                                                 if (success) {
                                                     success(accountInfo);
                                                 }
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}

- (void)getCachedAccountInfoWithSuccess:(void (^)(GDSugarSyncAccountInfo *accountInfo))success failure:(void (^)(NSError *error))failure
{
    GDSugarSyncAccountInfo *accountInfo = self.cachedAccountInfo;
    if (accountInfo) {
        if (success) success(accountInfo);
        return;
    }
    [self getAccountInfoWithSuccess:^(GDSugarSyncAccountInfo *accountInfo) {
        _cachedAccountInfo = accountInfo;
        if (success) success(accountInfo);
    } failure:failure];
}


#pragma mark - Metadata

- (void)getMetadataForObjectID:(NSString *)objectID success:(void (^)(GDSugarSyncMetadata *metadata))success failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(objectID);
    
    GDSugarSyncMetadata *fixedMetadata = self.fixedMetadataByObjectID[objectID];
    if (fixedMetadata) {
        if (success) success(fixedMetadata);
        return;
    }
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"GET" path:objectID urlParameters:nil
                                     xmlTemplateName:nil substitutionVariables:nil
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 NSDictionary *rawMetadata = [self objectFromXMLNode:[responseDocument rootElement]];
                                                 GDSugarSyncMetadata *metadata = [[GDSugarSyncMetadata alloc] initWithDictionary:rawMetadata];
                                                 
                                                 if (success) success(metadata);
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}


#pragma mark - Metadata Arrays

- (void)getContentsOfMetadataArrayID:(NSString *)arrayID success:(void (^)(NSArray *metadataArray))success failure:(void (^)(NSError *error))failure
{
    NSMutableArray *resultsArray = [NSMutableArray new];
    [self getContentsOfMetadataArrayID:arrayID offset:0 resultsArray:resultsArray
                               success:^{
                                   if (success) success([resultsArray copy]);
                               } failure:failure];
}

- (void)getContentsOfMetadataArrayID:(NSString *)arrayID offset:(NSInteger)offset resultsArray:(NSMutableArray *)resultsArray
                     success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(arrayID);
    
    NSString *path = arrayID;
    
    NSMutableDictionary *urlParameters = [NSMutableDictionary new];
    if (offset)
        urlParameters[@"start"] = @(offset);
    urlParameters[@"order"] = @"last_modified";
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"GET" path:path urlParameters:urlParameters
                                     xmlTemplateName:nil substitutionVariables:nil
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 DDXMLElement *rootElement = [responseDocument rootElement];
                                                 [resultsArray addObjectsFromArray:[self metadataArrayFromXMLNode:rootElement]];
                                                 NSDictionary *attributeDictionary = [rootElement attributesAsDictionary];
                                                 if ([attributeDictionary[@"hasMore"] boolValue]) {
                                                     NSInteger nextOffset = [attributeDictionary[@"end"] integerValue] + 1;
                                                     [self getContentsOfMetadataArrayID:arrayID offset:nextOffset resultsArray:resultsArray success:success failure:failure];
                                                     return;
                                                 } else {
                                                     if (success) success();
                                                 }
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}

#pragma mark - Collections

- (void)getContentsOfCollectionID:(NSString *)collectionID success:(void (^)(NSArray *contents))success failure:(void (^)(NSError *error))failure
{
    NSString *arrayID = [collectionID stringByAppendingPathComponent:@"contents"];
    
    return [self getContentsOfMetadataArrayID:arrayID success:success failure:failure];
}

- (void)contentsOfToplevelCollection:(NSString *)collectionName success:(void (^)(NSArray *contents))success failure:(void (^)(NSError *error))failure
{
    if (!self.credential.userID) {
        if (failure) failure(nil);
        return;
    }
    NSString *collectionID = [NSString pathWithComponents:@[@"/", @"user", self.credential.userID, collectionName]];
    
    return [self getContentsOfCollectionID:collectionID success:success failure:failure];
}

- (void)getWorkspacesWithSuccess:(void (^)(NSArray *workspaces))success failure:(void (^)(NSError *error))failure
{
    return [self contentsOfToplevelCollection:@"workspaces" success:success failure:failure];
}

- (void)getSyncFoldersWithSuccess:(void (^)(NSArray *))success failure:(void (^)(NSError *))failure
{
    return [self contentsOfToplevelCollection:@"folders" success:success failure:failure];
}

#pragma mark - Versions

- (void)getVersionHistoryForObjectID:(NSString *)objectID
                             success:(void (^)(NSArray *))success
                             failure:(void (^)(NSError *))failure
{
    NSString *arrayID = [objectID stringByAppendingPathComponent:@"version"];
    
    return [self getContentsOfMetadataArrayID:arrayID success:success failure:failure];
}

- (void)createFileVersionForFileID:(NSString *)fileID
                           success:(void (^)(NSString *))success
                           failure:(void (^)(NSError *))failure
{
    NSString *path = [fileID stringByAppendingPathComponent:@"version"];
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"POST"
                                                path:path urlParameters:nil
                                     xmlTemplateName:nil substitutionVariables:nil
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 NSDictionary *httpHeaders = [[operation response] allHeaderFields];
                                                 NSString *objectURLString = httpHeaders[@"Location"];
                                                 if (objectURLString) {
                                                     NSURL *objectURL = [NSURL URLWithString:objectURLString];
                                                     NSString *objectID = [GDSugarSyncMetadata objectIDFromObjectURL:objectURL];
                                                     
                                                     if (success) {
                                                         return success(objectID);
                                                     }
                                                 }
                                                 if (failure) failure(nil);
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}

#pragma mark - File Operations

- (void)moveObjectID:(NSString *)objectID toFolderID:(NSString *)folderID name:(NSString *)name success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(folderID);
    NSString *newParent = [[NSURL URLWithString:folderID relativeToURL:self.baseURL] absoluteString];
    // Get original metadata
    [self enqueueSugarSyncRequestOperationWithMethod:@"GET" path:objectID urlParameters:nil
                                     xmlTemplateName:nil substitutionVariables:nil
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 DDXMLElement *rootElement = [responseDocument rootElement];
                                                 if (![self setString:newParent asContentForElementWithName:@"parent" inXMLElement:rootElement]) {
                                                     if (failure) failure(nil);
                                                     return;
                                                 }
                                                 if (name) {
                                                     if (![self setString:name asContentForElementWithName:@"displayName" inXMLElement:rootElement]) {
                                                         if (failure) failure(nil);
                                                         return;
                                                     }
                                                 }
                                                 NSData *updatedMetadataData = [responseDocument XMLData];
                                                 NSMutableURLRequest *request = [self requestWithMethod:@"PUT" path:objectID parameters:nil];
                                                 [request setHTTPBody:updatedMetadataData];
                                                 
                                                 [self enqueueOperationWithURLRequest:request
                                                               requiresAuthentication:YES
                                                                              success:^(AFHTTPRequestOperation *requestOperation, id responseObject) {
                                                                                  if (success) success();
                                                                              } failure:^(AFHTTPRequestOperation *requestOperation, NSError *error) {
                                                                                  if (failure) failure(error);
                                                                              }];
                                                 
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}

- (void)trashObjectID:(NSString *)objectID success:(void (^)())success failure:(void (^)(NSError *))failure
{
    NSParameterAssert(objectID);
    [self getCachedAccountInfoWithSuccess:^(GDSugarSyncAccountInfo *accountInfo) {
        NSString *deletedItemsFolderID = accountInfo.deletedItemsObjectID;
        
        [self moveObjectID:objectID toFolderID:deletedItemsFolderID name:nil success:success failure:failure];
        
    } failure:failure];
}

- (void)copyFileID:(NSString *)fileID toFolderID:(NSString *)folderID name:(NSString *)name success:(void (^)(NSString *newFileID))success failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(fileID);
    NSParameterAssert(folderID);
    NSParameterAssert(name);
    NSString *sourceURLString = [[self.baseURL URLByAppendingPathComponent:fileID] absoluteString];
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"POST"
                                                path:folderID
                                       urlParameters:nil
                                     xmlTemplateName:@"SugarSyncCopyFileRequest"
                               substitutionVariables:@{@"source": sourceURLString, @"displayName": name}
                                 requiresAccessToken:YES
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 NSDictionary *httpHeaders = [[operation response] allHeaderFields];
                                                 NSString *newFileURLString = httpHeaders[@"Location"];
                                                 NSString *newFileID = [(NSURL *)[NSURL URLWithString:newFileURLString] path];
                                                 if (success) success(newFileID);
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];
}

#pragma mark - Downloading

- (NSOperation *)downloadFileID:(NSString *)fileID intoPath:(NSString *)localPath fileVersionID:(NSString *)fileVersionID
                       progress:(void (^)(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead))progress
                        success:(void (^)(NSString *localPath, GDSugarSyncMetadata *metadata, NSString *fileVersionID))success
                        failure:(void (^)(NSError *error))failure
{
    GDSugarSyncDownloadOperation *downloadOperation = [[GDSugarSyncDownloadOperation alloc] initWithClient:self
                                                                                                    fileID:fileID
                                                                                               toLocalPath:localPath
                                                                                                   success:success
                                                                                                   failure:failure];
    
    downloadOperation.downloadProgressBlock = progress;
    downloadOperation.fileVersionID = fileVersionID;
    
    [downloadOperation start];
    
    return downloadOperation;
}

#pragma mark - Uploading and creating files

- (void)createFileWithName:(NSString *)filename mimeType:(NSString *)mimeType inCollectionID:(NSString *)collectionID
                   success:(void (^)(NSString *objectID))success
                   failure:(void (^)(NSError *error))failure
{
    NSDictionary *substitutions = @{
                                    @"displayName"      : DICTIONARY_SAFE(filename),
                                    @"mediaType"        : DICTIONARY_SAFE(mimeType),
                                    };
    
    [self enqueueSugarSyncRequestOperationWithMethod:@"POST"
                                                path:collectionID
                                       urlParameters:nil
                                     xmlTemplateName:@"SugarSyncCreateFileRequest"
                               substitutionVariables:substitutions
                                             success:^(AFHTTPRequestOperation *operation, DDXMLDocument *responseDocument) {
                                                 NSDictionary *httpHeaders = [[operation response] allHeaderFields];
                                                 NSString *objectURLString = httpHeaders[@"Location"];
                                                 if (objectURLString) {
                                                     NSURL *objectURL = [NSURL URLWithString:objectURLString];
                                                     NSString *objectID = [GDSugarSyncMetadata objectIDFromObjectURL:objectURL];
                                                     
                                                     if (success) {
                                                         return success(objectID);
                                                     }
                                                 }
                                                 if (failure) failure(nil);
                                             } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 if (failure) failure(error);
                                             }];

}

- (NSOperation *)uploadFile:(NSString *)localPath toFileID:(NSString *)fileID parentVersionID:(NSString *)parentVersionID
                uploadState:(GDSugarSyncUploadState *)uploadState uploadStateHandler:(void (^)(GDSugarSyncUploadState *))uploadStateHandler
                   progress:(void (^)(NSUInteger, long long, long long))progress
                    success:(void (^)(GDSugarSyncMetadata *, NSString *, NSArray *))success
                    failure:(void (^)(NSError *))failure
{
    GDSugarSyncUploadOperation *uploadOperation = [[GDSugarSyncUploadOperation alloc] initWithClient:self fromLocalPath:localPath toFileID:fileID
                                                                                             success:success
                                                                                             failure:failure];
    
    uploadOperation.uploadProgressBlock = progress;
    uploadOperation.uploadStateHandler = uploadStateHandler;
    uploadOperation.uploadState = uploadState;
    uploadOperation.parentVersionID = parentVersionID;
    
    [uploadOperation start];
    
    return uploadOperation;
}

#pragma mark - Metadata support

- (GDSugarSyncMetadata *)workspacesMetadata
{
    if (!self.userID) return nil;

    NSURL *url = [self.baseURL URLByAppendingPathComponent:[NSString pathWithComponents:@[@"/", @"user", self.userID, @"workspaces"]]];
    
    NSDictionary *rawMetadata = @{
    @"displayName"  : @"Devices",
    @"ref"          : [url absoluteString],
    GDSugarSyncMetadataXMLElementKey : @"collection",
    };
    
    GDSugarSyncMetadata *metadata = [[GDSugarSyncMetadata alloc] initWithDictionary:rawMetadata];
    return metadata;
}

- (GDSugarSyncMetadata *)syncFoldersMetadata
{
    if (!self.userID) return nil;
    
    NSURL *url = [self.baseURL URLByAppendingPathComponent:[NSString pathWithComponents:@[@"/", @"user", self.userID, @"folders"]]];
    
    NSDictionary *rawMetadata = @{
    @"displayName"  : @"All Folders",
    @"ref"          : [url absoluteString],
    GDSugarSyncMetadataXMLElementKey : @"collection",
    };
    
    GDSugarSyncMetadata *metadata = [[GDSugarSyncMetadata alloc] initWithDictionary:rawMetadata];
    return metadata;
}

- (GDSugarSyncMetadata *)rootMetadata
{
    if (!self.userID) return nil;

    NSURL *url = [self.baseURL URLByAppendingPathComponent:@"/"];
    
    NSDictionary *rawMetadata = @{
    @"displayName"  : @"/",
    @"ref"          : [url absoluteString],
    GDSugarSyncMetadataXMLElementKey : @"collection",
    };
    
    GDSugarSyncMetadata *metadata = [[GDSugarSyncMetadata alloc] initWithDictionary:rawMetadata];
    return metadata;
}


#pragma mark - XML support

- (BOOL)setString:(NSString *)string asContentForElementWithName:(NSString *)elementName inXMLElement:(DDXMLElement *)rootElement
{
    DDXMLElement *childElement = [rootElement elementForName:elementName];
    if (!childElement) {
        // Try attribute
        DDXMLNode *attributeNode = [rootElement attributeForName:elementName];
        if (!attributeNode)
            return NO;
        [attributeNode setStringValue:string];
        return YES;
    }
    DDXMLNode *textNode = [DDXMLNode textWithStringValue:string];
    if (!textNode) {
        return NO;
    }
    [childElement setChildren:@[textNode]];
    return YES;
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
        if ([rootNode.name isEqualToString:@"collectionContents"]) {
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
        } else if (rootNode.kind == DDXMLElementKind && rootNode.childCount == 0 && [(DDXMLElement *)rootNode attributeForName:@"enabled"]) {
            NSDictionary *attributeDictionary = [(DDXMLElement *)rootNode attributesAsDictionary];
            NSString *enabledString = attributeDictionary[@"enabled"];
            return enabledString;
        } else {
            NSMutableDictionary *result = [NSMutableDictionary new];
            for (DDXMLNode *childNode in rootNode.children) {
                id childObject = [self objectFromXMLNode:childNode];
                if (!childObject) {
                    NSLog(@"Failed to decode XML %@ into an object", childNode);
                } else {
                    result[childNode.name] = childObject;
                }
            }
            result[GDSugarSyncMetadataXMLElementKey] = rootNode.name;
            return [result copy];
        }
    } else {
        NSLog(@"Don't know how to handle element: %@", rootNode);
    }
    return nil;
}

- (NSArray *)metadataArrayFromXMLNode:(DDXMLNode *)xmlNode
{
    if (![xmlNode.name isEqualToString:@"collectionContents"] &&
        ![xmlNode.name isEqualToString:@"fileVersions"]) {
        NSLog(@"Don't understand XML Node: %@", xmlNode);
        return nil;
    }
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:xmlNode.childCount];
    for (DDXMLNode *childNode in xmlNode.children) {
        NSDictionary *metadataDictionary = [self objectFromXMLNode:childNode];
        GDSugarSyncMetadata *metadata = [[GDSugarSyncMetadata alloc] initWithDictionary:metadataDictionary];
        if (metadata)
            [result addObject:metadata];
    }
    return [result copy];
}

@end
