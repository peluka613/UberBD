--------------------------------------------------------------------------------------------------
--------------------------------------TALLER 2----------------------------------------------------

---PUNTO 1

CREATE OR REPLACE VIEW MEDIOS_PAGO_CLIENTES AS
    SELECT CLI.ID, CLI.NOMBRES || ' ' || CLI.APELLIDOS AS NOMBRE_CLIENTE, PAG.ID AS MEDIO_PAGO_ID, PAG.TIPO, 
    PAG.DESCRIPCION AS DETALLE_MEDIO_PAGO, (CASE WHEN CLIEMP.ID IS NULL THEN 'FALSO' ELSE 'VERDADERO' END) AS EMPRESARIAL,
    EMP.NOMBRE AS NOMBRE_EMPRESA 
    FROM CLIENTES CLI 
    INNER JOIN MEDIOS_PAGO PAG ON PAG.CLIENTE_ID = CLI.ID
    LEFT JOIN CLIENTES_EMPRESAS CLIEMP ON CLI.ID = CLIEMP.CLIENTE_ID
    LEFT JOIN EMPRESAS EMP ON CLIEMP.EMPRESA_ID = EMP.ID;
    
---PUNTO 2

CREATE OR REPLACE VIEW VIAJES_CLIENTES AS
	SELECT SER.FECHA AS FECHA_VIAJE, COND.NOMBRES || ' ' || COND.APELIDOS AS NOMBRE_CONDUCTOR, VEHI.PLACA AS PLACA_VEHICULO, 
            CLI.NOMBRES || ' ' || CLI.APELLIDOS AS NOMBRE_CLIENTE, SUM(DETFAC.VALOR)  AS VALOR_TOTAL, SER.TARIFA_DINAMICA, 
            VEHI.TIPO_SERVICIO, CIU.NOMBRE AS CIUDAD_VIAJE
    FROM SERVICIOS SER INNER JOIN CONDUCTORES_VEHICULOS CONVEHI ON SER.CONDUCTORES_VEHICULOS_ID = CONVEHI.ID
                       INNER JOIN CONDUCTORES COND ON CONVEHI.CONDUCTOR_ID = COND.ID
                       INNER JOIN VEHICULOS VEHI ON CONVEHI.VEHICULO_ID = VEHI.ID
                       INNER JOIN CLIENTES CLI ON SER.CLIENTE_ID = CLI.ID
                       INNER JOIN FACTURAS FAC ON FAC.SERVICIO_ID = SER.ID
                       INNER JOIN DETALLES_FACTURAS DETFAC ON DETFAC.FACTURA_ID = FAC.ID
                       INNER JOIN CIUDADES CIU ON CLI.CIUDAD_ID = CIU.ID                  
    GROUP BY SER.FECHA, COND.NOMBRES, COND.APELIDOS, VEHI.PLACA, CLI.NOMBRES, CLI.APELLIDOS, SER.TARIFA_DINAMICA, VEHI.TIPO_SERVICIO,
    CIU.NOMBRE
    ORDER BY FECHA_VIAJE; 
    
---PUNTO 3
--creo explainplan para verificar rendimiento de la vista del punto 2
EXPLAIN PLAN SET STATEMENT_ID = 'EP_VIAJES_CLIENTES' FOR
  SELECT * FROM VIAJES_CLIENTES;
  
SELECT * FROM TABLE
  (DBMS_XPLAN.DISPLAY('PLAN_TABLE','EP_VIAJES_CLIENTES','TYPICAL'))
  
  CREATE UNIQUE INDEX CIUDAD ON CIUDADES(NOMBRE); -- Se crea un indice parala tabla ciudades para dar optimizacion a la busqueda
  
 EXPLAIN PLAN SET STATEMENT_ID = 'EP_VIAJES_CLIENTES_INDICE' FOR
  SELECT * FROM VIAJES_CLIENTES;

