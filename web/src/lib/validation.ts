import { z } from 'zod'

// Helpers de zod compartidos por todos los formularios. Reglas fijas:
//  - z.coerce.number() en todo lo numerico: <input type="number"> siempre
//    entrega strings.
//  - zTextoOpc convierte '' a undefined -- nunca mandarle a la Api un string
//    vacio donde espera null.
//  - Las fechas se quedan como strings 'yyyy-MM-dd' de punta a punta, nunca
//    un objeto Date (evita bugs de timezone al serializar).

export const zTextoReq = (max: number) => z.string().trim().min(1, 'Requerido').max(max, `Maximo ${max} caracteres`)

export const zTextoOpc = (max: number) =>
  z.string().trim().max(max, `Maximo ${max} caracteres`).optional().transform((v) => (v === '' ? undefined : v))

export const zEmailOpc = z.string().trim().email('Email invalido').optional().or(z.literal('')).transform((v) => (v === '' ? undefined : v))

export const zFechaISO = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Fecha invalida')
export const zFechaISOOpc = z.union([zFechaISO, z.literal('')]).optional().transform((v) => (v === '' ? undefined : v))

export const zEnteroPos = z.coerce.number().int('Debe ser un numero entero').positive('Debe ser mayor a cero')
export const zEnteroNoNeg = z.coerce.number().int('Debe ser un numero entero').nonnegative('No puede ser negativo')
export const zMonto = z.coerce.number().nonnegative('No puede ser negativo').finite()
export const zId = z.coerce.number().int().positive('Selecciona una opcion')
export const zIdOpc = z.coerce.number().int().positive().optional().nullable()
