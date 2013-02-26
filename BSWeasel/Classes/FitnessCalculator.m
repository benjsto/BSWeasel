//
//  FitnessCalculator.m
//  BSWeasel
//
//  Created by Benjamin Stockwell on 2/13/13.
//
//

#import "FitnessCalculator.h"

@implementation FitnessCalculator

+ (int)CalculateFitness: (unsigned char *)bitmap1
                 compareTo: (unsigned char *)bitmap2
                 withWidth: (int) width
                withHeight: (int) height;
{
    int numPixels = width * height;
    
    int errTotal = 0;
    
    for (int i = 0; i < numPixels; i++) {
        bgra *px1 = (bgra *)(&bitmap1[i]);
        bgra *px2 = (bgra *)(&bitmap2[i]);
        
        int errR = px1->r - px2->r;
        int errG = px1->g - px2->g;
        int errB = px1->b - px2->b;
        
        errTotal += abs(errR) + abs(errG) + abs(errB);
    }
    
    return errTotal;;
}

@end
