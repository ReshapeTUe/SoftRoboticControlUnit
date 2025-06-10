#if defined __cplusplus
extern "C" {
#endif

#ifndef VEAB_OUTPUT_H_
#define VEAB_OUTPUT_H_

#include <cstdint>

void setupAdc(uint8_t bus);
void setAllVeab(uint8_t bus, uint8_t channel, double value1, double value2, double value3, double value4, double resolution);
void getAllVeab(uint8_t bus, double resolution, double* in1, double* in2, double* in3, double* in4 );
void setVeab(uint8_t bus, uint8_t channel, double value, double resolution);
uint32_t getVeab(uint8_t bus, uint8_t channel, double resolution );
uint32_t test_f();

#endif /* VEAB_OUTPUT_H_ */

#if defined __cplusplus
}
#endif