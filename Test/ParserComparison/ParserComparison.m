/*
 *  ParserComparison.m
 *  ParserComparison
 *
 *  Created by Jim Dovey on 6/4/2009.
 *
 *  Copyright (c) 2009 Jim Dovey
 *  All rights reserved.
 *  
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *  Redistributions of source code must retain the above copyright notice,
 *  this list of conditions and the following disclaimer.
 *  
 *  Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *  
 *  Neither the name of this project's author nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
 *  FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#if TARGET_OS_IPHONE
# error This isn't designed for iPhone; it's a command-line app.
#endif

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import <sysexits.h>
#import <getopt.h>
#import <stdarg.h>
#import "AQXMLParser.h"
#import "MemoryUsageLogger.h"
#import "AQXMLParserDelegate.h"

static void usage( void ) __dead2;
static const char * MemorySizeString( mach_vm_size_t size );

static const char *     _shortCommandLineArgs = "f:u:ndmah";
static struct option    _longCommandLineArgs[] = {
    { "file", required_argument, NULL, 'f'},
    { "url", required_argument, NULL, 'u' },
    { "nsxmlparser", no_argument, NULL, 'n' },
    { "nsxmldocument", no_argument, NULL, 'd' },
    { "mapped-nsxmlparser", no_argument, NULL, 'm' },
    { "aqxmlparser", no_argument, NULL, 'a' },
    { "help", no_argument, NULL, 'h' },
    { NULL, 0, NULL, 0 }
};

enum
{
    Test_NSXMLParserWithURL,
    Test_NSXMLParserWithMappedData,
    Test_NSXMLDocument,
    Test_AQXMLParser
};

# pragma mark -

static void usage( void )
{
    fprintf( stderr, "Loads and parses an XML file containing 'number' elements in any\n"
             "structure, each containing a contiguous integer value.  The values are read\n"
             "into an NSMutableIndexSet, so as to avoid consuming too much memory with\n"
             "the parsed data.  We check the amount of virtual memory consumed by the app\n"
             "at certain points within the process, and print out the maximum amount of\n"
             "memory consumed.\n\n"
             "The different methods attempted are using NSXMLParser's -initWithURL:, with\n"
             "NSXMLParser's -initWithData: using a memory-mapped data object, and using\n"
             "AQXMLParser which reads data from a stream.\n\n" );
    fprintf( stderr, "Usage: ParserComparison [OPTIONS]\n" );
    fprintf( stderr, "  Options:\n" );
    fprintf( stderr, "    [-f|--file]=FILE           Path to an XML file to load.\n" );
    fprintf( stderr, "    [-u|--url]=URL             URL for an XML file to load. Must not require\n"
                     "                               authentication to access.\n" );
    fprintf( stderr, "    [-n|--nsxmlparser          Run NSXMLParser test direct from URL.\n" );
    fprintf( stderr, "    [-m|--mapped-nsxmlparser]  Run NSXMLParser test using mapped data\n" );
    fprintf( stderr, "    [-d|--nsxmldocument]       Run NSXMLDocument test direct from URL.\n" );
    fprintf( stderr, "    [-a|--aqxmlparser]         Run AQXMLParser test (default).\n" );
    fprintf( stderr, "    [-h|--help]                Display this message.\n\n" );
    fprintf( stderr, "If both -f and -u options are provided, -u takes precedence. If more than\n"
                     "one test-run argument is provided, runs the last one specified.\n" );
    fflush( stderr );
    exit( EX_USAGE );
}

static const char * MemorySizeString( mach_vm_size_t size )
{
    enum
    {
        kSizeIsBytes        = 0,
        kSizeIsKilobytes,
        kSizeIsMegabytes,
        kSizeIsGigabytes,
        kSizeIsTerabytes,
        kSizeIsPetabytes,
        kSizeIsExabytes
    };
    
    int sizeType = kSizeIsBytes;
    double dSize = (double) size;
    
    while ( isgreater(dSize, 1024.0) )
    {
        dSize = dSize / 1024.0;
        sizeType++;
    }
    
    NSMutableString * str = [[NSMutableString alloc] initWithFormat: (sizeType == kSizeIsBytes ? @"%.00f" : @"%.02f"), dSize];
    switch ( sizeType )
    {
        default:
        case kSizeIsBytes:
            [str appendString: @" bytes"];
            break;
            
        case kSizeIsKilobytes:
            [str appendString: @"KB"];
            break;
            
        case kSizeIsMegabytes:
            [str appendString: @"MB"];
            break;
            
        case kSizeIsGigabytes:
            [str appendString: @"GB"];
            break;
            
        case kSizeIsTerabytes:
            [str appendString: @"TB"];
            break;
            
        case kSizeIsPetabytes:
            [str appendString: @"PB"];
            break;
            
        case kSizeIsExabytes:
            [str appendString: @"EB"];
            break;
    }
    
    NSString * result = [str copy];
    [str release];
    
    return ( [[result autorelease] UTF8String] );
}

#pragma mark -

@interface NumberParser : AQXMLParserDelegate
{
    NSMutableIndexSet * set;
    mach_vm_size_t maxVMSize;
    mach_vm_size_t startVMSize;
}
@property (nonatomic, readonly, retain) NSMutableIndexSet * set;
@property (nonatomic, readonly) mach_vm_size_t maxVMSize;
@property (nonatomic) mach_vm_size_t startVMSize;
@end

@implementation NumberParser

@synthesize set;
@synthesize maxVMSize;
@synthesize startVMSize;

- (id) init
{
    if ( [super init] == nil )
        return ( nil );
    
    set = [[NSMutableIndexSet alloc] init];
    
    return ( self );
}

- (void) dealloc
{
    [set release];
    [super dealloc];
}

- (void) endNumber
{
    NSUInteger number = (NSUInteger) [self.characters integerValue];
    [set addIndex: number];
    
    mach_vm_size_t vmUsage = GetProcessMemoryUsage() - startVMSize;
    if ( vmUsage > maxVMSize )
        maxVMSize = vmUsage;
}

@end

#pragma mark -

static void RunNSDocumentTest( NSURL * url )
{
    fprintf( stdout, "Testing NSXMLDocument...\n" );
    
    mach_vm_size_t start = GetProcessMemoryUsage();
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    NSXMLDocument * doc = [[NSXMLDocument alloc] initWithContentsOfURL: url
                                                               options: NSXMLDocumentTidyXML
                                                                 error: NULL];
    time = CFAbsoluteTimeGetCurrent() - time;
    mach_vm_size_t end = GetProcessMemoryUsage();
    [doc release];
    
    fprintf( stdout, "  %.02f seconds, peak VM usage: %s\n", time, MemorySizeString(end - start) );
}

static void RunNSParserTest( NSURL * url )
{
    NSXMLParser * parser = [[NSXMLParser alloc] initWithContentsOfURL: url];
    NumberParser * delegate = [[NumberParser alloc] init];
    [parser setDelegate: delegate];
    
    fprintf( stdout, "Testing NSXMLParser from URL...\n" );
    
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    delegate.startVMSize = GetProcessMemoryUsage();
    
    (void) [parser parse];
    
    time = CFAbsoluteTimeGetCurrent() - time;
    fprintf( stdout, "  Parsed %lu numbers\n", (unsigned long)[delegate.set count] );
    fprintf( stdout, "  %.02f seconds, peak VM usage: %s\n", time, MemorySizeString(delegate.maxVMSize) );
    
    [delegate release];
    [parser release];
}

static NSData * MappedDataFromURL( NSURL * url )
{
    if ( [url isFileURL] )
        return ( [[NSData alloc] initWithContentsOfMappedFile: [url path]] );
    
    // download data
    NSData * downloadedData = [[NSData alloc] initWithContentsOfURL: url];
    [downloadedData writeToFile: @"downloaded.xml" atomically: NO];
    [downloadedData release];
    return ( [[NSData alloc] initWithContentsOfMappedFile: @"downloaded.xml"] );
}

static void RunMappedNSParserTest( NSURL * url )
{
    NSData * data = MappedDataFromURL( url );
    NSXMLParser * parser = [[NSXMLParser alloc] initWithData: data];
    [data release];
    
    NumberParser * delegate = [[NumberParser alloc] init];
    [parser setDelegate: delegate];
    
    fprintf( stdout, "Testing NSXMLParser with mapped data...\n" );
    
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    delegate.startVMSize = GetProcessMemoryUsage();
    
    (void) [parser parse];
    
    time = CFAbsoluteTimeGetCurrent() - time;
    fprintf( stdout, "  Parsed %lu numbers\n", (unsigned long)[delegate.set count] );
    fprintf( stdout, "  %.02f seconds, peak VM usage: %s\n", time, MemorySizeString(delegate.maxVMSize) );
    
    [delegate release];
    [parser release];
}

static NSInputStream * StreamFromURL( NSURL * url )
{
    if ( [url isFileURL] )
        return ( [[NSInputStream alloc] initWithFileAtPath: [url path]] );
    
    CFHTTPMessageRef msg = CFHTTPMessageCreateRequest( kCFAllocatorDefault, CFSTR("POST"),
                                                         (CFURLRef)url, kCFHTTPVersion1_1 );
    NSInputStream * stream = (NSInputStream *) CFReadStreamCreateForHTTPRequest( kCFAllocatorDefault, msg );
    CFRelease( msg );
    
    return ( stream );
}

static void RunAQParserTest( NSURL * url )
{
    NumberParser * delegate = [[NumberParser alloc] init];
    NSInputStream * stream = StreamFromURL( url );  // returns a retained stream
    AQXMLParser * parser = [[AQXMLParser alloc] initWithStream: stream];
    [stream release];
    
    [parser setDelegate: delegate];
    
    fprintf( stdout, "Testing AQXMLParser...\n" );
    
    CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
    delegate.startVMSize = GetProcessMemoryUsage();
    
    (void) [parser parse];
    
    time = CFAbsoluteTimeGetCurrent() - time;
    fprintf( stdout, "  Parsed %lu numbers\n", (unsigned long)[delegate.set count] );
    fprintf( stdout, "  %.02f seconds, peak VM usage: %s\n", time, MemorySizeString(delegate.maxVMSize) );
    
    [parser release];
    [delegate release];
}

#pragma mark -

int main (int argc, char * const argv[])
{
    const char * fileStr = NULL;
    const char * urlStr  = NULL;
    int ch = -1;
    int test = Test_AQXMLParser;
    
    while ( (ch = getopt_long(argc, argv, _shortCommandLineArgs, _longCommandLineArgs, NULL)) != -1 )
    {
        switch ( ch )
        {
            case 'h':
            default:
                usage();        // dead call, terminates program
                break;
                
            case 'f':
                fileStr = optarg;
                break;
                
            case 'u':
                urlStr = optarg;
                break;
                
            case 'n':
                test = Test_NSXMLParserWithURL;
                break;
                
            case 'm':
                test = Test_NSXMLParserWithMappedData;
                break;
                
            case 'd':
                test = Test_NSXMLDocument;
                break;
                
            case 'a':
                test = Test_AQXMLParser;
                break;
        }
    }
    
    if ( (fileStr == NULL) && (urlStr == NULL) )
        usage();        // dead call, terminates program
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    // we're going to avoid creating autoreleased objects as much as possible, so we can get them all
    //  deallocated & out of the way asap
    NSURL * url = nil;
    if ( urlStr != NULL )
    {
        NSString * str = [[NSString alloc] initWithUTF8String: urlStr];
        url = [NSURL URLWithString: str];
        [str release];
    }
    else
    {
        NSString * str = [[NSString alloc] initWithUTF8String: fileStr];
        url = [NSURL fileURLWithPath: str];
        [str release];
    }
    
    if ( ([url isFileURL] == NO) &&
         (([[url scheme] isEqualToString: @"http"] == NO) ||
          ([[url scheme] isEqualToString: @"https"] == NO)) )
    {
        [pool drain];
        usage();        // dead call, terminates program
    }

    switch ( test )
    {
        case Test_NSXMLDocument:
            RunNSDocumentTest( url );
            break;
            
        case Test_NSXMLParserWithURL:
            RunNSParserTest( url );
            break;
            
        case Test_NSXMLParserWithMappedData:
            RunMappedNSParserTest( url );
            break;
            
        default:
        case Test_AQXMLParser:
            RunAQParserTest( url );
            break;
    }
    
    [pool drain];
    
    return ( 0 );
}