---PUNTO 4
---VER TABLA CIUDADES DONDE SE EVIDENCIA LA CREACION DE LOS 3 NUEVOS CAMPOS CON SUS RESPECTIVOS VALORES.
SELECT * FROM CIUDADES;

---PUNTO 5

CREATE OR REPLACE FUNCTION VALOR_DISTANCIA(KILOMETROS DECIMAL, CIUDAD VARCHAR2)
RETURN DECIMAL IS
    TARIFA DECIMAL;
    NOM_CIU VARCHAR2(255);
    VAL_KIL DECIMAL;
    MENSAJE_CIUDAD EXCEPTION;
    MENSAJE_KILOMETROS EXCEPTION;
BEGIN
    --REALIZO LA CONSULTA PARA CAPTURAR LOS VALORES DEL KILOMETRO T VALCULAR LA TARIFA
    SELECT CIU.NOMBRE, CIU.VALOR_KILOMETRO
    INTO NOM_CIU, VAL_KIL
    FROM CIUDADES CIU
    WHERE CIU.NOMBRE = CIUDAD;
    
    --CAPTUROLAS EXCEPCIONES
    IF KILOMETROS <= 0 THEN
        RAISE MENSAJE_KILOMETROS;
    ELSIF CIUDAD <> NOM_CIU THEN
        RAISE MENSAJE_CIUDAD;
    ELSE 
    
    --CALCULO LA TARIFA Y RETORNO EL VALOR
    TARIFA := VAL_KIL * KILOMETROS;
    RETURN TARIFA;
    END IF;
    
    --CAPTURO Y RETORNO LAS EXCEPCIONES
    EXCEPTION
        WHEN MENSAJE_KILOMETROS THEN
            DBMS_OUTPUT.PUT_LINE('LA CANTIDAD DE KILOMETROS ES ERRADA, VERIFIQUE POR FAVOR.');
            RETURN 0;
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('LA CIUDAD ES ERRADA, VERIFIQUE POR FAVOR.');
            RETURN 0;
END;

--EXECUTO LA FUNCIÓN
SELECT VALOR_DISTANCIA(-2,'MEDELLIN') AS TARIFA FROM DUAL;

-----PUNTO 6

CREATE OR REPLACE FUNCTION VALOR_TIEMPO(MINUTOS INTEGER, CIUDAD VARCHAR2)
RETURN DECIMAL IS
    TARIFA DECIMAL;
    NOM_CIU VARCHAR2(255);
    VAL_MIN DECIMAL;
    MENSAJE_CIUDAD EXCEPTION;
    MENSAJE_MINUTOS EXCEPTION;
BEGIN
    --REALIZO LA CONSULTA PARA CAPTURAR EL VALOR DEL MINUTO SE SERVICIO
    SELECT CIU.NOMBRE, CIU.VALOR_POR_MINUTO
    INTO NOM_CIU, VAL_MIN
    FROM CIUDADES CIU
    WHERE CIU.NOMBRE = CIUDAD;
    
    --EVALUO LOS POSIBLES ERRORES Y EXCEPCIONES
    IF MINUTOS < 0 THEN
        RAISE MENSAJE_MINUTOS;
    ELSIF CIUDAD <> NOM_CIU THEN
        RAISE MENSAJE_CIUDAD;
    ELSE 
    
    --CALUCULO LA TARIFA
    TARIFA := VAL_MIN * MINUTOS;
    RETURN TARIFA;
    END IF;
    
    ---CAPTURO Y RETORNO LAS EXCEPCIONES
    EXCEPTION
        WHEN MENSAJE_MINUTOS THEN
            DBMS_OUTPUT.PUT_LINE('LA CANTIDAD DE MINUTOS ES ERRADA, VERIFIQUE POR FAVOR.');
            RETURN 0;
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('LA CIUDAD ES ERRADA, VERIFIQUE POR FAVOR.');
            RETURN 0;
END;

--EXECUTO LA FUNCIÓN
SELECT VALOR_TIEMPO(1,'MEDELLIN') AS TARIFA FROM DUAL;
