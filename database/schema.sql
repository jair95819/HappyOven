-- ============================================
-- Happy Oven — Schema de Base de Datos
-- Sistema de Gestión de Inventario y Producción
-- ============================================

-- 1. PERFILES (extiende auth.users de Supabase)
CREATE TABLE perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre_completo TEXT NOT NULL DEFAULT 'Usuario',
    rol TEXT NOT NULL DEFAULT 'operador' CHECK (rol IN ('admin', 'operador')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. CATEGORÍAS
CREATE TABLE categorias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('insumo', 'producto_final')),
    orden INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. ARTÍCULOS (tabla central del inventario)
CREATE TABLE articulos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('insumo', 'producto_final')),
    unidad TEXT NOT NULL DEFAULT 'kg',
    stock_actual NUMERIC NOT NULL DEFAULT 0,
    stock_minimo NUMERIC NOT NULL DEFAULT 0,
    precio_unitario NUMERIC NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. RECETAS
CREATE TABLE recetas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    producto_id UUID REFERENCES articulos(id) ON DELETE SET NULL,
    rendimiento_unidades INT NOT NULL DEFAULT 1,
    tiempo_produccion_min INT NOT NULL DEFAULT 60,
    costo_lote NUMERIC NOT NULL DEFAULT 0,
    instrucciones TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. RECETA_INGREDIENTES (pivote recetas <-> articulos/insumos)
CREATE TABLE receta_ingredientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receta_id UUID NOT NULL REFERENCES recetas(id) ON DELETE CASCADE,
    insumo_id UUID NOT NULL REFERENCES articulos(id) ON DELETE CASCADE,
    cantidad_requerida NUMERIC NOT NULL DEFAULT 0,
    unidad TEXT NOT NULL DEFAULT 'gr'
);

-- 6. ÓRDENES DE PRODUCCIÓN
CREATE TABLE ordenes_produccion (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receta_id UUID NOT NULL REFERENCES recetas(id) ON DELETE RESTRICT,
    usuario_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE SET NULL,
    cantidad_lotes INT NOT NULL DEFAULT 1,
    cantidad_producida INT DEFAULT 0,
    estado TEXT NOT NULL DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'en_proceso', 'completada', 'cancelada')),
    fecha_programada TIMESTAMPTZ,
    fecha_inicio TIMESTAMPTZ,
    fecha_fin TIMESTAMPTZ,
    notas TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. MOVIMIENTOS (historial Kardex)
CREATE TABLE movimientos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    articulo_id UUID NOT NULL REFERENCES articulos(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE SET NULL,
    receta_id UUID REFERENCES recetas(id) ON DELETE SET NULL,
    orden_produccion_id UUID REFERENCES ordenes_produccion(id) ON DELETE SET NULL,
    tipo_movimiento TEXT NOT NULL CHECK (tipo_movimiento IN ('entrada', 'salida_produccion', 'merma', 'ajuste')),
    motivo_salida TEXT CHECK (motivo_salida IN ('venta', 'merma', 'degustacion', 'ajuste')),
    cantidad NUMERIC NOT NULL,
    precio_unitario NUMERIC,
    proveedor TEXT,
    observacion TEXT,
    por_ocr BOOLEAN NOT NULL DEFAULT FALSE,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. ALERTAS
CREATE TABLE alertas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    articulo_id UUID REFERENCES articulos(id) ON DELETE CASCADE,
    tipo TEXT NOT NULL CHECK (tipo IN ('stock_bajo', 'anomalia', 'ia', 'ingreso')),
    titulo TEXT NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ÍNDICES
CREATE INDEX idx_articulos_tipo ON articulos(tipo);
CREATE INDEX idx_articulos_categoria ON articulos(categoria_id);
CREATE INDEX idx_movimientos_articulo ON movimientos(articulo_id);
CREATE INDEX idx_movimientos_fecha ON movimientos(fecha DESC);
CREATE INDEX idx_movimientos_tipo ON movimientos(tipo_movimiento);
CREATE INDEX idx_movimientos_orden ON movimientos(orden_produccion_id);
CREATE INDEX idx_alertas_tipo ON alertas(tipo);
CREATE INDEX idx_alertas_leida ON alertas(leida);
CREATE INDEX idx_receta_ingredientes_receta ON receta_ingredientes(receta_id);
CREATE INDEX idx_ordenes_produccion_estado ON ordenes_produccion(estado);
CREATE INDEX idx_ordenes_produccion_fecha ON ordenes_produccion(fecha_programada);

-- ============================================
-- RLS POLICIES
-- Run this section in Supabase Dashboard > SQL Editor
-- if RLS is enabled on your tables
-- ============================================

-- PERFILES
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_perfiles_all" ON perfiles FOR ALL USING (true) WITH CHECK (true);

-- CATEGORIAS
ALTER TABLE categorias ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_categorias_all" ON categorias FOR ALL USING (true) WITH CHECK (true);

-- ARTICULOS
ALTER TABLE articulos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_articulos_all" ON articulos FOR ALL USING (true) WITH CHECK (true);

-- RECETAS
ALTER TABLE recetas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_recetas_all" ON recetas FOR ALL USING (true) WITH CHECK (true);

-- RECETA_INGREDIENTES
ALTER TABLE receta_ingredientes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_receta_ingredientes_all" ON receta_ingredientes FOR ALL USING (true) WITH CHECK (true);

-- ORDENES_PRODUCCION
ALTER TABLE ordenes_produccion ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_ordenes_all" ON ordenes_produccion FOR ALL USING (true) WITH CHECK (true);

-- MOVIMIENTOS
ALTER TABLE movimientos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_movimientos_all" ON movimientos FOR ALL USING (true) WITH CHECK (true);

-- ALERTAS
ALTER TABLE alertas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "anon_alertas_all" ON alertas FOR ALL USING (true) WITH CHECK (true);
