/*******************************************************************************
* balance_config.h
*******************************************************************************/

#ifndef FOAMCUTTER_SETUP
#define FOAMCUTTER_SETUP

#include <pthread.h>
#include <signal.h>
#include <unistd.h>
#include <wiringPi.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <dirent.h>
#include <time.h>
#include <errno.h>
#include <math.h>
#include <sys/resource.h>
#include <sys/types.h>

// Cutter Width
#define CUTTERWIDTH (36.0*IN2MM) // inches

// Unit Conversion
#define IN2MM 25.4
#define MM2IN (1.0/25.4)
#define IN2REV 10.0 // Lead screw 10 TPI
#define REV2PULSE 400.0 // depend on the switch settings on the motor drive
#define MM2PULSE ( IN2REV / IN2MM * REV2PULSE) // 157.48 PULSE = 1 mm

// Settings
#define FEEDRATE 0.8 // unit: mm/s
#define FEEDRATE_PUL (FEEDRATE*MM2PULSE)

// position of limit switch relative to cutter origin
#define LIM2ORIGIN_LX -4100  // 10mm
#define LIM2ORIGIN_RX -3550  // 10mm
#define LIM2ORIGIN_LY -2500 // 5mm
#define LIM2ORIGIN_RY -2400 // 5mm

// Motor Drive Pins
#define PIN_LX_DIR 14
#define PIN_LX_PUL 15
#define PIN_LY_DIR 18
#define PIN_LY_PUL 23
#define PIN_RX_DIR 24
#define PIN_RX_PUL 25
#define PIN_RY_DIR 8
#define PIN_RY_PUL 7

// Limit Switches
#define PIN_LX_LIM 6
#define PIN_LY_LIM 13
#define PIN_RX_LIM 19
#define PIN_RY_LIM 26

// Relay
#define PIN_RELAY 12

// Buttons
#define PIN_PAUSE 17
#define PIN_STOP 27

// Motor Polarity
// set to +1 or -1
// reverse the setting if the wire moves away from the limit switch during homing.
#define POLARITY_LX +1
#define POLARITY_LY -1
#define POLARITY_RX +1
#define POLARITY_RY -1

// MAX cut area
#define X_MAX (29.0*IN2MM)  // 29 in
#define Y_MAX (16.0*IN2MM)  // 16 in

#endif	//FOAMCUTTER_SETUP