-- ============================================
-- Happy Oven — Schema de Base de Datos
-- Sistema de Gestión de Inventario
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. RECETA_INGREDIENTES (pivote recetas <-> articulos)
CREATE TABLE receta_ingredientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receta_id UUID NOT NULL REFERENCES recetas(id) ON DELETE CASCADE,
    articulo_id UUID NOT NULL REFERENCES articulos(id) ON DELETE CASCADE,
    cantidad NUMERIC NOT NULL DEFAULT 0,
    unidad TEXT NOT NULL DEFAULT 'gr'
);

-- 6. MOVIMIENTOS (historial Kardex)
CREATE TABLE movimientos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    articulo_id UUID NOT NULL REFERENCES articulos(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES perfiles(id) ON DELETE SET NULL,
    receta_id UUID REFERENCES recetas(id) ON DELETE SET NULL,
    tipo_movimiento TEXT NOT NULL CHECK (tipo_movimiento IN ('entrada', 'salida_produccion', 'merma', 'ajuste')),
    motivo_salida TEXT CHECK (motivo_salida IN ('venta', 'merma', 'degustacion', 'ajuste')),
    cantidad NUMERIC NOT NULL,
    precio_unitario NUMERIC,
    proveedor TEXT,
    observacion TEXT,
    por_ocr BOOLEAN NOT NULL DEFAULT FALSE,
    fecha TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. ALERTAS
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
CREATE INDEX idx_alertas_tipo ON alertas(tipo);
CREATE INDEX idx_alertas_leida ON alertas(leida);
CREATE INDEX idx_receta_ingredientes_receta ON receta_ingredientes(receta_id);
