		.equ SCREEN_WIDTH,   640 //Ancho
		.equ SCREEN_HEIGH,   480 //Alto
		.equ BITS_PER_PIXEL, 32

		.equ GPIO_BASE,    0x3f200000
		.equ GPIO_GPFSEL0, 0x00
		.equ GPIO_GPLEV0,  0x34

		// Variables para cambiar el dibujo
		.equ SEMILLA, 2023			// Si cambias la semilla se generan estrellas en otras posiciones

		// Estos 3 valores hay que editarlos dependiendo donde se ejecuta el programa
		.equ DELEY_VALUE, 1000		// Si aumentas este numero, el deley es mas lento
		.equ AVANCE_DE_LA_NAVE, 3	// Este numero indica cuando pixels se desplaza la nave al moverse

		//Variable globar - (recomendable no tocar)
		.equ VELOCIDAD_NORMAL, 12 // Sin accionar la barra espaciadora         (Cuanto mayor es mas lento va)
		.equ VELOCIDAD_RAPIDA, 2  // Al haber accionado la barra espaciadora   (Cuanto menor es mas rapido va)
		.globl main


//------------------------------------ CODE HERE ------------------------------------//

 /*
 X0...X7   : argumentos/resultados
 X8        : ...
 X9...x15  : Temporales
 X16       : IP0
 X17       : IP1
 X18       : ...
 X19...X27 : Saved
 X28       : SP
 X29       : FP
 X30       : LR
 Xzr       : 0
 */


main: // x0 = direccion base del framebuffer
	
	/* Inicializacion */
	
	mov x27, x0 	// Guarda la dirección base del framebuffer en x20

	// Configuracion GPIOS
	
	mov x26, GPIO_BASE
	str wzr, [x26, GPIO_GPFSEL0] // Setea gpios 0 - 9 como lectura

	// Pintamos el fondo 
				// arg: x0 = direct base del frame buffer
	bl pintarFondo 

	////--------------------// CODE MAIN //---------------------------////
	
	mov x23, xzr                                  	// inicializamos posicion Y de las estrellas
	mov x24, VELOCIDAD_NORMAL						// inicializamos el delay

	            	// arg: x0 = direct base del frame buffer
	movz x3, 0xF3, lsl 16	// arg: Color del las estrellas 	
	movk x3, 0xF3F3, lsl 00 // Color del las estrellas (0xF3F3F3)
	mov x7, x23		// arg: desplazamiento vertical 
	bl fondoDinamico

	            	// x0 = direct base del frame buffer
	mov x1, 320 	// x
	mov x2, 320 	// y
	mov x3, x24
	bl nave			// Dibuja la nave	

 InfLoop_TECLAS:
   //-------------------- Animacion ---------------------------//

	// Borramos las estrellas:
	movz x3, 0x0E, lsl 16		//NEGRO
	movk x3, 0x0E0E, lsl 00		//NEGRO (#0E0E0E)
	                // arg: x0 = direct base del frame buffer
	                // arg: x3 = Color del las estrellas 
 	mov x7, x23		// arg: desplazamiento vertical
	bl fondoDinamico
					// arg: x0 = direct base del frame buffer
	mov x6, x24		// arg: x6 = tipo
					// arg: x7 = desplazamiento vertical
	bl borrarPlanetas

	//Dibujamos las estrellas:
	add x23, x23, 1 // y de estrellas + 1 (estrellas 1 pixel mas abajo)
	cmp x24, VELOCIDAD_NORMAL
	b.eq 8
	add x23,x23, 2
	
	movz x3, 0xF3, lsl 16		
	movk x3, 0xF3F3, lsl 00 // Color del las estrellas (0xF3F3F3)
                	// arg: x0 = direct base del frame buffer
	                // arg: Color del las estrellas 
 	mov x7, x23		// arg: desplazamiento vertical

	bl fondoDinamico

	//Dibujamos la nave
	mov x3, x24
    bl nave

	// Deley
	mov x25, x1
    mov x1 , x24				// Setea el deley
	bl deley

   //-------------------- Control de Teclas ---------------------------//

	mov x1, x25
	ldr w10, [x26, GPIO_GPLEV0]

	cmp x24, VELOCIDAD_NORMAL
	b.ne trubo
	
	lsr w11,w10, 1					// Tecla w
	and w11, w11,0b1				// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq w
	
	lsr w11,w10, 2					// Tecla a
	and w11, w11,1					// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq a
	
	lsr w11,w10, 3					// Tecla s
	and w11, w11,1					// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq s
	
	lsr w11,w10, 4					// Tecla d
	and w11, w11,1					// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq d		
 trubo:	
	lsr w11,w10, 5					// Tecla Barra espaciadora
	and w11, w11,1					// Mascara para comparar solo el primer bit	
	cmp w11, 1
	b.eq ep

	mov x19, xzr
    b   InfLoop_TECLAS    	 		// if (x11 != 1) ->  InfLoop_TECLAS

 //-------------------- Teclas en accion ---------------------------//

	// MAS PROPULSION DE LA NAVE
  ep:		
	cbnz x19, InfLoop_TECLAS

	mov x19, x11
	cmp x24, VELOCIDAD_NORMAL
	b.eq es_VELOCIDAD_NORMAL

	mov x24, VELOCIDAD_NORMAL		// si es VELOCIDAD_RAPIDA, lo ponemos en VELOCIDAD_NORMAL
	b InfLoop_TECLAS

   es_VELOCIDAD_NORMAL: 			// si es VELOCIDAD_NORMAL, lo ponemos en VELOCIDAD_RAPIDA
	mov x24, VELOCIDAD_RAPIDA
	b InfLoop_TECLAS

	
	// MOVER LA NAVE
  w:	bl borrar_nave		// Borra la nave

	sub x2, x2, AVANCE_DE_LA_NAVE	    // y - AVANCE_DE_LA_NAVE
	mov x3, x24
	bl nave				// Dibuja la nave avanzando AVANCE_DE_LA_NAVE pixeles
    mov x25, x1
	b InfLoop_TECLAS

  a:	bl borrar_nave	// Borra la nave

	sub x1, x1, AVANCE_DE_LA_NAVE		// x - AVANCE_DE_LA_NAVE
	mov x3, x24
	bl nave				// Dibuja la nave avanzando AVANCE_DE_LA_NAVE pixeles
    mov x25, x1
	b InfLoop_TECLAS

  s:	bl borrar_nave		// Borra la nave

	add x2, x2, AVANCE_DE_LA_NAVE		// x + AVANCE_DE_LA_NAVE
	mov x3, x24
	bl nave				// Dibuja la nave avanzando AVANCE_DE_LA_NAVE pixeles
    mov x25, x1
	b InfLoop_TECLAS

  d:	bl borrar_nave		// Borra la nave

	add x1, x1, AVANCE_DE_LA_NAVE	// x - AVANCE_DE_LA_NAVE
	mov x3, x24
	bl nave				// Dibuja la nave avanzando AVANCE_DE_LA_NAVE pixeles
    mov x25, x1
	b InfLoop_TECLAS

	////--------------------// END CODE MAIN //---------------------------////

