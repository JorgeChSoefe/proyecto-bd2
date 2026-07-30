import type { FieldValues, Path, UseFormReturn } from 'react-hook-form'
import { ApiError } from './client'

/**
 * "Detalle[0].IdProducto" -> "detalle.0.idProducto".
 * FluentValidation con RuleForEach (ver VentaValidators.cs, CompraValidators.cs,
 * ClienteRecetaValidators.cs) produce PropertyName con indices entre
 * corchetes y PascalCase -- react-hook-form espera rutas con puntos y la
 * misma casing que los campos del formulario (camelCase).
 */
export function aRutaRhf(propertyName: string): string {
  return propertyName
    .split('.')
    .flatMap((seg) => seg.replace(/\[(\d+)\]/g, '.$1').split('.'))
    .map((seg) => (seg.length > 0 ? seg.charAt(0).toLowerCase() + seg.slice(1) : seg))
    .join('.')
}

/**
 * Aplica los errores 400 de un ApiError al formulario. Nunca descarta un
 * error en silencio: lo que no matchea un campo conocido se devuelve como
 * mensaje "suelto" para mostrar en un <AlertaFormulario/>. 409/422/404 (sin
 * `errores`) devuelven directamente el `detail` del servidor.
 */
export function aplicarErroresServidor<T extends FieldValues>(
  err: unknown,
  form: UseFormReturn<T>,
  camposConocidos: string[],
): string | null {
  if (!(err instanceof ApiError)) return 'Ocurrio un error inesperado.'

  if (err.esValidacion && err.errores) {
    const sueltos: string[] = []
    for (const [prop, mensajes] of Object.entries(err.errores)) {
      const ruta = aRutaRhf(prop)
      const coincide =
        camposConocidos.some((c) => ruta === c || ruta.startsWith(`${c}.`)) ||
        /^\w+\.\d+\./.test(ruta) // rutas de useFieldArray (ej. detalle.0.cantidad)

      if (coincide) {
        form.setError(ruta as Path<T>, { type: 'server', message: mensajes[0] })
      } else {
        sueltos.push(`${prop}: ${mensajes[0]}`)
      }
    }
    return sueltos.length > 0 ? sueltos.join(' · ') : null
  }

  return err.problem?.detail ?? err.message
}
