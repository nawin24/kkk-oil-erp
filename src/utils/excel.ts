import * as XLSX from 'xlsx'

/**
 * Exports data rows to a native Microsoft Excel (.xlsx) or (.csv) file
 */
export const exportToExcel = (filename: string, rows: any[], sheetName: string = 'Sheet1') => {
  if (!rows || !rows.length) return
  const worksheet = XLSX.utils.json_to_sheet(rows)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, sheetName)

  // Ensure correct file extension
  const safeFilename = filename.endsWith('.xlsx') || filename.endsWith('.csv') ? filename : `${filename}.xlsx`
  XLSX.writeFile(workbook, safeFilename)
}

/**
 * Parses an uploaded Excel (.xlsx, .xls) or CSV (.csv) file into a JSON array of objects
 */
export const parseExcelOrCsv = (file: File): Promise<any[]> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()

    reader.onload = (e) => {
      try {
        const data = new Uint8Array(e.target?.result as ArrayBuffer)
        const workbook = XLSX.read(data, { type: 'array' })
        const firstSheetName = workbook.SheetNames[0]
        const worksheet = workbook.Sheets[firstSheetName]
        const jsonRows = XLSX.utils.sheet_to_json(worksheet, { defval: '' })
        resolve(jsonRows)
      } catch (err) {
        reject(err)
      }
    }

    reader.onerror = (error) => reject(error)
    reader.readAsArrayBuffer(file)
  })
}
