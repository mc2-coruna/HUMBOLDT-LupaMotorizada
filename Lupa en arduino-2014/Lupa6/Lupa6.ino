// Esta es una variante en la que el cambio de muestra se hace con un motor DC
// 19 febrero de 2014
// Actualizado el 4 de septiembre de 2014


// Variables de configuracion
  boolean imprimeInfo = false;
  int tiempoEnvio =  500;     // Tiempo entre envios de informacion a processing
  int tiempoImpre = 2000;     // Tiempo entre impresion de informacion por terminal




// Variables del montaje de la lupa robot
  int numMuestras = 8;       // numero de muestras en el plato
  int umbralBarrera = 200;   // umbral de referencia para las barreras opticas

// El accionamiento de los motores de enfoque y cambio de muestra se hace por medio  
// de una Motor Shield ( http://arduino.cc/en/Main/ArduinoMotorShieldR3 ).
// Se han eliminado las entradas de control del consumo de los motores. 
// Se han dejado habilitadas las entradas de frenado.
// CHAN A: pines del motor de continua del cambio de muestras. CHAN A del MotorShield
  int muestraDir = 12;       // Direccion de giro del cambio de muestra
  int muestraPWM =  3;       // Control de velocidad del giro de cambio de muestra
  int muestraBrk =  9;       // Freno del cambio de muestra

// CHAN B: pines del motor de continua del enfoque. CHAN B del MotorShield
  int enfoqueDir = 13;       // Direccion de enfoque
  int enfoquePWM = 11;       // Control de velocidad de enfoque

// Botonera de mando
  int intMuestraMas =   24;  //Puls avance de muestra  LUZ int Muestra Mas   = 22
  int intMuestraMenos = 28;  //Puls retroc de muestra  LUZ int Muestra Menos = 26
  int intEnfoqueMas =   30;  //Puls enfoque arriba     LUZ int Enfoque Mas   = 36
  int intEnfoqueMenos = 32;  //Puls enfoque abajo      LUZ int Enfoque Menos = 34

// Barreras opticas del movimiento de muestras
  int barreraEnfoqueLim =    1; // Barrera dentro de limite del recorrido de enfoque
  int barreraEnfoqueAlto = 2; // Barrera enfoque en zona alta del recorrido
  int barreraMuestra1 =      3; // Barrera que detecta la muestra 0 (cercana al eje)
  int barreraMuestraCentro = 4; // Barrera de posicion de muestra (lehos del centro)

// Otras patillas
    // Luz LED para muestras D11 (OJO INCOMPATIBLE CON MOTOR SHIELD)
    // El LED queda conectado directamente.

// Variables asociadas a los Pulsadores ya las barreras opticas
  boolean muestraMas =   false; // Variable del pulsador de avance de muesta.
  boolean muestraMenos = false; // Variable del pulsador retroceso de muestra 
  boolean enfoqueMas =   false; // Variable del pulsador de enfoque arriba.
  boolean enfoqueMenos = false; // Variable del pulsador de enfoque abajo.

  boolean bMuestra =     false; // TRUE si la muestra esta situada en su sitio
  boolean bMuestra1 =    false; // TRUE al paso por el indicador de Muestra 1
  boolean bEnfAlto =     false; // TRUE si el carro de enfoque esta bajo
  boolean bEnfDentro =   false; // TRUE si el carro de enfoque esta dentro del limites

// Inicializacion de variables
  boolean reset = true;     // Si true busca el centro del enfoque y a la muestra 1
  int muestra = 4;          // Es el numero de muestra que estamos viendo.
  int muestraOrigen =0;     // Indica si paso por el indicador me muestra 0
  int tiempoMarcha = 0;     // Tiempo empleado en el ultimo cambio de muestra
  unsigned long tiempoUltimoEnvio = 0;  // Momento del ultimo envio a Processing
  unsigned long tiempoUltimaImpre = 0;  // Momento de la ultima impresion de estado



void setup() {
  //Configuracion de los pines de entradas digitales.
  pinMode (intMuestraMas,   INPUT);
  pinMode (intMuestraMenos, INPUT);
  pinMode (intEnfoqueMas,   INPUT);
  pinMode (intEnfoqueMenos, INPUT);

  // Configuracion de los pines de salidas digitales del motor de avance de muestras.
  pinMode (muestraDir,    OUTPUT);
  pinMode (muestraPWM,    OUTPUT);
  pinMode (muestraBrk,    OUTPUT);

  // Configuracion de los pines de salidas digitales del motor de enfoque.
  pinMode (enfoqueDir,    OUTPUT);
  pinMode (enfoquePWM,    OUTPUT);

  Serial.begin(9600);
}



