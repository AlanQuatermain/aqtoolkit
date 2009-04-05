/*
 *  NSData+CommonCrypto.m
 *  AQToolkit
 *
 *  Created by Jim Dovey on 22/03/2009.
 *
 *  Copyright (c) 2009, Jim Dovey
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

#import <Foundation/Foundation.h>
#import <sysexits.h>
#import <getopt.h>
#import <stdarg.h>
#import "NSData+CommonCrypto.h"

/*
 gcc -framework Foundation -o CCCryptSample "NSData+CommonCrypto.m" "example.m"
 */

static void usage( void ) __dead2;
static void errexit( const char * format, ... ) __dead2;
static NSFileHandle * EnsureFile( const char * path, BOOL forWriting );
static CCAlgorithm ParseAlgorithm( const char * algoStr, CCOptions *pOpts );

static NSAutoreleasePool * gAutoreleasePool = nil;

static int gEncrypt = 1;

static const char *		_shortCommandLineArgs = "i:o:edk:x:a:v:h";
static struct option	_longCommandLineArgs[] = {
	{ "input", required_argument, NULL, 'i' },
	{ "output", required_argument, NULL, 'o' },
	{ "encrypt", no_argument, &gEncrypt, 1 },
	{ "decrypt", no_argument, &gEncrypt, 0 },
	{ "string-key", required_argument, NULL, 'k' },
	{ "binary-key", required_argument, NULL, 'x' },
	{ "algorithm", required_argument, NULL, 'a' },
	{ "input-vector", required_argument, NULL, 'v' },
	{ "help", no_argument, NULL, 'h' },
	{ NULL, 0, NULL, 0 }
};

#pragma mark -

static void usage( void )
{
	fprintf( stderr, "Encrypts or decrypts data to/from files or standard input/output.\n" );
	fprintf( stderr, "This tool supports multiple encryption algorithms, each with their own key sizes\n"
			 "(or range of key sizes).\n\n"
			 "Unless the input or output file options are specified, it reads data from standard input\n"
			 "and returns encrypted/decrypted data via standard output.\n\n"
			 "The key can be provided as either a string or as a path to a file containing binary key\n"
			 "data; exactly one of these must be supplied.\n\n"
			 "If neither the encrypt or decrypt option is specified, encryption is performed.  If no\n"
			 "algorithm is specified, AES is used.\n\n"
			 "Note that AES[128|192|256] refers to the key size, they all use the same encryption\n"
			 "algorithm.\n\n" );
	fprintf( stderr, "Usage: CCCryptSample [OPTIONS]\n" );
	fprintf( stderr, "  Options:\n" );
	fprintf( stderr, "    [-i|--input]=FILE       Path to a file containing input data.\n" );
	fprintf( stderr, "    [-o|--output]=FILE      Path to a file to contain the output.\n" );
	fprintf( stderr, "    [-e|--encrypt]          Encrypt data (the default).\n" );
	fprintf( stderr, "    [-d|--decrypt]          Decrypt data.\n" );
	fprintf( stderr, "    [-k|--string-key]=KEY   Specify a key as a string in UTF-8 format.\n" );
	fprintf( stderr, "    [-x|--binary-key]=FILE  Path to a file containing binary data to be used as a key.\n" );
	fprintf( stderr, "    [-a|--algorithm]=ALGO   Specify the encryption algorithm to use, from the following:\n" );
	fprintf( stderr, "         - AES (the default)\n" );
	fprintf( stderr, "         - DES\n" );
	fprintf( stderr, "         - 3DES\n" );
	fprintf( stderr, "         - CAST\n" );
	fprintf( stderr, "         - RC4\n" );
	fprintf( stderr, "    [-v|--input-vector]=IV  Supply an algorithm initialization vector as a string.\n" );
	fprintf( stderr, "    [-h|--help]             Display this information.\n" );
	fflush( stderr );
	[gAutoreleasePool drain];
	exit( EX_USAGE );
}

static void errexit( const char * format, ... )
{
	va_list args;
	va_start( args, format );
	vfprintf( stderr, format, args );
	va_end( args );
	[gAutoreleasePool drain];
	exit( EX_SOFTWARE );
}

