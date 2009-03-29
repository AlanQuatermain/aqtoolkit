/*
 *  ASLQuery.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *
 *  Copyright (c) 2008-2009, Jim Dovey
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
#import <asl.h>
#import "ASLMessage.h"

enum
{
	// these values are mutually exclusive
	ASLQueryOperationEqual				= ASL_QUERY_OP_EQUAL,
	ASLQueryOperationGreater			= ASL_QUERY_OP_GREATER,
	ASLQueryOperationGreaterOrEqual		= ASL_QUERY_OP_GREATER_EQUAL,
	ASLQueryOperationLess				= ASL_QUERY_OP_LESS,
	ASLQueryOperationLessOrEqual		= ASL_QUERY_OP_LESS_EQUAL,
	ASLQueryOperationNotEqual			= ASL_QUERY_OP_NOT_EQUAL,
	ASLQueryOperationTrue				= ASL_QUERY_OP_TRUE,
	
	// these values can be bitwise-OR'd along with one of those above
	// you may use any number of these (they are all bitflags)
	ASLQueryOperationCaseFold			= ASL_QUERY_OP_CASEFOLD,
	ASLQueryOperationPrefix				= ASL_QUERY_OP_PREFIX,
	ASLQueryOperationSuffix				= ASL_QUERY_OP_SUFFIX,
	ASLQueryOperationSubstring			= ASL_QUERY_OP_SUBSTRING,
	ASLQueryOperationNumeric			= ASL_QUERY_OP_NUMERIC,
	ASLQueryOperationRegularExpression	= ASL_QUERY_OP_REGEX
	
};
typedef uint32_t ASLQueryOperation;

@interface ASLQuery : ASLMessage

// attributes tested for equality can be set using the interface provided by
//  ASLMessage; for other operations, the following method is provided
- (void) setValue: (id) value forKey: (NSString *) key withOperation: (ASLQueryOperation) operation;

@end
