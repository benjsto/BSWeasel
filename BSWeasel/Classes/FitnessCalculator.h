//
//  FitnessCalculator.h
//  BSWeasel
//
//  Created by Benjamin Stockwell on 2/13/13.
//
//

#import <Foundation/Foundation.h>

typedef struct
{
    unsigned char b;
    unsigned char g;
    unsigned char r;
    unsigned char a;
} bgra;

@interface FitnessCalculator : NSObject

+ (int)CalculateFitness: (unsigned char *)bitmap1
                 compareTo: (unsigned char *)bitmap2
                 withWidth: (int)width
                withHeight: (int)height;

@end
