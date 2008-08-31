/*
 *  ASLQuery.h
 *  AQToolkit
 *
 *  Created by Jim Dovey on 31/8/2008.
 *  Copyright (c) 2008 Jim Dovey. Some Rights Reserved.
 *
 *  This work is licensed under a Creative Commons
 *  Attribution License. You are free to use, modify,
 *  and redistribute this work, but may only distribute
 *  the resulting work under the same, similar or a
 *  compatible license. In addition, you must include
 *  the following disclaimer:
 *
 *    Portions Copyright (c) 2008 Jim Dovey
 *
 *  For license details, see:
 *    http://creativecommons.org/licenses/by-sa/3.0/
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
