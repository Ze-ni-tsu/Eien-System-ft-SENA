// PROGRAMA: Tecnólogo en Análisis y Desarrollo de Software (ADSO)
// PROYECTO: Eien-System - Kizuna Logística S.A.S.
// EVIDENCIA: GA6-220501096-AA1-EV03-EV04 - Creación de los objetos de la base de datos NoSQL (MongoDB)
// APRENDIZ: David Alejandro Meyer Romero

// 1. Selección y apertura de la Base de Datos del Proyecto
use eien_system_db;

// 2. CREACIÓN DE COLECCIONES Y VALIDACIÓN DE ESQUEMA (BSON SCHEMA)

// Colección: usuarios (Gestión de roles y autenticación)
db.createCollection("usuarios", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["nombre", "email", "password_hash", "rol", "estado"],
         properties: {
            nombre: { bsonType: "string", description: "Nombre completo del usuario" },
            email: { bsonType: "string", pattern: "^.+@.+$", description: "Correo electrónico válido" },
            password_hash: { bsonType: "string", description: "Contraseña encriptada con BCrypt" },
            rol: { enum: ["Administrador", "Despachador", "Conductor", "Cliente"], description: "Rol dentro del sistema" },
            estado: { enum: ["Activo", "Bloqueado", "Inactivo"], description: "Estado de la cuenta" },
            intentos_fallidos: { bsonType: "int", description: "Contador de intentos de inicio de sesión" }
         }
      }
   }
});

// Colección: vehiculos (Gestión de la flota de transporte)
db.createCollection("vehiculos", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["placa", "modelo", "capacidad_kg", "capacidad_vol_m3", "estado"],
         properties: {
            placa: { bsonType: "string", description: "Placa única del vehículo" },
            modelo: { bsonType: "string", description: "Marca y modelo" },
            capacidad_kg: { bsonType: "double", minimum: 0.1, description: "Capacidad máxima en kilogramos" },
            capacidad_vol_m3: { bsonType: "double", minimum: 0.01, description: "Capacidad en metros cúbicos" },
            estado: { enum: ["Disponible", "En Ruta", "En Mantenimiento"], description: "Disponibilidad operativa" }
         }
      }
   }
});

// Colección: envios (Documento principal embedding cliente, evidencia e historial)
db.createCollection("envios", {
   validator: {
      $jsonSchema: {
         bsonType: "object",
         required: ["codigo_hash", "cliente", "peso_kg", "volumen_m3", "direccion_destino", "estado"],
         properties: {
            codigo_hash: { bsonType: "string", description: "Código de seguimiento único SHA-256" },
            cliente: {
               bsonType: "object",
               required: ["documento", "nombre", "telefono"],
               properties: {
                  documento: { bsonType: "string" },
                  nombre: { bsonType: "string" },
                  telefono: { bsonType: "string" },
                  email: { bsonType: "string" }
               }
            },
            peso_kg: { bsonType: "double", minimum: 0.01 },
            volumen_m3: { bsonType: "double", minimum: 0.01 },
            direccion_destino: { bsonType: "string" },
            estado: { enum: ["En Bodega", "Asignado", "En Tránsito", "Entregado", "Fallido", "Devolución", "Cancelado"] },
            prioridad: { enum: ["Baja", "Media", "Alta"] },
            conductor_asignado: {
               bsonType: "object",
               properties: {
                  nombre: { bsonType: "string" }
               }
            },
            vehiculo_asignado: {
               bsonType: "object",
               properties: {
                  placa: { bsonType: "string" }
               }
            },
            evidencia: {
               bsonType: "object",
               properties: {
                  fotografia_url: { bsonType: "string" },
                  ubicacion_gps: {
                     bsonType: "object",
                     properties: {
                        latitud: { bsonType: "double" },
                        longitud: { bsonType: "double" }
                     }
                  },
                  recibido_por: { bsonType: "string" },
                  fecha_entrega: { bsonType: "date" }
               }
            },
            historial: {
               bsonType: "array",
               items: {
                  bsonType: "object",
                  required: ["estado_nuevo", "fecha_cambio"],
                  properties: {
                     estado_anterior: { bsonType: "string" },
                     estado_nuevo: { bsonType: "string" },
                     usuario_modifico: { bsonType: "string" },
                     observaciones: { bsonType: "string" },
                     fecha_cambio: { bsonType: "date" }
                  }
               }
            }
         }
      }
   }
});

// 3. RESTRICCIONES E ÍNDICES ÚNICOS (REGLAS DE NEGOCIO)

db.usuarios.createIndex({ "email": 1 }, { unique: true });
db.vehiculos.createIndex({ "placa": 1 }, { unique: true });
db.envios.createIndex({ "codigo_hash": 1 }, { unique: true });

// 4. OPERACIONES DE PRUEBA Y TRAZABILIDAD (DML)

// Insertar un usuario con rol Conductor
db.usuarios.insertOne({
   nombre: "Carlos Conductor",
   email: "carlos@kizuna.com",
   password_hash: "$2b$12$eImiTXuWVxfM37uY4JANjO",
   rol: "Conductor",
   estado: "Activo",
   intentos_fallidos: NumberInt(0)
});

// Insertar un vehículo de reparto
db.vehiculos.insertOne({
   placa: "KZN-830",
   modelo: "Chevrolet N300",
   capacidad_kg: Double(650.00),
   capacidad_vol_m3: Double(4.30),
   estado: "Disponible"
});

// Registrar un envío inicial en bodega
db.envios.insertOne({
   codigo_hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
   cliente: {
      documento: "900123456",
      nombre: "SENA Regional Cauca",
      telefono: "3001234567",
      email: "contacto@sena.edu.co"
   },
   peso_kg: Double(12.50),
   volumen_m3: Double(0.15),
   direccion_destino: "Calle 4 # 2-80, Popayán",
   estado: "En Bodega",
   prioridad: "Alta",
   historial: [{
      estado_anterior: null,
      estado_nuevo: "En Bodega",
      usuario_modifico: "David Meyer (Despachador)",
      observaciones: "Ingreso a bodega principal",
      fecha_cambio: new Date()
   }]
});

// Asignar el envío al conductor y vehículo
db.envios.updateOne(
   { codigo_hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" },
   {
      $set: {
         estado: "Asignado",
         conductor_asignado: { nombre: "Carlos Conductor" },
         vehiculo_asignado: { placa: "KZN-830" }
      },
      $push: {
         historial: {
            estado_anterior: "En Bodega",
            estado_nuevo: "Asignado",
            usuario_modifico: "Despachador",
            observaciones: "Asignado a vehículo KZN-830",
            fecha_cambio: new Date()
         }
      }
   }
);

// Registrar entrega final con foto y coordenadas GPS
db.envios.updateOne(
   { codigo_hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" },
   {
      $set: {
         estado: "Entregado",
         evidencia: {
            fotografia_url: "https://storage.kizuna.com/evidencias/envio_1.jpg",
            ubicacion_gps: { latitud: Double(2.4419), longitud: Double(-76.6063) },
            recibido_por: "Jhon Moreno",
            fecha_entrega: new Date()
         }
      },
      $push: {
         historial: {
            estado_anterior: "En Tránsito",
            estado_nuevo: "Entregado",
            usuario_modifico: "Carlos Conductor",
            observaciones: "Entregado con foto de evidencia",
            fecha_cambio: new Date()
         }
      }
   }
);

// Consultar la trazabilidad completa del envío
db.envios.find({ codigo_hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" });