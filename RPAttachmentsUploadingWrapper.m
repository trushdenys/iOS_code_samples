#import "RPAttachmentsUploadingWrapper.h"
#import "ApiMethodClass.h"

@interface RPAttachmentsUploadingWrapper()

@property (weak) NSURLSessionUploadTask *fileUploadTask;

@end

@implementation RPAttachmentsUploadingWrapper

- (void) startToUploadFileWithName: (NSString *) name
                          fileData: (NSData *) data
                      fileMimeType: (NSString *) mimeType
                      fileMemberID: (NSString *) memberID
                      inBackground: (bool) isBackgroundUploading
                      withCallback: (void(^)(bool result, id responseObject, NSString *errorStr))callbackBlock
{
    self.fileUploadTask = [ApiMethodClass didUploadAttachmentInBackground: isBackgroundUploading
                                                                 fileData: data
                                                                 fileName: name
                                                             fileMimeType: mimeType
                                                             fileMemberID: memberID
                                        attachmentManagerProgressingBlock: ^(int64_t bytes, int64_t fullBytes) {
                                            [self receivedBytes: bytes
                                                       fullSize: fullBytes];
                                        }
                                                                 callback: ^(bool result, id responseObject, NSString *errorStr)
                           {
                               callbackBlock(result, responseObject, errorStr);
                           }];
    
    if (self.fileUploadTask)
    {
        [self.fileUploadTask resume];
    }
}

- (void) cancelFileUploading
{
    if (self.fileUploadTask)
    {
        [self.fileUploadTask cancel];
    }
}

#pragma mark - Delegate progress

- (void) receivedBytes: (int64_t) bytes
              fullSize: (int64_t) fullBytes
{
    [self.attachmentManagerDelegate receivedProgress: bytes
                                            fullSize: fullBytes];
}

@end
