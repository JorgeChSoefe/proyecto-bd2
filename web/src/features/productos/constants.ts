import type { OpcionSelect } from '@/components/crud/crud-config'

// Espejo exacto del enum ViaAdministracion (src/PharmaInventory.Domain/Enums/Enums.cs)
// -- viaja como string snake_case gracias a JsonStringEnumConverter en Program.cs.
export const VIA_ADMINISTRACION_OPCIONES: OpcionSelect[] = [
  { valor: 'oral', etiqueta: 'Oral' },
  { valor: 'topica', etiqueta: 'Topica' },
  { valor: 'intravenosa', etiqueta: 'Intravenosa' },
  { valor: 'intramuscular', etiqueta: 'Intramuscular' },
  { valor: 'subcutanea', etiqueta: 'Subcutanea' },
  { valor: 'inhalatoria', etiqueta: 'Inhalatoria' },
  { valor: 'oftalmica', etiqueta: 'Oftalmica' },
  { valor: 'otica', etiqueta: 'Otica' },
  { valor: 'nasal', etiqueta: 'Nasal' },
  { valor: 'rectal', etiqueta: 'Rectal' },
  { valor: 'sublingual', etiqueta: 'Sublingual' },
]