endMain:
	b endMain

// Herramientas basicas:

pintarFondo: // pre: {}  args: (in x0 = direccion base del framebuffer)

	/* Inicializacion */
	sub sp, sp , 8
	stur x19 , [sp, #0]
	mov x19, x0
	//-------------------- CODE ---------------------------//
	movz x9, 0x0E0E, lsl 48
	movk x9, 0x0E0E, lsl 32
	movk x9, 0x0E0E, lsl 16		
	movk x9, 0x0E0E, lsl 00			//Color del fondo
	mov x10, SCREEN_WIDTH
	mov x11, SCREEN_HEIGH
	mul x10, x10 ,x11 				// x*y
	lsr x10, x10, 1
 loopPintarFondo:
	stur x9, [x0, #0]
	add x0, x0, 8
	sub x10, x10, 1
	cbnz x10, loopPintarFondo
	//-------------------- END CODE -------------------------//

	mov x0, x19

	ldur x19 , [sp, #0]
	add sp, sp , 8
endPintarFondo:	br lr

deley: // pre: {}    args: (in x1 = tamaño del deley)
	//-------------------- CODE ---------------------------//
	mov x9, DELEY_VALUE
	lsl x9, x9, x1
 deley_loop:   	
    sub x9, x9, #1
    cbnz x9, deley_loop
	//-------------------- END CODE -------------------------//
endDeley:	br lr 

p_pixel: // pre: { 0 <= x <= 480 && 0 <= y <= 640}    args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	sub sp, sp , 24
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur lr , [sp, #16]
	mov x19, x1
	mov x20, x2
	//-------------------- CODE ---------------------------//
	bl moduloWIDTH
	bl moduloHEIGH
	lsl x9, x1, 2 // x9 = x * 4
	lsl x10, x2, 2 // x10 = y * 4
	mov x11, SCREEN_WIDTH
	mul x10, x10, x11 // x10 = y * 4 * 640
	add x9, x9, x10 // x9 = x * 4 + y * 4 * 640
	add x9, x9 , x0 // x9 = direccion base del framebufer +  x * 4 + y * 4 * 640

	str w3, [x9,#0]
	//-------------------- END CODE -------------------------//
	mov x1, x19 
	mov x2, x20 
	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur lr , [sp, #16]
	add sp, sp , 24
end_p_pixel: br lr

moduloWIDTH: // pre: {}   args: (in/out x1 = eje x)
	//-------------------- CODE ---------------------------//
	cmp x1, 0					// if (x1 < 0) -> le sumo SCREEN_WIDTH
	b.ge noCambiaWIDTH	
 loopModuloWIDTH1:
	add x1, x1, SCREEN_WIDTH	//x1 = x1 + SCREEN_WIDTH
	cmp x1, 0
	b.lt loopModuloWIDTH1	
 noCambiaWIDTH:					// else 
	cmp x1, SCREEN_WIDTH		// if (x1 < SCREEN_WIDTH) -> termino
	b.lt endModuloWIDTH	
 loopModuloWIDTH2:				// else
	sub x1, x1, SCREEN_WIDTH	// x1 = x1 - SCREEN_WIDTH
	cmp x1, SCREEN_WIDTH		// if (x1 >= SCREEN_WIDTH ) -> itero
	b.ge loopModuloWIDTH2		// else -> termino
	//-------------------- END CODE -------------------------//
endModuloWIDTH: br lr

moduloHEIGH: // pre: {}   args: (in/out x2 = eje y)
	//-------------------- CODE ---------------------------//
	cmp x2, 0					// if (x2 < 0) -> le sumo SCREEN_HEIGH
	b.ge noCambiaHEIGH	
 loopModuloHEIGH1:
	add x2, x2, SCREEN_HEIGH	//x2 = x2 + SCREEN_HEIGH
	cmp x2, 0
	b.lt loopModuloHEIGH1	
 noCambiaHEIGH:				// else 
	cmp x2, SCREEN_HEIGH		// if (x2 < SCREEN_HEIGH) -> termino
	b.lt endModuloHEIGH	
 loopModuloHEIGH2:				// else
	sub x2, x2, SCREEN_HEIGH	// x2 = x2 - SCREEN_HEIGH
	cmp x2, SCREEN_HEIGH		// x2 (x2 >= SCREEN_HEIGH ) -> itero
	b.ge loopModuloHEIGH2			// else -> termino
	//-------------------- END CODE -------------------------//
endModuloHEIGH: br lr

// Formas basicas:

triangulo_punta_abajo:  // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color,  x4 = alto)
	
	/* Inicializacion */
	
	sub sp, sp , 56
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x26 , [sp, #32]
	stur x27 , [sp, #40]
	stur lr , [sp, #48]

	mov x21, x1 // x (cordenada)
	mov x22, x2 // y (cordenada)

    //-------------------- CODE ---------------------------//
	
	mov x19, x1 // x (cordenada)
	mov x20, x2 // y (cordenada)

	// Calculamos el inicio y final del triangulo:
	lsr x9, x4, 1             // Mitad del alto
	
	// Inicio:
	lsr x10, x4, 2             // Mitad de la mitad del alto
	sub x19, x1, x9            // x - mitad del alto
	
	sub x20, x2, x10           // y - mitad del alto
	
	// Final de x e y:
	add x26, x1, x9           	  // x26 = x + mitad del alto  
	add x27, x2, x10               // x27 = y + mitad del alto
	//add x27, x27, 1               // x27 = y + mitad del alto

	// Dibujamos: 
	mov x2, x20   	          // y
 tri_p_abajo_loop1:
	mov x1, x19               // x
 tri_p_abajo_loop2:	
	bl p_pixel                // args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	adds x1,x1, #1 	          // x + 1
	cmp x1 , x26     
	b.lt tri_p_abajo_loop2    // if (x < final_x ) -> tri_p_abajo_loop2
	add  x19, x19, 1          //  x + 1
	sub  x26, x26, 1		  // final_x - 1
	adds x2, x2, #1           // y + 1
	cmp x2 , x27 
	b.lt  tri_p_abajo_loop1   // if (y < final_y ) -> tri_p_abajo_loop1
	
	//-------------------- END CODE -------------------------//
	mov x1, x21
	mov x2, x22

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x26 , [sp, #32]
	ldur x27 , [sp, #40]
	ldur lr , [sp, #48]
	add sp, sp , 56

end_triangulo_punta_abajo: br lr

triangulo_punta_arriba:  // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color,  x4 = alto)
	
	/* Inicializacion */
	sub sp, sp , 56
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x26 , [sp, #32]
	stur x27 , [sp, #40]
	stur lr , [sp, #48]

	mov x21, x1 // x (cordenada)
	mov x22, x2 // y (cordenada)

    //-------------------- CODE ---------------------------//
	mov x19, x1 // x (cordenada)
	mov x20, x2 // y (cordenada)
	// Calculamos el inicio y final del triangulo:
	lsr x9, x4, 1             // Mitad del alto
	
	// Inicio:
	lsr x10, x4, 2             // Mitad de la mitad del alto
	sub x19, x1, x9            // x - mitad del alto
	add x20, x2, x10           // y + mitad del alto
	
	// Final de x e y:
	add x26, x1, x9           	  // x26 = x + mitad del alto  
	sub x27, x2, x10               // x27 = y - mitad del alto
	//sub x27, x27, 1               // x27 = y - mitad del alto

	// Dibujamos: 
	mov x2, x20   	          // y
 tri_p_arriba_loop1:
	mov x1, x19               // x
 tri_p_arriba_loop2:	
	bl p_pixel                // args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	adds x1,x1, #1 	          // x + 1
	cmp x1 , x26     
	b.lt tri_p_arriba_loop2    // if (x < final_x ) -> tri_p_arriba_loop2
	add  x19, x19, 1          //  x + 1
	sub  x26, x26, 1		  // final_x - 1
	subs x2, x2, #1           // y + 1
	cmp x2 , x27 
	b.gt  tri_p_arriba_loop1   // if (y > final_y ) -> tri_p_arriba_loop1
	
	//-------------------- END CODE -------------------------//

	mov x1, x21
	mov x2, x22

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x26 , [sp, #32]
	ldur x27 , [sp, #40]
	ldur lr , [sp, #48]
	add sp, sp , 56

end_triangulo_punta_arriba: br lr

rectangulo: // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color, x4 = ancho, x5 = alto)

	/* Inicializacion */
	sub sp, sp , 56
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x26 , [sp, #32]
	stur x27 , [sp, #40]
	stur lr , [sp, #48]
	
	mov x21, x1 // x (cordenada)
	mov x22, x2 // y (cordenada)

	
	//-------------------- CODE ---------------------------//

	mov x19, x1 // x (cordenada)
	mov x20, x2 // y (cordenada)
	
	// Calculamos el inicio y final del rectangulo:
	lsr x9, x4, 1    // Mitad del ancho
	lsr x10, x5, 1   // Mitad del alto
	
	// Inicio:
	sub x19, x1, x9  // x - mitad del ancho
	sub x19, x19, 1  // x - mitad del ancho - 1
	sub x20, x2, x10 // y - mitad del alto
	sub x20, x20, 1 // y - mitad del alto - 1
	
	// Final:
	add x26, x1, x9  // x + mitad del ancho
	sub x26, x26, 1  // x + mitad del ancho - 1
	add x27, x2, x10 // y + mitad del alto
	sub x27, x27, 1  // x + mitad del ancho - 1
	
	// Dibujamos: 
	mov x2, x20   	 // y
 rect_loop1:
	mov x1, x19  	 // x
	adds x2, x2, #1  // y + 1
 rect_loop2:	
	adds x1,x1, #1 	 // x + 1
	bl p_pixel       // args: ( x0 = direccion base del framebufer, x1 = x,  x2 = y, x3 = color )
	cmp x1 , x26     //
	b.lt rect_loop2  // if (x < ancho) -> rect_loop2
	cmp x2 , x27     // 
	b.lt rect_loop1  // if (y < alto) -> rect_loop1
	
	//-------------------- END CODE -------------------------//

	mov x1, x21 // x (cordenada)
	mov x2, x22 // y (cordenada)

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x26 , [sp, #32]
	ldur x27 , [sp, #40]
	ldur lr , [sp, #48]
	add sp, sp , 56

endRectangulo:	br lr

circulo: // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color,  x4 = radio)
	/* Inicializacion */
	sub sp, sp , 72
	stur x21 , [sp, #0]
	stur x22 , [sp, #8]
	stur x23 , [sp, #16]
	stur x24 , [sp, #24]
	stur x25, [sp, #32]
	stur x26 , [sp, #40]
	stur x27 , [sp, #48]
	stur x20 , [sp, #56]
	stur lr , [sp, #64]
	
	//-------------------- CODE ---------------------------//
	mov x25, x1		// posicion del framebufer x
	mov x27, x2		// posicion del framebufer y
	mov x21, x4  	// x  distancia incial del eje x al punto 
	mov x22, x4  	// y  distancia inicial del eje y al punto
	mov x23, x4  	// radio
	mul x23, x23, x23   // radio*radio
	mov x20, x3

 ciclo1: 
    sub x21, x21, 1
	add x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
	add x3, x3, 1
    cmp x24, x23 
	b.gt ciclo1
    bl p_pixel
	cbnz x21, ciclo1  
 	mov x21, x4
	mov x1, x25
	add x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo1 
   	 
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	mov x2, x27			// y = y
	mov x21, x4
	mov x22, x4
	mov x3, x20

 ciclo2: 
    sub x21, x21, 1
	sub x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
	add x3, x3, 1
    cmp x24, x23 
	b.gt ciclo2
    bl p_pixel
	cbnz x21, ciclo2
 	mov x21, x4
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	add x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo2 

    
	mov x1, x25
	add x2, x2, x4
	sub x2, x2, 1	// y = y + radio -1
	mov x21, x4
	mov x22, x4
	mov x3, x20

 ciclo3: 
    sub x21, x21, 1
	add x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
	add x3, x3, 1
    cmp x24, x23 
	b.gt ciclo3
    bl p_pixel
	cbnz x21, ciclo3
 	mov x21, x4
	mov x1, x25			// = x
	sub x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo3 



    lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	add x2, x2, x4
	mov x21, x4
	mov x22, x4
	mov x3, x20

 ciclo4: 
    sub x21, x21, 1
	sub x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
	add x3, x3, 1
    cmp x24, x23 
	b.gt ciclo4
    bl p_pixel
	cbnz x21, ciclo4
 	mov x21, x4
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	sub x2, x2, 1
	sub x22, x22, 1
	cbnz x22, ciclo4

	//-------------------- END CODE -------------------------//
	mov x1, x25 	
	mov x2, x27 		
	mov x4, x23   
	mov x3, x20	

	ldur x21 , [sp, #0]
	ldur x22 , [sp, #8]
	ldur x23 , [sp, #16]
	ldur x24 , [sp, #24]
	ldur x25, [sp, #32]
	ldur x26 , [sp, #40]
	ldur x27 , [sp, #48]
	ldur x20 , [sp, #56]
	ldur lr , [sp, #64]
	add sp, sp , 72

endCirculo: br lr

medioCirculo: // pre: {}    args: (in x0 = direccion base framebufer, x1 = x, x2 = y,  x3 = color,  x4 = radio, x5 = grosor)
	/* Inicializacion */
	sub sp, sp , 72
	stur x20, [sp, #0]
	stur x21 , [sp, #8]
	stur x22 , [sp, #16]
	stur x23 , [sp, #24]
	stur x24 , [sp, #32]
	stur x25, [sp, #40]
	stur x26 , [sp, #48]
	stur x27 , [sp, #56]
	stur lr , [sp, #64]
	
	//-------------------- CODE ---------------------------//
	mov x25, x1		// posicion del framebufer x
	mov x27, x2		// posicion del framebufer y
	mov x21, x4  	// x  distancia incial del eje x al punto 
	mov x22, x4  	// y  distancia inicial del eje y al punto
	mov x23, x4  		// radio
	sub x20, x4, x5
	mul x20, x20, x20
	mul x23, x23, x23   // radio*radio

 mediociclo1: 
    sub x21, x21, 1
	add x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
    cmp x24, x23 
	b.gt mediociclo1
	cmp x24, x20
	b.lt 8
    bl p_pixel
	cbnz x21, mediociclo1  
 	mov x21, x4
	mov x1, x25
	add x2, x2, 1
	sub x22, x22, 1
	cbnz x22, mediociclo1 
   	 
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	mov x2, x27			// y = y
	mov x21, x4
	mov x22, x4

 mediociclo2: 
    sub x21, x21, 1
	sub x1, x1, 1
    mul x24, x21, x21
	mul x26, x22, x22
	add x24, x24, x26 
    cmp x24, x23 
	b.gt mediociclo2
	cmp x24, x20
	b.lt 8
    bl p_pixel
	cbnz x21, mediociclo2
 	mov x21, x4
	lsl x9, x4, 1
	add x1, x25, x9		// x = x + 2 * radio
	add x2, x2, 1
	sub x22, x22, 1
	cbnz x22, mediociclo2 

	//-------------------- END CODE -------------------------//
	mov x1, x25 	
	mov x2, x27 		
	mov x4, x23   	

	
	ldur x20 , [sp, #0]
	ldur x21 , [sp, #8]
	ldur x22 , [sp, #16]
	ldur x23 , [sp, #24]
	ldur x24 , [sp, #32]
	ldur x25 , [sp, #40]
	ldur x26 , [sp, #48]
	ldur x27 , [sp, #56]
	ldur lr , [sp, #64]
	add  sp, sp , 72
endMedioCirculo: br lr

// Formas combinadas:

estrella: // pre: {}    args: (in x0 = direccion base del framebuffer, x1 = x, x2 = y, x3 = color, x4 = ancho)

	sub sp, sp , 24
	stur x19 , [sp, #0]
	stur x20 , [sp, #8] // No hace falta guardar en el stack x3 y  x4  porque solo usamos las funciones de triangulos y no las modifican
	stur lr , [sp, #16]

	mov x19, x1
	mov x20, x2
    //-------------------- CODE ---------------------------//
	lsr x9, x4, 2
	sub x9, x20, x9 
	//Triangulo superior 
	           // x0 = arg: direccion base framebufer
	           // x1 = arg: x
	mov x2, x9 // arg: y
	           // x3 = arg: color
	           // x4 = arg: ancho
	bl triangulo_punta_arriba

	// Triangulo inferrior
	lsr x9, x4, 2
	add x9, x20, x9 

				// x0 = arg: direccion base framebufer
				// x1 = arg: x
	mov x2,  x9 // arg: y
	            // x3 = arg: color
	 		    // x4 = arg: ancho
	bl triangulo_punta_abajo
 //-------------------- END CODE ---------------------------//
	mov  x1, x19
	mov  x2, x20

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur lr , [sp, #16]
	add sp, sp , 24

endEstrella: br lr

nave: 		//  pre: {}  args: (in x0 = direccion base del framebuffer, x1 = x, x2 = y, x3 = Numero de color del fuego)
	sub sp, sp , 80
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur x22 , [sp, #24]
	stur x23 , [sp, #32]
	stur x24 , [sp, #40]
	stur x25 , [sp, #48]
	stur x26 , [sp, #56]
	stur x27 , [sp, #64]
	stur lr , [sp, #72]

	mov x19, x1
	mov x20, x2
	mov x25, x3
	mov x26, x4
	mov x27, x5

 //-------------------- CODE ---------------------------//

	movz x21, 0xDA, lsl 16		//BLANCO
	movk x21, 0xDADA, lsl 00	//BLANCO (#F5F5F5)

	movz x22, 0x1E, lsl 16		//AZUL
	movk x22, 0x86F5, lsl 00	//AZUL (#1E86F5)

	movz x23, 0xF1, lsl 16		//AMARILLO
	movk x23, 0xCE2D, lsl 00	//AMARILLO (#F1CE2D)



		
	cmp x25, VELOCIDAD_NORMAL
	b.eq normal
		movz x24, 0x05, lsl 16		//AZUL
		movk x24, 0xffee, lsl 00	//AZUL (#F73822)
	b 12
    normal: 
			movz x24, 0xF7, lsl 16		//ROJO
			movk x24, 0x3822, lsl 00	//ROJO (#F73822)


	//Rectangulo central blanco
						// arg: x0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 24		    // arg: ancho
	mov x5, 56			// arg: alto
	bl rectangulo 

	//Rectangulo superior azul
	sub x9, x20, 30		// calculo: y - 30
	
					    // arg: x0 = direccion base del framebuffer
	mov x1,	x19		    // arg: x
	mov x2,	x9			// arg: y
	mov x3, x22  		// arg: color
	mov x4, 24			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo 

	//Triangulo Blanco superior
	sub x9, x20, 40  	// calculo: y - 36 - 12

						// arg: x0 = direccion base del framebuffer
						// arg: x1 = x
	mov x2,	x9			// arg: y    
	mov x3, x21         // arg: color
	mov x4, 24			// arg: ancho
	bl triangulo_punta_arriba 
 
	//Rectangulo central alargado
	movz x9, 0xab, lsl 16		// GRIS
	movk x9, 0xa3a2, lsl 00		// GRIS

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
	mov x3, x9			// arg: color
	mov x4, 60			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo  
	
	movz x9, 0xab, lsl 16		// GRIS
	movk x9, 0xa3a2, lsl 00		// GRIS

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21			// arg: color
	mov x4, 24			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo  

	//Rectangulo derecho
	add x9, x19, 30		// calculo: x + 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 		    // arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 
   

	//Rectangulo izquierdo
	sub x9, x19, 30		// calculo: x - 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 

 	//Rectangulo derecho mas chico
	add x9, x19, 18		// calculo: x + 18
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
	mov x3, x21 		// arg: color
	mov x4, 4			// arg: ancho
	mov x5, 18		    // arg: alto
	bl rectangulo 
    
	//Rectangulo izquierdo mas chico
	sub x9, x19, 18		// calculo: x - 18

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
	bl rectangulo 

	//Rectangulo derecho mas chico rojo
	add x9, x19, 30		 // calculo: x + 30
	sub x10, x20, 10     // calculo y - 5

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
	movz x3, 0xF7, lsl 16		//ROJO
	movk x3, 0x3822, lsl 00	//ROJO (#F73822)
	mov x4, 6			// arg: ancho
	mov x5, 4		    // arg: alto
	bl rectangulo


	//Rectangulo izquierdo mas chico rojo
	sub x9, x19, 30		// calculo: x - 30
	sub x10, x20, 10     // calculo y - 5

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo


	//Rectangulo derecho mas chico amarillo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 15     // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
	mov x3, x23 		// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 5			// arg: alto
	bl rectangulo
    

	//Rectangulo izquierdo mas chico amarillo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 15    // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo
 
	//Rectangulo derecho mas chico naranja/rojo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
	mov x3, x24 			// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 6			// arg: alto
	
	bl rectangulo
    
	//Rectangulo izquierdo mas chico naranja/rojo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo


	//Rectangulo abajo amarillo
	add x10, x20, 31    // calculo y + 31

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
    mov x3, x23 		// arg: color
	mov x4, 22			// arg: ancho
	mov x15, 6			// arg: alto
	bl rectangulo
	

    //Rectangulo derecho mas chico azul
	add x9, x19, 18		// calculo: x + 18
	sub x10, x20, 7     // calculo y - 7
	
						// arg: direccion base del framebuffer
	mov x1, x9 		    // arg: x
	mov x2, x10			// arg: y
	mov x3, x22 		// arg: color
	mov x4, 4			// arg: ancho
	mov x5, 4		    // arg: alto
	bl rectangulo
    

	//Rectangulo izquierdo mas chico azul
	sub x9, x19, 18		// calculo: x - 18
	sub x10, x20, 7     // calculo y - 7 
	
						// arg: direccion base del framebuffer
	mov x1, x9 		    // arg: x
	mov x2, x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo
 
    //Rectangulo abajo naranja/rojo             Esta es la parte del fuego
    add x10, x20, 38   // calculo y + 36

  						// arg: direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
	mov x3, x24 		// arg: color
	mov x4, 20			// arg: ancho
	mov x5, 8			// arg: alto
	add x6, x6, 1
	bl rectangulo
	mov x27, x1




    mov x1 , 13				// Setea el deley
	bl deley
 //	rectangulos centro, izquierda y derecha de NEGROS 

	movz x3, 0x0E, lsl 16			 //NEGRO
	movk x3, 0x0E0E, lsl 00			 //NEGRO (#0E0E0E)
	add x11, x19, 30		// calculo: x + 30
	add x10, x20, 20     // calculo y + 20
						// arg: X0 = direccion base del framebuffer
	mov x1,	x11 			// arg: x
	mov x2,	x10			// arg: y
						// arg: color
	mov x4, 6			// arg: ancho
	mov x5, 6			// arg: alto
	
	bl rectangulo
    
	//Rectangulo izquierdo mas chico naranja/rojo
	sub x11, x19, 30		// calculo: x - 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x11 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo

	mov x1, x27
	add x10, x20, 42
	mov x2,	x10 
	mov x4, 20							// arg: ancho
	mov x5, 8
	bl rectangulo                	 // un pedazo de rectangulo negro del rectangulo rojo dibujado anteriormente 
 


 //-------------------- END CODE ---------------------------//

	mov  x1, x19
	mov  x2, x20
	mov  x3, x25 
	mov  x4, x26 
	mov  x5, x27 

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur x22 , [sp, #24]
	ldur x23 , [sp, #32]
	ldur x24 , [sp, #40]
	ldur x25 , [sp, #48]
	ldur x26 , [sp, #56]
	ldur x27 , [sp, #64]
	ldur lr , [sp, #72]
	add sp, sp , 80

endNave: br lr

borrar_nave: 		// pre: {}  args: (in x0 = direccion base del framebuffer, x1 = x, x2 = y)         
	sub sp, sp , 48
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x25 , [sp, #16]
	stur x26 , [sp, #24]
	stur x27 , [sp, #32]
	stur lr ,  [sp, #40]

	mov x19, x1
	mov x20, x2
	mov x25, x3
	mov x26, x4
	mov x27, x5

 //-------------------- CODE ---------------------------//

	movz x3, 0x0E, lsl 16		//NEGRO
	movk x3, 0x0E0E, lsl 00		//NEGRO (#0E0E0E)


	//Rectangulo central blanco
						// arg: x0 = direccion base del framebuffer
	mov x1,	x19   		// arg: x
	sub x2,	x20	, 3		// arg: y
	             		// arg: x3 = color
	mov x4, 24		    // arg: ancho
	mov x5, 64			// arg: alto
	bl rectangulo   

	//Triangulo Blanco superior
	sub x9, x20, 40  	// calculo: y - 36 - 12

						// arg: x0 = direccion base del framebuffer
	mov x1,	x19					// arg: x1 = x
	mov x2,	x9			// arg: y    
				        // arg: x3 = x3 = color
	mov x4, 24			// arg: ancho
			 			// arg: x5 = alto
	bl triangulo_punta_arriba 
 
	//Rectangulo central alargado
						// arg: X0 = direccion base del framebuffer
	sub x1,	x19, 20 	// arg: x
	mov x2,	x20			// arg: y
						// arg: x3 = color
	mov x4, 16			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo 

	//Rectangulo central alargado
						// arg: X0 = direccion base del framebuffer
	add x1,	x19, 20 	// arg: x
	mov x2,	x20			// arg: y
						// arg: x3 = color
	mov x4, 16			// arg: ancho
	mov x5, 6			// arg: alto
	bl rectangulo   

	//Rectangulo derecho
	add x9, x19, 30		// calculo: x + 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 		    // arg: x
	mov x2,	x20			// arg: y
						// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 
   

	//Rectangulo izquierdo
	sub x9, x19, 30		// calculo: x - 30
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
			 			// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 30			// arg: alto
	bl rectangulo 

 	//Rectangulo derecho mas chico
	add x9, x19, 18		// calculo: x + 18
	
						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
			 			// arg: x3 = color
	mov x4, 4			// arg: ancho
	mov x5, 18		    // arg: alto
	bl rectangulo 
    
	//Rectangulo izquierdo mas chico
	sub x9, x19, 18		// calculo: x - 18

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x20			// arg: y
			 			// arg: x3 = color
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo 


	//Rectangulo derecho mas chico amarillo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 15     // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 5			// arg: alto
	bl rectangulo
    

	//Rectangulo izquierdo mas chico amarillo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 15    // calculo y + 15

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo

	//Rectangulo derecho mas chico naranja/rojo
	add x9, x19, 30		// calculo: x + 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 6			// arg: ancho
	mov x5, 6			// arg: alto
	
	bl rectangulo
    
	//Rectangulo izquierdo mas chico naranja/rojo
	sub x9, x19, 30		// calculo: x - 30
	add x10, x20, 20     // calculo y + 20

						// arg: X0 = direccion base del framebuffer
	mov x1,	x9 			// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
			 			// arg: x4 = ancho
			 			// arg: x5 = alto
	bl rectangulo

	//Rectangulo abajo amarillo
	add x10, x20, 31    // calculo y + 31

						// arg: X0 = direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 22			// arg: ancho
	mov x15, 6			// arg: alto
	bl rectangulo
	

	//Rectangulo abajo naranja/rojo
	add x10, x20, 40    // calculo y + 36

						// arg: direccion base del framebuffer
	mov x1,	x19 		// arg: x
	mov x2,	x10			// arg: y
			 			// arg: x3 = color
	mov x4, 20			// arg: ancho
	mov x5, 20			// arg: alto
	bl rectangulo

 //-------------------- END CODE ---------------------------//

	mov  x1, x19
	mov  x2, x20
	mov  x3, x25 
	mov  x4, x26 
	mov  x5, x27 

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x25 , [sp, #16]
	ldur x26 , [sp, #24]
	ldur x27 , [sp, #32]
	ldur lr , [sp, #40]
	add sp, sp , 48

endborrar_Nave: br lr

fondoPlanetas: // pre: {} args: (in x0 = direccion base del framebuffer, x7 = Desplazamiento vertical)
	sub sp, sp , 32
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur lr , [sp, #24]

	mov x19, x1 
	mov x20, x2
	mov x21, x7
	mov x22, x3 
	lsl x21, x21, 1
	//-------------------- CODE ---------------------------//
			    // arg: x0 = direc base del frame buffer
	mov x1, 50	// arg: x
	mov x2, 17	// arg: y
				// arg: x3 = color
	mov x4, 16	// arg: ancho

	mov x1, 100
	mov x2, 290
	add x2, x2, x21	
	movz x3, 0xe0, lsl 16		//AMARILLO
	movk x3, 0xbba2, lsl 00
	mov x4, 40
	bl circulo

	mov x1, 530
	mov x2, 380
	add x2, x2, x21	
	movz x3, 0xcc, lsl 16		//CELESTE
	movk x3, 0x1414, lsl 00
	mov x4, 20
	bl circulo

	mov x1, 325
	mov x2, 115
	add x2, x2, x21
	movz x3, 0x12, lsl 16		
	movk x3, 0x3f3f, lsl 00		//AZUL
	mov x4, 30
	bl circulo

	//-------------------- END CODE ---------------------------//

	mov x1, x19 
	mov x2, x20
	mov x3, x22
	mov x7, x21

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur lr , [sp, #24]
		
	add sp, sp , 32
endFondoPlanetas: br lr

borrarPlanetas: // pre: {} args: (in x0 = direccion base del framebuffer, x6 = tipo ,x7 = Desplazamiento vertical)
	sub sp, sp , 32
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur lr , [sp, #24]

	mov x19, x1 
	mov x20, x2
	mov x21, x7
	mov x22, x3 
	lsl x21, x21, 1
	//-------------------- CODE ---------------------------//
			    // arg: x0 = direc base del frame buffer
	mov x1, 50	// arg: x
	mov x2, 17	// arg: y
	movz x3, 0x0E, lsl 16		//NEGRO
	movk x3, 0x0E0E, lsl 00		//NEGRO (#0E0E0E)
	mov x4, 16	// arg: ancho


	mov x1, 100
	mov x2, 290
	add x2, x2, x21	
	mov x4, 40
	mov x5, 2
	cmp x6, VELOCIDAD_NORMAL
	b.eq 8
	add x5,x5, 4
	bl medioCirculo

	mov x1, 530
	mov x2, 380
	add x2, x2, x21	
	mov x4, 20
	mov x5, 2
	cmp x6, VELOCIDAD_NORMAL
	b.eq 8
	add x5,x5, 4
	bl medioCirculo

	mov x1, 325
	mov x2, 115
	add x2, x2, x21
	mov x4, 30
	mov x5, 2
	cmp x6, VELOCIDAD_NORMAL
	b.eq 8
	add x5,x5, 4
	bl medioCirculo
	
	//-------------------- END CODE ---------------------------//

	mov x1, x19 
	mov x2, x20
	mov x3, x22
	mov x7, x21

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur lr , [sp, #24]
		
	add sp, sp , 32
endBorrarPlanetas: br lr

fondoEstrellado: // pre: {} args: (in x0 = direccion base del framebuffer, x1 = semilla X, x2 = semilla Y, x3 = color, x4 = numero de estrellas, x5 = Desplazamiento vertical)
	sub sp, sp , 56
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	// x21 borrado
	stur x22 , [sp, #16]
	stur x23 , [sp, #24]
	stur x24 , [sp, #32]
	stur x25 , [sp, #40]
	stur lr ,  [sp, #48]
	
	// x0 no lo modificamos asi que no hace falta guardarlo
	mov x19, x1 // semilla X
	mov x20, x2 // semilla Y
	// x3 (color) no lo modificamos asi que no lo guardamos
	mov x22, x4 // n de estrellas  
	mov x23, x5 // desplazamiento del eje Y

 //-------------------- CODE ---------------------------//
	mov x24, x22 		// x24 sera donde guardaremos el contador de estrellas que quedan por dibujar

 // Estrellas //
 RecEstrellas:

	// calculamos el desplazamiento vertical del eje Y
	mov x25, x2 // rescatamos posicion Y original antes de modificarlo
	add x2, x2, x23
 
	// dibujamos la estrella
		        	// arg: x0 = direc base del frame buffer
    				// arg: x1 = x
					// arg: x2 = y
					// arg: x3 = color
	mov x4, 8		// arg: ancho
	bl estrella 
	
    mov x2, x25 // recuperamos el valor de y original por si y_mas_abajo lo modifico

	// Calculamos x e y de la proxima estrella
	mov x9, 4 //contador
	lk:
	    sub x1, x1, x24
		add x2, x2, x1
		lsl x1, x1, x9
		add x1, x1, 71
		add x2, x24, x2
		add x1, x2, x1

		sub x9, x9, 1
		cbnz x9, lk
	
	bl moduloHEIGH
	bl moduloWIDTH

	sub x24, x24, 1 // numero de estrellas - 1

	// Dibujamos la proxima estrella

	        	// "arg": x0 = direc base del frame buffer
				// "arg": x1 = semilla x
				// "arg": x2 = semilla y
				// "arg": x3 = color
				// "arg": x24 = numero de estrellas
				// "arg": x5 = Desplazamiento vertical
	cbnz x24, RecEstrellas 

 //-------------------- END CODE ---------------------------//
	mov x1, x19 
	mov x2, x20 
	mov x4, x22 
	mov x5, x23

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x22 , [sp, #16]
	ldur x23 , [sp, #24]
	ldur x24 , [sp, #32]
	ldur x25 , [sp, #40]
	ldur lr ,  [sp, #48]
	add sp, sp , 56
endFondoEstrellado: br lr

fondoDinamico: // pre: {} args: (in x0 = direccion base del framebuffer, x3 = color, x7 = Desplazamiento vertical)
	sub sp, sp , 32
	stur x19 , [sp, #0]
	stur x20 , [sp, #8]
	stur x21 , [sp, #16]
	stur lr , [sp, #24]

	mov x19, x1 
	mov x20, x2
	// x3 no se modifica
	mov x21, x7
	//-------------------- CODE -------------------------------//
	
	mov x9, SEMILLA
	add x9, x9, 367
		            	// arg: x0 = direct base del frame buffer
	add x1, x9, 13		// arg: semilla x
	add x2, x9, 34		// arg: semilla y
						// arg: x3 = color
	mov x4, 30	    	// arg: numero de estrellas 
	mov x5, x21			// arg: Desplazamiento vertical
	bl fondoEstrellado  

						// arg: x0 = direct base del frame buffer
						// arg: x7 = Desplazamiento vertical
	bl fondoPlanetas	//Pintamos los planetas
	//-------------------- END CODE ---------------------------//
	mov x1, x19 
	mov x2, x20
	mov x7, x21

	ldur x19 , [sp, #0]
	ldur x20 , [sp, #8]
	ldur x21 , [sp, #16]
	ldur lr , [sp, #24]
		
	add sp, sp , 32
endFondoDinamico: br lr

Error: // Nunca se deberia ejecutar esto
		b Error
		