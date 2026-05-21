const fs = require("fs");
const path = require("path");
const productos = require("./productos.json");

const serviceAccountPath =
  process.env.SERVICE_ACCOUNT_PATH || path.join(__dirname, "serviceAccountKey.json");

if (!fs.existsSync(serviceAccountPath)) {
  console.error("Falta scripts/serviceAccountKey.json");
  console.error("Tambien puedes indicar una ruta externa con SERVICE_ACCOUNT_PATH.");
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);
const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function importarProductos() {
  try {
    if (!Array.isArray(productos) || productos.length === 0) {
      throw new Error("scripts/productos.json no tiene productos para importar.");
    }

    const lotes = [];

    for (let i = 0; i < productos.length; i += 500) {
      const batch = db.batch();
      const grupo = productos.slice(i, i + 500);

      grupo.forEach((item) => {
        if (!item.codigo) {
          throw new Error(`Producto sin codigo en la posicion ${i}.`);
        }

        const referencia = db.collection("inventario_catering").doc(item.codigo);
        batch.set(referencia, item);
      });

      lotes.push(batch.commit());
    }

    await Promise.all(lotes);

    console.log("Productos importados correctamente.");
    console.log(`Total importado: ${productos.length}`);
    process.exit(0);
  } catch (error) {
    console.error("Error al importar productos:");
    console.error(error);
    process.exit(1);
  }
}

importarProductos();
