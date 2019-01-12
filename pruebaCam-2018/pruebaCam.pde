import processing.video.*;
import processing.serial.*;    // Import the processing serial library

Capture cam;
String nombreCamara = "";
boolean camCreada = false;
PImage img ;

Serial myPort;                 // The Serial Port
String portName = "";
String resultString;           // El texto recibido

int  muestraNum = 4, muestraNumAnt = 0, muestraNumAnt2 = 0;
float triX = 0.0, triY = 0.0;
float posX = 50.0;

String[] ficheroTexto  = {"", "", "", "", "", "", "", ""};
String[] parrafoTexto  = {"", "", "", "", "", "", "", ""};
String[] ficheroImagen = {"", "", "", "", "", "", "", ""};
String[] nombreComun   = {"", "", "", "", "", "", "", ""};
String[] nombreCientif = {"", "", "", "", "", "", "", ""};
String[] textoExtra    = {"", "", "", "", "", "", "", ""};

PFont myfont1, myfont2;

int anchoPantalla, altoPantalla;
float[] xpos0Titulo, xpos1Titulo, xpos2Titulo;
int yposTitulo;
int xposCamara, yposCamara, anchoCamara, altoCamara;
int xposmm, yposmm, xanchomm, tamanomm;
int xposTexto, yposTexto, anchoTexto , altoTexto;
int tamanoTexto, tamanoTitulo;
int pasos;
int segundos, segundosAnt;
String logPath, logFile;
PrintWriter ficheroLog;



Runtime instance = Runtime.getRuntime();
long minMemLibre = 1000000000;
long llamadasGC = 0;





void setup() {
  logPath = sketchPath ("") + "logs/";
  logFile = year()%100 + nf(month(),2) + nf(day(),2) + "_" + nf(hour(),2) + nf(minute(),2);
  ficheroLog = createWriter(logPath + logFile + ".txt");   
  
  String imagen = "Imagen.png";
  img = loadImage(imagen);
    anotacionLog(ficheroLog, "Cargada imagen" + imagen);
 
  int intFrameRate = 30;
  frameRate (intFrameRate);
    anotacionLog(ficheroLog, "Establecido frameRate = " + intFrameRate);

  anchoPantalla = displayWidth;
  altoPantalla  = displayHeight;

  xpos0Titulo = new float [8];
  xpos1Titulo = new float [8];
  xpos2Titulo = new float [8];

  size(anchoPantalla, altoPantalla, P2D);
    anotacionLog(ficheroLog, "Tamaño pantalla = " + anchoPantalla + " x " + altoPantalla);
  background (20,120,100);
  
                                                    // Calcula el tamaño y posicion de la imagen de la camara
  xposCamara  = int (height * 0.01 + 0.5);
  yposCamara  = xposCamara;
  anchoCamara = int (height * 0.27) * 4;
  altoCamara  = int (anchoCamara * 3 / 4);
  
  xanchomm    = int (anchoCamara / 7);
  tamanomm    = int (width / 50);
  xposmm      = int (xposCamara + anchoCamara - 1.25 * xanchomm);
  yposmm      = int (yposCamara + altoCamara - 0.05 * altoCamara);
  
                                                   // Calcula el tamaño y posicion de la ventana de texto  
                                                   // xposTexto  = xposCamara * 4 + anchoCamara;
  xposTexto  = xposCamara + anchoCamara + 3 * xposCamara;
  yposTexto  = yposCamara;
  anchoTexto = width - xposTexto - 2 * xposCamara;
  altoTexto  = altoCamara;
  tamanoTexto = width / 50;

                                                   // Calcula la posicion del titulo.
  yposTitulo = int (height * 0.95);
  tamanoTitulo = width / 30;

  myfont1 = createFont ("AgaramondPro-Bold",tamanoTitulo);
  myfont2 = createFont ("AgaramondPro-BoldItalic",tamanoTitulo);

 String[] cameras = Capture.list();  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();     
  }       
    anotacionLog(ficheroLog, "Inicializada cámara " + cameras[0]);

  leerFicherosDatos ();  
    anotacionLog(ficheroLog, "Copiados los ficheros de datos");

  String puertoSerie = abrePuertoSerie ();
    if (puertoSerie == null)
    {
    anotacionLog(ficheroLog, "No hay puertos USB disponibles");
    }
    else {
    anotacionLog(ficheroLog, "Abierto el puerto " + puertoSerie + " a 9600 bps");
    }
  
  noCursor();
}

