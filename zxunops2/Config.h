// Fichero de configuracion

#define PA 1 //
#define PB 2 //
#define PC 3 //
#define PD 4 //

#define ROWS8 8     //Numero de Filas de teclado 8x5
#define COLS5 5     //Numero de Columnas de teclado 8x5

//#define xchg_del_break
// Mapa de la matriz
// 1x1 = '1', 1x2 = '2'
// 2x1 = 'Q', 2x2 = 'W'
// ...

#define ROWS 8      //Numero de Filas de teclado en atmega 168/328
#define COLS 5      //Numero de Columnas de teclado en atmega 168/328

#define PS2_DAT     PC4
#define PS2_CLK     PC5

////////Pro Mini
#define PS2_PORT    PORTC
#define PS2_DDR     DDRC
#define PS2_PIN     PINC

#define LED_ON	PORTB |= (1<<5)
#define LED_OFF	PORTB &= ~(1<<5)
#define LED_CONFIG	DDRB |= (1<<5) //Led en PB5 en Pro mini y similares

//{PC1, PC0, PB4, PB3, PB2};
uint8_t pinsC[COLS] = {  1,  0,  4,  3,  2 }; // Configuracion de pines en el ZXGo+
uint8_t bcdC[COLS] =  { PC, PC, PB, PB, PB }; // Configuracion de pines en el ZXGo+

//{PD2, PD3, PD4, PD5, PD6, PD7, PB0, PB1};
uint8_t pinsR[ROWS] = {  2,  3,  4,  5,  6,  7,  0,  1 }; // Configuracion de pines en el ZXGo+
uint8_t bcdR[ROWS] =  { PD, PD, PD, PD, PD, PD, PB, PB }; // Configuracion de pines en el ZXGo+
