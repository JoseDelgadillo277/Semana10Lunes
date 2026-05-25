const fs = require("fs");
const path = require("path");
const productosEventos = require("./productos_eventos.json");

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

async function importarEventos() {
  try {
    if (!Array.isArray(productosEventos) || productosEventos.length === 0) {
      throw new Error("scripts/productos_eventos.json no tiene productos para importar.");
    }

    const lotes = [];

    for (let i = 0; i < productosEventos.length; i += 500) {
      const batch = db.batch();
      const grupo = productosEventos.slice(i, i + 500);

      grupo.forEach((item, indice) => {
        if (!item.codigo) {
          throw new Error(`Producto de evento sin codigo en la posicion ${i + indice}.`);
        }

        const referencia = db.collection("productos_eventos").doc(item.codigo);
        batch.set(referencia, item);
      });

      lotes.push(batch.commit());
    }

    await Promise.all(lotes);

    console.log("Productos para eventos importados correctamente.");
    console.log(`Total importado: ${productosEventos.length}`);
    process.exit(0);
  } catch (error) {
    console.error("Error al importar productos para eventos:");
    console.error(error);
    process.exit(1);
  }
}

importarEventos();