void draw() {

  background(204, 50, 0);
  segundos = millis() / 1000;

  if (cam.available() == true) {
    if ((muestraNum >= 0 ) && (muestraNum <= 7)) cam.read();
  }
  // g.removeCache(img);                                               // ***LIMPIEZA DE CAHE***
  image(cam, xposCamara, yposCamara, anchoCamara, altoCamara);
  
  stroke(204, 50, 0);
  strokeWeight (4);
  line (xposmm, yposmm, xposmm + xanchomm, yposmm);
  line (xposmm, yposmm - 10, xposmm, yposmm + 10);
  line (xposmm + xanchomm, yposmm - 10, xposmm + xanchomm, yposmm + 10);
  strokeWeight (1);
  
  fill(204, 50, 0);
  textFont(myfont1,tamanomm);
  textAlign(CENTER);
  text ("1 mm", xposmm + xanchomm / 2, yposmm - 0.2 * tamanomm);  

  
  fill(255);  
  textSize(tamanoTitulo);

  if (muestraNum >= 100) {
    textAlign(CENTER);
    text( "Avanzando muestra" , width / 2 , yposTitulo);
    posX += 5.0;    
    fill (#9ff999);
    float anchoTriangulos = anchoCamara - 80;
    if (posX > anchoTriangulos /4.0) posX = 0.0;
    triY = yposCamara + altoCamara * 3.0 / 4.0;
    for (int i = 0; i < 4; i++) {
      triX = 10 + posX + xposCamara + i * anchoTriangulos / 4.0;
      triangle (triX, triY-60, triX, triY+60, triX+60,triY);
    }
  } else if ((muestraNum >= 0) && (muestraNum <=7)) {
    posX = 0.0;
    textAlign(LEFT);
    textFont(myfont1,tamanoTitulo);
    text ((nombreComun[muestraNum] + " - "), xpos0Titulo[muestraNum], yposTitulo);
    textFont(myfont2,tamanoTitulo);
    text ((nombreCientif[muestraNum]), xpos1Titulo[muestraNum], yposTitulo);
    if (textoExtra[muestraNum] != null) {
      textFont(myfont2,tamanoTitulo);
      text ((" " + textoExtra[muestraNum]), xpos2Titulo[muestraNum], yposTitulo);
    }
  }
  if (muestraNum != muestraNumAnt)
  {
    if (muestraNum >= 100) anotacionLog(ficheroLog, "Avanzando muestra");
    else 
    {
      String textoAnota;
      textoAnota =  "Muestra " + muestraNumAnt2 + " -> " + muestraNum;
      if ((muestraNum == 0) && (muestraNumAnt2 != 7)) textoAnota += "**";
      textoAnota += "\t" + nombreComun[muestraNum] + "\t";
      //  textoAnota += "Frame Rate = " + int(frameRate + 0.5);
      anotacionLog(ficheroLog, textoAnota);
      segundosAnt = segundos;
      muestraNumAnt2 = muestraNum;
    }

    muestraNumAnt = muestraNum;
  }

  fill(255);  
  textSize(tamanoTexto);
   textAlign(LEFT,CENTER);
  if ((muestraNum >= 0) && (muestraNum <= 7)) {
    stroke (#0000ff);
    fill (#000000);
    //rect (xposTexto, yposTexto, anchoTexto , altoTexto);
    fill (#ffffff);
    text(parrafoTexto [muestraNum], xposTexto, yposTexto, anchoTexto , altoTexto); 
  }

  if ((segundos - segundosAnt) > 30)
  {
    anotacionLog (ficheroLog, "Seguimos en muestra " + muestraNum);
    segundosAnt = segundos;
  }

}


void serialEvent (Serial myPort)
{
  String inputString = myPort.readStringUntil ('\n');
  inputString = trim (inputString);
  println (inputString);
  resultString = "";
  int sensors[] = int ( split( inputString, ','));
  if (sensors[0] == 999)
  {
    muestraNum = sensors[1];
    pasos = 0;
    if (sensors.length >= 3) pasos = sensors[2];
    println ("Muestra número: " + muestraNum + "\t" + sensors[0] + "\t" + sensors[1]);
  }
  
    for (int sensorNum = 0; sensorNum < sensors.length; sensorNum++)
    {
      resultString += "Sensor " + sensorNum + ": ";
      resultString += sensors[sensorNum] + "\t";
    }
    println (resultString);
}



//  ============ FUNCION LEER FICHEROS DE DATOS ===============================================
void leerFicherosDatos ()
{ 
  
  
  
                                                             // Lee el fichero de datos externo
                                                            // formato textxxx, imgxxx, comun, cientifico, extra
                                                            //


  
                                                            // Carga las fuentes para el titulo y para el texto
                                                            //  
 
 
                                                            // Carga cada una de las imgxxx
                                                            //
    
  
  



                                                            // Funcion que lee el texto de un fichero, y traduce 
                                                            // Lee el fichero de datos que contiene la siguiente 
                                                            // informacion para cada muestra separada por tabuladores:
                                                            // Nombre del fichero de texto asociado
                                                            // Nombre del fichero de imagen asociado
                                                            // Nombre comun de la muestra
                                                            // Nombre científico de la muestra
                                                            // Texto adicional al nombre científico
                                                            // Todos los ficheros tienen que estar guardado con 
                                                            //         codificacion Occidental(Windows latino 1)
  Table table;
  table = loadTable("datos.tsv", "header, tsv");

  int contador = 0;
  println(table.getRowCount() + " total rows in table"); 
  for (TableRow row : table.rows()) {
    ficheroTexto [contador]  = row.getString("texto");  
    ficheroImagen [contador] = row.getString("imagen");
    nombreComun [contador]   = row.getString("comun");
    nombreCientif [contador] = row.getString("cientif");
    textoExtra [contador]    = row.getString("extra");
    
    println(contador + "\t" + ficheroTexto[contador] + "\t" + ficheroImagen[contador] + "\t" + nombreComun[contador] + "\t" + nombreCientif[contador] + "\t" + textoExtra[contador]);
    contador ++;
  }

                                                            // Carga el texto de cada fichero de texto
  for (int i = 0; i < 8; i++)
  {
    InputStream input = createInput(ficheroTexto [i]+".txt");
    String content = "";
    try {
      int data = input.read();
      while (data != -1) {
        content += char(data);
        data = input.read();
      }
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    finally {
      try {
        input.close();
      } 
      catch (IOException e) {
        e.printStackTrace();
      }
    }
    parrafoTexto [i] = content;
  }

                                                           // Calcula la longitud de cada titulo, y las posiciones 
                                                           // de inicio de cada una de las palabras

  for (int i = 0; i < 8; i++)
  {
    textFont(myfont1,tamanoTitulo);
    float longitud1Titulo = textWidth(nombreComun[i] + " - ");
    textFont(myfont2,tamanoTitulo);
    float longitud2Titulo = textWidth(nombreCientif[i]);
    float longitud3Titulo = 0;
    if (textoExtra[i] != null)
    {
      textFont(myfont1,tamanoTitulo);
      longitud3Titulo = textWidth(" " + textoExtra[i]);
    }
    float longitudTitulo = longitud1Titulo + longitud2Titulo + longitud3Titulo;
    xpos0Titulo[i] = (width - longitudTitulo) / 2;
    xpos1Titulo[i] = xpos0Titulo[i] + longitud1Titulo;
    xpos2Titulo[i] = xpos1Titulo[i] + longitud2Titulo;

    println (i + "\t" + longitud1Titulo +"\t" + longitud2Titulo + "\t" + longitud3Titulo + "\t" + longitudTitulo + "\t" + nombreComun [i]);
    println (i + "\t" + xpos0Titulo[i] +"\t" + xpos1Titulo[i] + "\t" + xpos2Titulo[i]);
  }
  
  
}

 
 
//  ============ ABRE PUERTO SERIE ===============================================
String abrePuertoSerie ()
{
  String puertoSerie = null;
  String[] serials = Serial.list ();          // Imprime la lista de los puertos serie disponibles.  
  if (serials.length == 0) 
  {
    println ("No hay puertos libres deisponibles");
    exit();
  }
  else
  {
    int numSerial = -1;
    println ("Puertos disponibles: ");
    for (int i = 0; i < serials.length; i++)
    {
      println (i + "  " + serials[i]);
      String[] esUSB = match (serials[i], "usb");
      if (esUSB != null) numSerial = i;
    }
                                              // Hay que cambiar la siguiente linea en función del puerto
                                              // arduino Duelimilanove puertos 4 ó 9
                                              // arduino Mega puertos 
    if ((numSerial >= 0) && (numSerial < serials.length))
    {
      portName = Serial.list () [numSerial];
      println ("numero de puerto " + numSerial);
      myPort = new Serial (this, portName, 9600);
      myPort.bufferUntil ('\n');
      puertoSerie = Serial.list () [numSerial];
    }
    else 
    {
      println ("no hay puerto serie-USB libre");
    }      
  }
  return puertoSerie;
}
  

void anotacionLog(PrintWriter fichero, String texto)
{
  String ahora;
  ahora  = ahora = "<" +nf(year(),4) +"/"+ nf(month(),2) +"/"+ nf(day(),2);
  ahora += " " + nf(hour(),2) +":"+ nf(minute(),2) +":"+ nf(second(),2)+">  ";
  
  long memTotal = instance.totalMemory() / 1000000;
  long memLibre = instance.freeMemory () / 1000000;
  long memUsada = memTotal - memLibre;
  long memDispo = instance.maxMemory  () / 1000000;
    
  if (memLibre < minMemLibre) minMemLibre = memLibre;
  
long llamadasGC = 0;



  
  fichero.println(ahora + " Frame Rate = " + int(frameRate + 0.5) + " mem Libre: " + memLibre + " MB-min = " + minMemLibre + "   " + texto);
  
  
  println (ahora + " Frame Rate = " + int(frameRate + 0.5) + " mem Libre: " + memLibre + " MB-min = " + minMemLibre + "   " + texto);
  
  if (memLibre < 10)
  {
    fichero.println ("INVOCANDO EL GARBAGE COLLECTOR ... ");
    println ("INVOCANDO EL GARBAGE COLLECTOR ... ");

    instance.gc();  // Invoca el garbage collector
    memTotal = instance.totalMemory() / 1000000;
    memLibre = instance.freeMemory () / 1000000;
    memUsada = memTotal - memLibre;
    memDispo = instance.maxMemory  () / 1000000;
    llamadasGC += 1;

    println (ahora + " Frame Rate = " + int(frameRate + 0.5) + " mem Libre: " + memLibre + " MB  (" + llamadasGC + ")   " + texto);
    fichero.println(ahora + " Frame Rate = " + int(frameRate + 0.5) + " mem Libre: " + memLibre + " MB  (" + llamadasGC + ")   " + texto);
  }

  fichero.flush();
    
  
}
