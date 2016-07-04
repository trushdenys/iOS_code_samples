#import <Foundation/Foundation.h>

@protocol RPAttachmentManagerDelegate <NSObject>

- (void) receivedProgress: (int64_t) bytes
                 fullSize: (int64_t) fullBytes;

@end

@interface RPAttachmentsUploadingWrapper : NSObject

@property (weak) id<RPAttachmentManagerDelegate> attachmentManagerDelegate;

- (void) startToUploadFileWithName: (NSString *) name
                          fileData: (NSData *) data
                      fileMimeType: (NSString *) mimeType
                      fileMemberID: (NSString *) memberID
                      inBackground: (bool) isBackgroundUploading
                      withCallback: (void(^)(bool result, id responseObject, NSString *errorStr))callbackBlock;

- (void) cancelFileUploading;

@end