static NSFileHandle * EnsureFile( const char * path, BOOL forWriting )
{
	BOOL isDir = NO;
	NSString * str = [[NSString alloc] initWithUTF8String: path];
	if ( [[NSFileManager defaultManager] fileExistsAtPath: str isDirectory: &isDir] == NO )
	{
		[[NSFileManager defaultManager] createFileAtPath: str
												contents: [NSData data]
											  attributes: nil];
	}
	else if ( isDir == YES )
	{
		[str release];
		errexit( "'%s' is a directory.\n", path );
	}
	
	NSFileHandle * result = nil;
	if ( forWriting )
	{
		result = [NSFileHandle fileHandleForWritingAtPath: str];
		[result truncateFileAtOffset: 0];
	}
	else
	{
		result = [NSFileHandle fileHandleForReadingAtPath: str];
	}
	
	[str release];
	return ( result );
}

static CCAlgorithm ParseAlgorithm( const char * algoStr, CCOptions *pOpts )
{
	if ( strncmp(algoStr, "AES", 3) == 0 )
		return ( kCCAlgorithmAES128 );
	
	if ( strncmp(algoStr, "DES", 3) == 0 )
		return ( kCCAlgorithmDES );
	
	if ( strncmp(algoStr, "3DES", 4) == 0 )
		return ( kCCAlgorithm3DES );
	
	if ( strncmp(algoStr, "CAST", 4) == 0 )
		return ( kCCAlgorithmCAST );
	
	// stream cipher, no options
	if ( strncmp(algoStr, "RC4", 3) == 0 )
	{
		*pOpts = 0;
		return ( kCCAlgorithmRC4 );
	}
	
	fprintf( stderr, "Unknown algorithm '%s'.\n", algoStr );
	usage();
}

int main( int argc, char * const argv[] )
{
	CCAlgorithm algo = kCCAlgorithmAES128;
	CCOptions opts = kCCOptionPKCS7Padding;
	id key = nil;
	NSString * iv = nil;
	NSFileHandle * input = nil;
	NSFileHandle * output = nil;
	BOOL closeInput = NO, closeOutput = NO;
	
	gAutoreleasePool = [[NSAutoreleasePool alloc] init];
	
	int ch;	
	while ( (ch = getopt_long(argc, argv, _shortCommandLineArgs, _longCommandLineArgs, NULL)) != -1 )
	{
		switch ( ch )
		{
			case 0:
				// a long option has just set a variable for us
				break;
			
			case 'h':
			default:
				usage();	// dead call, terminates program
				break;
				
			case 'i':
				input = EnsureFile( optarg, NO );
				closeInput = YES;
				break;
				
			case 'o':
				output = EnsureFile( optarg, YES );
				closeOutput = YES;
				break;
				
			case 'k':
				key = [NSString stringWithUTF8String: optarg];
				break;
				
			case 'e':
				gEncrypt = 1;
				break;
				
			case 'd':
				gEncrypt = 0;
				break;
				
			case 'x':
				key = [NSData dataWithContentsOfFile: [NSString stringWithUTF8String: optarg]];
				if ( key == nil )
					errexit( "Unable to load key from file '%s'.\n", optarg );
				break;
				
			case 'a':
				algo = ParseAlgorithm( optarg, &opts );	// calls usage() if invalid algorithm name
				break;
				
			case 'v':
				iv = [NSString stringWithUTF8String: optarg];
				break;
		}
	}
	
	if ( input == nil )
		input = [NSFileHandle fileHandleWithStandardInput];
	if ( output == nil )
		output = [NSFileHandle fileHandleWithStandardOutput];
	
	if ( key == nil )
		errexit( "You must supply an encryption key.\n" );
	
	CCCryptorStatus status = kCCSuccess;
	NSData * inputData = [input availableData];
	if ( [inputData length] == 0 )
		errexit( "Unable to read input data.\n" );
	
	NSData * outputData = nil;
	if ( gEncrypt )
	{
		outputData = [inputData dataEncryptedUsingAlgorithm: algo
														key: key
									   initializationVector: iv
													options: opts
													  error: &status];
	}
	else
	{
		outputData = [inputData decryptedDataUsingAlgorithm: algo
														key: key
									   initializationVector: iv
													options: opts
													  error: &status];
	}
	
	if ( status != kCCSuccess )
	{
		NSError * err = [NSError errorWithCCCryptorStatus: status];
		errexit( "Cryptor failed: %s\n", [[err localizedDescription] UTF8String] );
	}
	
	[output writeData: outputData];
	
	if ( closeInput )
		[input closeFile];
	if ( closeOutput )
		[output closeFile];
	
	[gAutoreleasePool drain];
	
	return ( EX_OK );
}
