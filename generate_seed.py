import uuid
import random

def generate_sql():
    insumos_names = [
        "Harina de Trigo sin Preparar", "Harina Preparada", "Azúcar Blanca", "Azúcar Rubia", "Azúcar Impalpable",
        "Mantequilla sin Sal", "Mantequilla con Sal", "Margarina Pastelera", "Huevos Rosados", "Huevos Blancos",
        "Leche Entera", "Leche Evaporada", "Leche Condensada", "Crema de Leche", "Polvo de Hornear",
        "Bicarbonato de Sodio", "Esencia de Vainilla", "Cocoa en Polvo", "Cobertura de Chocolate Bitter",
        "Cobertura de Chocolate Blanco", "Cobertura de Chocolate Leche", "Chispas de Chocolate", "Manjar Blanco",
        "Fudge", "Queso Crema", "Levadura Fresca", "Levadura Seca Activa", "Sal", "Aceite Vegetal", "Manteca",
        "Canela Molida", "Clavo de Olor Molido", "Nuez Moscada", "Jengibre Molido", "Almendras Fileteadas",
        "Nueces Picadas", "Pecanas Picadas", "Pasas Morenas", "Pasas Rubias", "Fruta Confitada", "Cerezas Marrasquino",
        "Fresas Frescas", "Arándanos Frescos", "Limones", "Naranjas", "Manzanas", "Plátanos", "Zanahorias",
        "Coco Rallado", "Gelatina sin Sabor", "Colapez", "Glucosa", "Glicerina", "Fondant", "Colorante Rojo",
        "Colorante Azul", "Colorante Amarillo", "Colorante Verde", "Polvo de Almendras", "Mermelada de Fresa",
        "Mermelada de Piña", "Mermelada de Sauco", "Crema Chantilly (Mix)", "Pisco", "Ron Blanco", "Anís",
        "Avena Laminada", "Maicena", "Castañas", "Ajonjolí"
    ]
    
    productos_names = [
        "Torta de Chocolate", "Torta Tres Leches", "Torta de Fresa", "Cheesecake de Maracuyá", "Cheesecake de Fresa",
        "Pie de Limón", "Pie de Manzana", "Alfajores de Maicena", "Pionono de Manjar", "Brownies Clásicos",
        "Keke de Vainilla", "Keke de Naranja", "Keke de Plátano", "Keke de Zanahoria", "Keke Inglés",
        "Cupcakes de Vainilla", "Cupcakes de Chocolate", "Red Velvet Cake", "Torta Selva Negra", "Torta Ópera",
        "Galletas Chocochip", "Galletas de Avena", "Muffins de Arándanos", "Empanadas de Carne", "Empanadas de Pollo",
        "Pastel de Acelga", "Quiche Lorraine", "Pan Ciabatta", "Pan Francés", "Pan de Yema"
    ]

    insumos = []
    productos = []
    
    sql = "-- Archivo de Seed para Supabase: Pastelería (Restricciones Corregidas)\n\n"
    sql += "BEGIN;\n\n"
    
    sql += "-- 0. Sincronizar usuario real automáticamente desde la tabla users\n"
    sql += "INSERT INTO perfiles (id, nombre_completo, rol, created_at)\n"
    sql += "SELECT id, 'Admin Generado', 'admin', NOW() FROM auth.users LIMIT 1\n"
    sql += "ON CONFLICT (id) DO NOTHING;\n\n"
    
    sql += "INSERT INTO perfiles (id, nombre_completo, rol, created_at)\n"
    sql += "SELECT id, 'Admin Generado', 'admin', NOW() FROM users LIMIT 1\n"
    sql += "ON CONFLICT (id) DO NOTHING;\n\n"

    sql += "-- 1. Insertar Insumos\n"
    for name in insumos_names:
        item_id = str(uuid.uuid4())
        unidad = random.choice(["kg", "gr", "litros", "ml", "unid."])
        stock = round(random.uniform(0.1, 50.0), 2)
        minimo = round(random.uniform(1.0, 10.0), 2)
        if unidad == "unid.":
            stock = int(stock)
            minimo = int(minimo)
            
        insumos.append({"id": item_id, "nombre": name, "unidad": unidad})
        sql += f"INSERT INTO articulos (id, nombre, unidad, stock_actual, stock_minimo, tipo) "
        sql += f"VALUES ('{item_id}', '{name}', '{unidad}', {stock}, {minimo}, 'insumo');\n"

    sql += "\n-- 2. Insertar Productos Finales\n"
    for name in productos_names:
        item_id = str(uuid.uuid4())
        stock = random.randint(0, 30)
        minimo = random.randint(2, 10)
        productos.append({"id": item_id, "nombre": name, "unidad": "unid."})
        sql += f"INSERT INTO articulos (id, nombre, unidad, stock_actual, stock_minimo, tipo) "
        sql += f"VALUES ('{item_id}', '{name}', 'unid.', {stock}, {minimo}, 'producto_final');\n"

    sql += "\n-- 3. Crear Recetas y sus Ingredientes\n"
    for prod in productos[:15]:
        receta_id = str(uuid.uuid4())
        rendimiento = random.randint(8, 24)
        sql += f"INSERT INTO recetas (id, nombre, rendimiento, tiempo_produccion_min, costo_lote, instrucciones, created_at, updated_at) "
        sql += f"VALUES ('{receta_id}', 'Receta de {prod['nombre']}', {rendimiento}, 60, 0, 'Instrucciones generadas', NOW(), NOW());\n"
        
        num_ings = random.randint(3, 6)
        ings = random.sample(insumos, num_ings)
        for ing in ings:
            cant = round(random.uniform(0.05, 1.5), 2)
            if ing['unidad'] == 'unid.':
                cant = float(random.randint(1, 10))
            sql += f"INSERT INTO receta_ingredientes (id, receta_id, insumo_id, cantidad_requerida, unidad) "
            sql += f"VALUES ('{str(uuid.uuid4())}', '{receta_id}', '{ing['id']}', {cant}, '{ing['unidad']}');\n"

    sql += "\n-- 4. Generar Movimientos de Historial Aleatorios\n"
    todos = insumos + productos
    for i in range(50):
        item = random.choice(todos)
        tipo_mov = random.choice(['entrada', 'salida_produccion'])
        cant = round(random.uniform(0.5, 10.0), 2)
        if item['unidad'] == 'unid.':
            cant = float(random.randint(1, 15))
            
        sql += f"INSERT INTO movimientos (id, articulo_id, usuario_id, tipo_movimiento, cantidad) "
        sql += f"VALUES ('{str(uuid.uuid4())}', '{item['id']}', (SELECT id FROM perfiles LIMIT 1), '{tipo_mov}', {cant});\n"

    sql += "\nCOMMIT;\n"
    
    with open("seed_data.sql", "w") as f:
        f.write(sql)

generate_sql()
print("SQL file generated successfully with valid movement types.")