void loop() {
  // Si activo recorre las muestras hasta encontrar la marca de origen
  if (reset == true) inicio();

  leeEntorno();                  // Lee las variables del mundo fisico.
  mensaje (muestra, 0, false);   // Envia informacion periodica a Processing
  imprimeInformacion();          // imprime enformacion.

  // Lee los pulsadores de cambio de muestra
  if      (muestraMas   == HIGH) cambiaMuestra ( +1);   // Avance de muestra
  else if (muestraMenos == HIGH) cambiaMuestra ( -1);   // Retroceso de muestra
 
// Lee los pulsadores de control de enfoque
  if      (enfoqueMas   == HIGH) enfocando ( +1);       // Enfoque arriba
  else if (enfoqueMenos == HIGH) enfocando ( -1);       // Enfoque abajo
}


// ------------------- Busqueda de muestra inicial ------------------------------------------------
void inicio ()
{
  leeEntorno();
  
  if (bMuestra1 == true)                   // Si esta en la muestra 0 no hace nada
  {
    muestra = 0;
  }
  else
  {
    muestra = 1;
    // Hace un primer movimiento de muestra para asegurar que al iniciar la busqueda el plato 
    // esta parado en una muestra
    cambiaMuestra ( +1);
    delay (1000);
    
    // Avanza el portamuestras hasta encontrar la marca de muestra 0. Antes marca la 
    // muestra como numero 1 para evitar problemas con el contador 
      // Seria importante añadir un timeout.
    while (muestra != 0)
    {
      muestra = 1; 
      cambiaMuestra ( +1);
      delay (1000);
    }
  }
  
  enfoqueNeutro ();
  reset = false;
}



// ------------------- CAMBIO DE MUESTRAS CON MOTOR DC ------------------------------------------------
void cambiaMuestra (int direccion)
{
  //************************************************************
  //***    QUEDA SIN PROGRAMAR EL RETROCESO DE MUESTRAS      ***
  //************************************************************

  if (direccion >0)
  {
    // Envia un mensaje para Processing al iniciar el movimiento de la muestra. 
    // El valor es 100.
    mensaje (100, -2, true);
    int tiempoInicio = millis();
    bMuestra  = false;             // Sobreescribe el valor de las barreras para iniciar el movimiento

    while (bMuestra == false)      // Avanza hasta la proxima muesca de muestra
    {
      // Variables de un movimiento hacia adelante.
      digitalWrite (muestraDir, HIGH);  
      analogWrite  (muestraPWM,  100);
      digitalWrite (muestraBrk, LOW);

      leeEntorno();
      // Durante 200 mS ignora el valor de las barreras para dejar salir los marcadores 
      if ((millis() - tiempoInicio) < 200)
      {
        bMuestra  = false;  bMuestra1 = false;
      }
      
      // Detecta el paso por la muesca de origen
      if (bMuestra1 == true)
      {
        muestraOrigen = 1; 
        Serial.println ("Detectada muestra origen ");
      }
    }
    
    tiempoMarcha = millis() - tiempoInicio;

    // Variables para frenar el motor de avance de muestra
    analogWrite  (muestraPWM,  255);
    digitalWrite (muestraBrk, HIGH);
    delay (200);

    digitalWrite (muestraDir, HIGH);  
    analogWrite  (muestraPWM,  100);
    digitalWrite (muestraBrk, LOW);
    delay (40);
    analogWrite  (muestraPWM,  255);
    digitalWrite (muestraBrk, HIGH);
    
    delay (1000);
    
    muestra ++;
    muestra = muestra % numMuestras; 
    // if (muestra < 0) muestra += numMuestras; para usar en el caso de conteo hacia abajo

    // Si paso por la muesca de origen
    if (muestraOrigen > 0)
    {
      muestra = 0; muestraOrigen = 0;
    }
    
    // Envia un mensaje forzado a processing con el nuevo numero de muestra.
    mensaje (muestra, tiempoMarcha, true);

    if (! reset) 
    {
      enfoqueNeutro ();  // Lleva el carro de enfoque a su posicion central
      imprimeInformacion();
      delay (1000);
    }
    
    // Variables para liberar el freno del motor de avance de muestra
    analogWrite  (muestraPWM,    0);
    digitalWrite (muestraBrk,  LOW);

  }
}    




