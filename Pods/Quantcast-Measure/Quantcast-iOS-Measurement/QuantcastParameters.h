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

#import <Foundation/Foundation.h>

#pragma mark - Event Constants

// Base event parameters
#define QCPARAMETER_SID               @"sid"
#define QCPARAMETER_ET                @"et"


// Typed event
#define QCPARAMETER_EVENT             @"event"
#define QCPARAMETER_LABELS            @"labels"
#define QCPARAMETER_APPEVENT          @"appevent"

// Typed event parameters
#define QCMEASUREMENT_EVENT_LOAD        @"load"
#define QCMEASUREMENT_EVENT_REFRESH     @"refresh"
#define QCMEASUREMENT_EVENT_UPDATE      @"update"
#define QCMEASUREMENT_EVENT_FINISHED    @"finished"
#define QCMEASUREMENT_EVENT_PAUSE       @"pause"
#define QCMEASUREMENT_EVENT_RESUME      @"resume"

#define QCMEASUREMENT_EVENT_APPEVENT    @"appevent"
#define QCMEASUREMENT_EVENT_LOCATION    @"location"
#define QCMEASUREMENT_EVENT_LATENCY     @"latency"
#define QCMEASUREMENT_EVENT_NETINFO     @"netinfo"
#define QCMEASUREMENT_EVENT_SDKERROR    @"sdkerror"


// Open session event
#define QCPARAMETER_A                 @"a"
#define QCPARAMETER_AID               @"aid"
#define QCPARAMETER_ALT               @"alt"
#define QCPARAMETER_ANAME             @"aname"
#define QCPARAMATER_APIKEY            @"apikey"
#define QCPARAMETER_ASID              @"asid"
#define QCPARAMETER_AVER              @"aver"
#define QCPARAMETER_LOCALITY          @"l"
#define QCPARAMETER_COUNTRY           @"c"
#define QCPARAMETER_CT                @"ct"
#define QCPARAMETER_DG                @"dg"
#define QCPARAMETER_DID               @"did"
#define QCPARAMETER_DM                @"dm"
#define QCPARAMETER_DMOD              @"dmod"
#define QCPARAMETER_DOS               @"dos"
#define QCPARAMETER_DOSV              @"dosv"
#define QCPARAMETER_DST               @"dst"
#define QCPARAMETER_DTYPE             @"dtype"
#define QCPARAMETER_HAC               @"hac"
#define QCPARAMETER_ICC               @"icc"
#define QCPARAMETER_IVER              @"iver"
#define QCPARAMETER_LC                @"lc"
#define QCPARAMETER_LL                @"ll"
#define QCPARAMETER_MCC               @"mcc"
#define QCPARAMETER_MEDIA             @"media"
#define QCPARAMETER_MNC               @"mnc"
#define QCPARAMETER_MNN               @"mnn"
#define QCPARAMATER_PKID              @"pkid"
#define QCPARAMETER_SR                @"sr"
#define QCPARAMETER_STATE             @"st"
#define QCPARAMETER_TZO               @"tzo"
#define QCPARAMETER_UH                @"uh"
#define QCPARAMETER_VAC               @"vac"
#define QCPARAMETER_OPTOUT            @"optout"
#define QCPARAMETER_REASON            @"nsr"
#define QCPARAMETER_INSTALL           @"inst"
#define QCPARAMETER_INBACKGROUND      @"inback"

// Latency event
#define QCPARAMETER_LATENCY           @"latency"
#define QCPARAMETER_LATENCY_VALUE     @"latency-value"
#define QCPARAMETER_LATENCY_UPLID     @"uplid"

// Load event types
#define QCPARAMETER_REASONTYPE_LAUNCH       @"launch"
#define QCPARAMETER_REASONTYPE_RESUME       @"resume"
#define QCPARAMETER_REASONTYPE_USERHASH     @"userhash"
#define QCPARAMETER_REASONTYPE_ADPREFCHANGE @"adprefchange"

// SDK Error Event
#define QCPARAMETER_ERRORTYPE         @"error-type"     // required
#define QCPARAMETER_ERRORDESCRIPTION  @"error-desc"     // optional
#define QCPARAMETER_ERRORPARAMETER    @"error-param"    // optional

#define QC_SDKERRORTYPE_HTTPSAUTHCHALLENGE          @"https-auth-challenge"
#define QC_SDKERRORTYPE_UPLOADFAILURE               @"json-upload-failure"
#define QC_SDKERRORTYPE_POLICYDOWNLOADFAILURE       @"policy-download-failure"
#define QC_SDKERRORTYPE_GEOCODERFAILURE             @"geo-coder-failure"

// 
// Quantcast Measurement SDK
//

#define QCMEASUREMENT_API_VERSION               @"1_2_10"
#define QCMEASUREMENT_API_IDENTIFIER            @"iOS_1.2.10"
#define QCMEASUREMENT_CONN_TIMEOUT_SECONDS      60

#ifndef QCMEASUREMENT_UPLOAD_URL
    #define QCMEASUREMENT_UPLOAD_URL            @"http://m.quantcount.com/mobile"
#endif
#ifndef QCMEASUREMENT_POLICY_URL_FORMAT
    #define QCMEASUREMENT_POLICY_URL_FORMAT     @"http://m.quantcount.com/policy.json?a=%@&v=%@&t=%@&c=%@"
#endif

#define QCMEASUREMENT_CACHE_DIRNAME             @"qc-measurement-cache"
#define QCMEASUREMENT_POLICY_FILENAME           @"qc-policy.json"
#define QCMEASUREMENT_DATABASE_FILENAME         @"qcmeasurement.db"
#define QCMEASUREMENT_IDENTIFIER_FILENAME       @"qc-identifier.txt"
#define QCMEASUREMENT_ADIDPREF_FILENAME         @"ad-id-pref.txt"
#define QCMEASUREMENT_SESSIONID_FILENAME        @"session-id.txt"

#define QCMEASUREMENT_OPTOUT_PASTEBOARD         @"com.quantcast.measurement.optout"
#define QCMEASUREMENT_OPTOUT_STRING             @"QC-OPT-OUT"

#define QCMEASUREMENT_UA_PREFIX                 @" QuantcastSDK"

#ifndef QCMEASUREMENT_DEFAULT_MAX_SESSION_PAUSE_SECOND
    #define QCMEASUREMENT_DEFAULT_MAX_SESSION_PAUSE_SECOND  1800
#endif

#ifndef QCMEASUREMENT_DEFAULT_UPLOAD_EVENT_COUNT
#define QCMEASUREMENT_DEFAULT_UPLOAD_EVENT_COUNT 100
#endif

#ifndef QCMEASUREMENT_DEFAULT_BACKGROUND_UPLOAD_EVENT_COUNT
#define QCMEASUREMENT_DEFAULT_BACKGROUND_UPLOAD_EVENT_COUNT 4
#endif

#ifndef QCMEASUREMENT_ENABLE_GEOMEASUREMENT
#define QCMEASUREMENT_ENABLE_GEOMEASUREMENT 0
#endif
