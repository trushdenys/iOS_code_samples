#import <Foundation/Foundation.h>
#import "RPAttachmentsUploadingWrapper.h"
#import "AttachmentEntity.h"

@protocol RPComposerEnvelopeProxyDelegate <NSObject>

- (void) didFinishUploadingFile: (AttachmentEntity *) attachment
                     withResult: (bool) result;
- (void) didStartUploadingFile: (AttachmentEntity *) attachment;
- (void) receivedProgress: (int64_t) bytes
                fullBytes: (int64_t) fullBytes
            forAttachment: (AttachmentEntity *) attachment;

@end

@interface RPAttachmentsUploadingManager : NSObject <RPAttachmentManagerDelegate>

@property (weak) id<RPComposerEnvelopeProxyDelegate> attachmentProxyDelegate;

+ (instancetype) sharedInstance;

- (void) addAttachmentForUploading: (AttachmentEntity *) attachment;
- (void) removeAttachmentFromUploading: (AttachmentEntity *) attachment;

@end
