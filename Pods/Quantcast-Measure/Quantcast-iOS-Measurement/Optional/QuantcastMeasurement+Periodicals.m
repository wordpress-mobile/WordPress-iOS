/*
 * Copyright 2012 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License.
 *
 */

#import "QuantcastMeasurement+Periodicals.h"
#import "QuantcastEvent.h"
#import "QuantcastDataManager.h"
#import "QuantcastParameters.h"
#import "QuantcastUtils.h"

#define QCMEASUREMENT_EVENT_PERIODICALOPENISSUE     @"periodical-issue-open"
#define QCMEASUREMENT_EVENT_PERIODICALCLOSEISSUE    @"periodical-issue-close"
#define QCMEASUREMENT_EVENT_PERIODICALPAGEVIEW      @"periodical-page-view"
#define QCMEASUREMENT_EVENT_PERIODICALARTICLEVIEW   @"periodical-article-view"
#define QCMEASUREMENT_EVENT_PERIODICALDOWNLOAD      @"periodical-download"

#define QCPARAMETER_PERIODICAL_PERIODICALNAME   @"periodical-name"
#define QCPARAMETER_PERIODICAL_ISSUENAME        @"issue-name"
#define QCPARAMETER_PERIODICAL_ISSUEDATE        @"issue-date"
#define QCPARAMETER_PERIODICAL_ARTICLE          @"article"
#define QCPARAMETER_PERIODICAL_AUTHOR           @"authors"
#define QCPARAMETER_PERIODICAL_PAGE             @"pagenum"



@interface QuantcastMeasurement ()
@property (readonly,nonatomic) BOOL isMeasurementActive;
@property (retain,nonatomic) QuantcastDataManager* dataManager;
@property (retain,nonatomic) NSString* currentSessionID;

-(void)recordEvent:(QuantcastEvent*)inEvent;

@end

@implementation QuantcastMeasurement (Periodicals)

-(void)logAssetDownloadCompletedWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil {
    [self logAssetDownloadCompletedWithPeriodicalNamed:inPeriodicalName issueNamed:inIssueName issuePublicationDate:inPublicationDate withAppLabels:inLabelsOrNil networkLabels:nil];
}

-(void)logAssetDownloadCompletedWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil {
    
    if ( nil == inPeriodicalName ) {
        NSLog(@"QC Measurement: ERROR - The inPeriodicalName parameter cannot be nil");
        return;
    }
    
    if ( nil == inIssueName ) {
        NSLog(@"QC Measurement: ERROR - The inIssueName parameter cannot be nil");
        return;
    }
    
    if ( nil == inPublicationDate ) {
        NSLog(@"QC Measurement: ERROR - The inPublicationDate parameter cannot be nil");
        return;        
    }

    
    if ( !self.isOptedOut ) {
        if (self.isMeasurementActive) {
            QuantcastEvent* e = [QuantcastEvent eventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy];
            
            NSString* issueTimeStamp = nil;
            
            if ( nil != inPublicationDate) {
                issueTimeStamp = [NSString stringWithFormat:@"%qi",(int64_t)[inPublicationDate timeIntervalSince1970]];
            }
            [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_PERIODICALDOWNLOAD enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_PERIODICALNAME withValue:[QuantcastUtils JSONEncodeString:inPeriodicalName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUENAME withValue:[QuantcastUtils JSONEncodeString:inIssueName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUEDATE withValue:issueTimeStamp enforcingPolicy:self.dataManager.policy];
            
            [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil enforcingPolicy:self.dataManager.policy];
            
            [self recordEvent:e];
        }
        else {
            NSLog(@"QC Measurement: logCompletedDownloadingIssueName: was called without first calling beginMeasurementSession:");
        }
    }
}

-(void)logOpenIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil {
    [self logOpenIssueWithPeriodicalNamed:inPeriodicalName issueNamed:inIssueName issuePublicationDate:inPublicationDate withAppLabels:inLabelsOrNil networkLabels:nil];
}
-(void)logOpenIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil {

    if ( nil == inPeriodicalName ) {
        NSLog(@"QC Measurement: ERROR - The inPeriodicalName parameter cannot be nil");
        return;
    }
    
    if ( nil == inIssueName ) {
        NSLog(@"QC Measurement: ERROR - The inIssueName parameter cannot be nil");
        return;
    }
    
    if ( nil == inPublicationDate ) {
        NSLog(@"QC Measurement: ERROR - The inPublicationDate parameter cannot be nil");
        return;
    }

    if ( !self.isOptedOut ) {
        if (self.isMeasurementActive) {
            QuantcastEvent* e = [QuantcastEvent eventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy];
            
            NSString* issueTimeStamp = nil;
            
            if ( nil != inPublicationDate) {
                issueTimeStamp = [NSString stringWithFormat:@"%qi",(int64_t)[inPublicationDate timeIntervalSince1970]];
            }
            [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_PERIODICALOPENISSUE enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_PERIODICALNAME withValue:[QuantcastUtils JSONEncodeString:inPeriodicalName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUENAME withValue:[QuantcastUtils JSONEncodeString:inIssueName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUEDATE withValue:issueTimeStamp enforcingPolicy:self.dataManager.policy];

            [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil enforcingPolicy:self.dataManager.policy];
            
            [self recordEvent:e];
        }
        else {
            NSLog(@"QC Measurement: logPeriodicalOpenIssueNamed: was called without first calling beginMeasurementSession:");
        }
    }
}

-(void)logCloseIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil {
    [self logCloseIssueWithPeriodicalNamed:inPeriodicalName issueNamed:inIssueName issuePublicationDate:inPublicationDate withAppLabels:inLabelsOrNil networkLabels:nil];
}

-(void)logCloseIssueWithPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil {
    if ( nil == inPeriodicalName ) {
        NSLog(@"QC Measurement: ERROR - The inPeriodicalName parameter cannot be nil");
        return;
    }
    
    if ( nil == inIssueName ) {
        NSLog(@"QC Measurement: ERROR - The inIssueName parameter cannot be nil");
        return;
    }
    
    if ( nil == inPublicationDate ) {
        NSLog(@"QC Measurement: ERROR - The inPublicationDate parameter cannot be nil");
        return;
    }

    if ( !self.isOptedOut ) {
        if (self.isMeasurementActive) {
            QuantcastEvent* e = [QuantcastEvent eventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy];
            
            NSString* issueTimeStamp = nil;
            
            if ( nil != inPublicationDate) {
                issueTimeStamp = [NSString stringWithFormat:@"%qi",(int64_t)[inPublicationDate timeIntervalSince1970]];
            }
            [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_PERIODICALCLOSEISSUE enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_PERIODICALNAME withValue:[QuantcastUtils JSONEncodeString:inPeriodicalName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUENAME withValue:[QuantcastUtils JSONEncodeString:inIssueName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUEDATE withValue:issueTimeStamp enforcingPolicy:self.dataManager.policy];
            
            [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil enforcingPolicy:self.dataManager.policy];
            
            [self recordEvent:e];
        }
        else {
            NSLog(@"QC Measurement: logPeriodicalCloseIssueNamed: was called without first calling beginMeasurementSession:");
        }
    }
}

-(void)logPeriodicalPageView:(NSUInteger)inPageNumber withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withLabels:(id<NSObject>)inLabelsOrNil {
    [self logPeriodicalPageView:inPageNumber withPeriodicalNamed:inPeriodicalName issueNamed:inIssueName issuePublicationDate:inPublicationDate withAppLabels:inLabelsOrNil networkLabels:nil];
}

-(void)logPeriodicalPageView:(NSUInteger)inPageNumber withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil {
    if ( nil == inPeriodicalName ) {
        NSLog(@"QC Measurement: ERROR - The inPeriodicalName parameter cannot be nil");
        return;
    }
    
    if ( nil == inIssueName ) {
        NSLog(@"QC Measurement: ERROR - The inIssueName parameter cannot be nil");
        return;
    }
    
    if ( nil == inPublicationDate ) {
        NSLog(@"QC Measurement: ERROR - The inPublicationDate parameter cannot be nil");
        return;
    }

    if ( !self.isOptedOut ) {
        if (self.isMeasurementActive) {
            QuantcastEvent* e = [QuantcastEvent eventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy];
            
            NSString* issueTimeStamp = nil;
            
            if ( nil != inPublicationDate) {
                issueTimeStamp = [NSString stringWithFormat:@"%qi",(int64_t)[inPublicationDate timeIntervalSince1970]];
            }
            [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_PERIODICALPAGEVIEW enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_PERIODICALNAME withValue:[QuantcastUtils JSONEncodeString:inPeriodicalName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUENAME withValue:[QuantcastUtils JSONEncodeString:inIssueName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUEDATE withValue:issueTimeStamp enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_PAGE withValue:[NSNumber numberWithUnsignedInteger:inPageNumber] enforcingPolicy:self.dataManager.policy];
            
            [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil enforcingPolicy:self.dataManager.policy];
            
            [self recordEvent:e];
        }
        else {
            NSLog(@"QC Measurement: logPeriodicalPageViewWithIssueNamed: was called without first calling beginMeasurementSession:");
        }
    }
}


-(void)logPeriodicalArticleView:(NSString*)inArticleName withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate articleAuthors:(NSArray*)inAuthorListOrNil withLabels:(id<NSObject>)inLabelsOrNil {
    [self logPeriodicalArticleView:inArticleName withPeriodicalNamed:inPeriodicalName issueNamed:inIssueName issuePublicationDate:inPublicationDate articleAuthors:inAuthorListOrNil withAppLabels:inLabelsOrNil networkLabels:nil];
}

-(void)logPeriodicalArticleView:(NSString*)inArticleName withPeriodicalNamed:(NSString*)inPeriodicalName issueNamed:(NSString*)inIssueName issuePublicationDate:(NSDate*)inPublicationDate articleAuthors:(NSArray*)inAuthorListOrNil withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil {
    
    if ( nil == inPeriodicalName ) {
        NSLog(@"QC Measurement: ERROR - The inPeriodicalName parameter cannot be nil");
        return;
    }
    
    if ( nil == inIssueName ) {
        NSLog(@"QC Measurement: ERROR - The inIssueName parameter cannot be nil");
        return;
    }
    
    if ( nil == inPublicationDate ) {
        NSLog(@"QC Measurement: ERROR - The inPublicationDate parameter cannot be nil");
        return;
    }
    
    if ( nil == inArticleName ) {
        NSLog(@"QC Measurement: ERROR - The inArticleName parameter cannot be nil");
        return;
    }
    

    if ( !self.isOptedOut ) {
        if (self.isMeasurementActive) {
            QuantcastEvent* e = [QuantcastEvent eventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy];
            
            NSString* issueTimeStamp = nil;

            if ( nil != inPublicationDate) {
                issueTimeStamp = [NSString stringWithFormat:@"%qi",(int64_t)[inPublicationDate timeIntervalSince1970]];
            }
            
            [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_PERIODICALARTICLEVIEW enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_PERIODICALNAME withValue:[QuantcastUtils JSONEncodeString:inPeriodicalName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUENAME withValue:[QuantcastUtils JSONEncodeString:inIssueName] enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ISSUEDATE withValue:issueTimeStamp enforcingPolicy:self.dataManager.policy];
            [e putParameter:QCPARAMETER_PERIODICAL_ARTICLE withValue:[QuantcastUtils JSONEncodeString:inArticleName] enforcingPolicy:self.dataManager.policy];
            
            if ( nil != inAuthorListOrNil && inAuthorListOrNil.count > 0 ) {
                NSString* authorsString =  [QuantcastUtils encodeLabelsList:inAuthorListOrNil];

                [e putParameter:QCPARAMETER_PERIODICAL_AUTHOR withValue:authorsString enforcingPolicy:self.dataManager.policy];
            }
            
            [e putAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil enforcingPolicy:self.dataManager.policy];
            
            [self recordEvent:e];
        }
        else {
            NSLog(@"QC Measurement: logPeriodicalPageViewWithIssueName: was called without first calling beginMeasurementSession:");
        }
    }
}


@end