// ------------------- MOVIMIENTO DE ENFOQUE CON MOTOR DC ------------------------------------------------
void enfocando (int direccion)
{
  int velEnfoque = 200;
  leeEntorno();
  
  // Si la orden es para subir, el carro se muevo si esta dentro de los 
  // llmites o si esta por debajo del centro
  if (direccion > 0)
  {
    if ((bEnfDentro == true) || (bEnfAlto == false))
    {
      digitalWrite (enfoqueDir, HIGH);
      analogWrite  (enfoquePWM,  velEnfoque);
      delay (10);
      digitalWrite (enfoqueDir,  LOW);
      analogWrite  (enfoquePWM,    0);
    }
  }
  
  // Si la orden es para bajar, el carro se muevo si esta dentro de los 
  // llmites o si esta por encima del centro
  else if (direccion < 0)
  {
    if ((bEnfDentro == true) || (bEnfAlto == true))
    {
      digitalWrite (enfoqueDir,  LOW);
      analogWrite  (enfoquePWM,  velEnfoque);
      delay (10);
      analogWrite  (enfoquePWM,    0);
    }
  }
}


// ------------------- Busca el enfoque neutro ------------------------------------------------
void enfoqueNeutro ()
{
  leeEntorno();
  imprimeInformacion ();
  
  // Si el carro de enfoque esta en la zona alta lo baja 
  // hasta que sale de esa zona
  if (bEnfAlto) 
   {
    while (bEnfAlto)
    {
      leeEntorno();
      enfocando ( - 1); 
    }
  }

  // Si el carro de enfoque esta en la zona baja lo sube 
  // hasta que sale de esa zona
  else if (! bEnfAlto)             
  {
    while (!bEnfAlto)
    {
      leeEntorno();
      enfocando ( + 1); 
    }
  }
}


// ------------------- Lee Barreras -----------------------------------------------------------
void leeEntorno()
{
        // BARRERAS OPTICAS
  bEnfAlto     = (analogRead(barreraEnfoqueAlto)   > umbralBarrera);
  bEnfDentro   = (analogRead(barreraEnfoqueLim)    > umbralBarrera);
  bMuestra     = (analogRead(barreraMuestraCentro) < umbralBarrera);
  bMuestra1    = (analogRead(barreraMuestra1)      < umbralBarrera);

        // PULSADORES
  muestraMas   = digitalRead(intMuestraMas);
  muestraMenos = digitalRead(intMuestraMenos);
  enfoqueMas   = digitalRead(intEnfoqueMas);
  enfoqueMenos = digitalRead(intEnfoqueMenos);
}



// ------------------- Envia un mensaje para Processing ------------------------------------------------
void mensaje (int dato1, int dato2, boolean forzado)
{
  
  // Envia mensajes a processing cada tiempoEnvio o cada vez que se solicita forzado
  if (((millis() - tiempoUltimoEnvio) > tiempoEnvio) || (forzado == true))
  {    
    Serial.print   (999);
    Serial.print   (",");
    Serial.print   (dato1);
    Serial.print   (",");
    Serial.print   (dato2);    
    Serial.println ();
    
    tiempoUltimoEnvio = millis();
  }
}

// ------------------- Imprime un bloque de informacion ------------------------------------------------
void imprimeInformacion()
{
  // Imprime las variables del sistema cada tiempoImpre
  if ( ((millis() - tiempoUltimaImpre) > tiempoImpre) && (imprimeInfo == true))
  {    
    Serial.print ("BarreraMuestra ");
    Serial.print (analogRead(barreraMuestraCentro));
    Serial.print (" -> ");
    Serial.print (bMuestra);  
    Serial.print ("\t Barrera inicio ");
    Serial.print (analogRead(barreraMuestra1));
    Serial.print (" -> ");
    Serial.print (bMuestra1);
    Serial.println ();

    Serial.print ("\t 3-Enf alto ");
    Serial.print (analogRead(barreraEnfoqueAlto));
    Serial.print (" -> ");
    Serial.print (bEnfAlto);
    Serial.print ("\t 2-Enf dentro ");
    Serial.print (analogRead(barreraEnfoqueLim));
    Serial.print (" -> ");
    Serial.print (bEnfDentro);
    Serial.println ();

    Serial.print ("MuestraNum: ");
    Serial.print (muestra);
    Serial.print ("\t Tiempode transicion: ");
    Serial.print (tiempoMarcha);
    Serial.print (" mS");
    Serial.println ();
     
    tiempoUltimaImpre = millis();
  }
}

