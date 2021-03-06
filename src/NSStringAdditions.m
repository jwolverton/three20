#import "Three20/TTGlobal.h"

//////////////////////////////////////////////////////////////////////////////////////////////////

@interface TTMarkupStripper : NSObject {
  NSMutableArray* _strings;
}

- (NSString*)parse:(NSString*)string;

@end

@implementation TTMarkupStripper

//////////////////////////////////////////////////////////////////////////////////////////////////
// NSObject

- (id)init {
  if (self = [super init]) {
    _strings = nil;
  }
  return self;
}

- (void)dealloc {
  [_strings release];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
  [_strings addObject:string];
}

- (NSData *)parser:(NSXMLParser *)parser resolveExternalEntityName:(NSString *)entityName systemID:(NSString *)systemID {
  static NSDictionary* entityTable = nil;
  if (!entityTable) {
    // XXXjoe Gotta get a more complete set of entities
    entityTable = [[NSDictionary alloc] initWithObjectsAndKeys:
      [NSData dataWithBytes:" " length:1], @"nbsp",
      [NSData dataWithBytes:"&" length:1], @"amp",
      [NSData dataWithBytes:"\"" length:1], @"quot",
      [NSData dataWithBytes:"<" length:1], @"lt",
      [NSData dataWithBytes:">" length:1], @"gt",
      nil];
  }
  return [entityTable objectForKey:entityName];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// public

- (NSString*)parse:(NSString*)text {
  _strings = [[NSMutableArray alloc] init];

  NSString* document = [NSString stringWithFormat:@"<x>%@</x>", text];
  NSData* data = [document dataUsingEncoding:text.fastestEncoding];
  NSXMLParser* parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
  parser.delegate = self;
  [parser parse];
  
  return [_strings componentsJoinedByString:@""];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation NSString (TTCategory)

- (BOOL)isWhitespace {
  NSCharacterSet* whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  for (NSInteger i = 0; i < self.length; ++i) {
    unichar c = [self characterAtIndex:i];
    if (![whitespace characterIsMember:c]) {
      return NO;
    }
  }
  return YES;
}

- (BOOL)isEmptyOrWhitespace {
  return !self.length || 
         ![self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length;
}

// Copied and pasted from http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg28175.html
- (NSDictionary*)queryDictionaryUsingEncoding:(NSStringEncoding)encoding {
  NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"];
  NSMutableDictionary* pairs = [NSMutableDictionary dictionary];
  NSScanner* scanner = [[[NSScanner alloc] initWithString:self] autorelease];
  while (![scanner isAtEnd]) {
    NSString* pairString;
    [scanner scanUpToCharactersFromSet:delimiterSet intoString:&pairString];
    [scanner scanCharactersFromSet:delimiterSet intoString:NULL];
    NSArray* kvPair = [pairString componentsSeparatedByString:@"="];
    if (kvPair.count == 2) {
      NSString* key = [[kvPair objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:encoding];
      NSString* value = [[kvPair objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:encoding];
      [pairs setObject:value forKey:key];
    }
  }

  return [NSDictionary dictionaryWithDictionary:pairs];
}

- (NSString*)stringByRemovingHTMLTags {
  TTMarkupStripper* stripper = [[[TTMarkupStripper alloc] init] autorelease];
  return [stripper parse:self];
}

@end
