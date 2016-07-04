#import "RPAttachmentsUploadingManager.h"

@interface RPAttachmentsUploadingManager()

- (NSInteger) indexForAttachment: (AttachmentEntity *) aAttachment;
- (void) startUploadFirstFileInQueue;

@property (nonatomic, strong) NSMutableArray *attachments;

@end

const NSString* kAttachmentNameKey = @"name";
const NSString* kAttachmentKey = @"attachment";
const NSString* kAttachmentUploadingWrapperKey = @"wrapper";
const NSString* kAttachmntUploadStatus = @"isUploading";

@implementation RPAttachmentsUploadingManager

+ (instancetype) sharedInstance
{
    static RPAttachmentsUploadingManager* instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[RPAttachmentsUploadingManager alloc] init];
    });

    return instance;
}

#pragma mark - Attachments queue

- (void) addAttachmentForUploading: (AttachmentEntity *) attachment
{
    if (attachment.localCachedFilePath == nil || attachment.size == 0 || attachment.name == nil)
    {
        return;
    }
    RPAttachmentsUploadingWrapper *wrapper = [[RPAttachmentsUploadingWrapper alloc] init];
    wrapper.attachmentManagerDelegate = self;
    if (self.attachments == nil)
    {
        self.attachments = [[NSMutableArray alloc] init];
    }
    NSDictionary* dict = @{kAttachmentNameKey: attachment.name,
                           kAttachmentKey: attachment,
                           kAttachmentUploadingWrapperKey: wrapper,
                           kAttachmntUploadStatus: [NSNumber numberWithBool: NO]};
    [self.attachments addObject: [dict mutableCopy]];
    [self startUploadFirstFileInQueue];
}

- (void) removeAttachmentFromUploading: (AttachmentEntity *) attachment
{
    NSInteger index = [self indexForAttachment: attachment];
    if (index != NSNotFound)
    {
        NSMutableDictionary* mutableDict = self.attachments[index];
        bool isUploading = mutableDict[kAttachmntUploadStatus];
        if (isUploading)
        {
            RPAttachmentsUploadingWrapper *wrapper = mutableDict[kAttachmentUploadingWrapperKey];
            [wrapper cancelFileUploading];
        }
        
        [self.attachments removeObjectAtIndex: index];
    }
}

#pragma mark - Attachment manager delegate

- (void) receivedProgress: (int64_t) bytes
                 fullSize: (int64_t) fullBytes
{
    NSArray *filtered = [self.attachments filteredArrayUsingPredicate:[[NSPredicate predicateWithFormat:@"(isUploading == %@)", [NSNumber numberWithBool: YES]] copy]];
    if ([filtered count] > 0) {
        NSDictionary *dict = [filtered objectAtIndex:0];
        [self.attachmentProxyDelegate receivedProgress: bytes
                                             fullBytes: fullBytes
                                         forAttachment: dict[kAttachmentKey]];
    }

}

#pragma mark - Private

- (NSInteger) indexForAttachment: (AttachmentEntity *) aAttachment
{
    NSInteger indexForAttachment = NSNotFound;

    for (NSInteger index = 0; index < self.attachments.count; index++)
    {
        NSDictionary* dict = (NSDictionary*) self.attachments[index];

        if ([dict[kAttachmentNameKey] isEqualToString: aAttachment.name] && dict[kAttachmentKey] == aAttachment)
        {
            indexForAttachment = index;
        }
    }

    return indexForAttachment;
}

- (void) startUploadFirstFileInQueue
{
    NSMutableDictionary *dictAttach = [self.attachments firstObject];
    if (dictAttach)
    {
        NSNumber *isUploading = dictAttach[kAttachmntUploadStatus];
        if (![isUploading boolValue])
        {
            dictAttach[kAttachmntUploadStatus] = [NSNumber numberWithBool:YES];
            RPAttachmentsUploadingWrapper *wrapper = dictAttach[kAttachmentUploadingWrapperKey];
            AttachmentEntity *attachment = dictAttach[kAttachmentKey];
            [self.attachmentProxyDelegate didStartUploadingFile: attachment];
            [wrapper startToUploadFileWithName: attachment.name
                                      fileData: attachment.cachedFileDataForUpload
                                  fileMimeType: [AttachmentEntity mimeTypeForFileAtPath: attachment.name]
                                  fileMemberID: attachment.memberID
                                  inBackground: YES
                                  withCallback: ^(bool result, id responseObject, NSString *errorStr) {
                                      if (result)
                                      {
                                          NSArray *uploadedAttachments = [[responseObject objectForKey: @"UploadAttachments"] objectForKey: @"Files"];
                                          attachment.attachmentId = [[uploadedAttachments firstObject] objectForKey: @"FileID"];
                                          attachment.isUploaded = YES;
                                      }
                                      [self.attachmentProxyDelegate didFinishUploadingFile: attachment
                                                                                withResult: result];
                                      [self.attachments removeObject:dictAttach];
                                      [self startUploadFirstFileInQueue];
                                  }];
        }
    }
}

@end
