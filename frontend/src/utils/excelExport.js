import * as XLSX from 'xlsx';

/**
 * Utilitaire pour les exports Excel
 */

/**
 * Export des données d'impôts au format Excel
 * @param {Array} data - Données des impôts
 * @param {string} filename - Nom du fichier (optionnel)
 */
export const exportImpots = (data, filename = 'impots_export.xlsx') => {
  try {
    // Structure des colonnes pour les impôts
    const columns = [
      'Nom',
      'Revenu',
      'Patrimoine',
      'Tranche Impôt',
      'Taux Impôt (%)',
      'Montant Impôt',
      'Tranche Patrimoine', 
      'Taux Patrimoine (%)',
      'Montant Patrimoine',
      'Total Impôts',
      'Date Calcul'
    ];

    // Transformer les données pour l'export
    const exportData = data.map(item => ({
      'Nom': item.name || '',
      'Revenu': item.income || 0,
      'Patrimoine': item.wealth || 0,
      'Tranche Impôt': item.incomeTaxBracket || '',
      'Taux Impôt (%)': item.incomeTaxRate || 0,
      'Montant Impôt': item.incomeTaxAmount || 0,
      'Tranche Patrimoine': item.wealthTaxBracket || '',
      'Taux Patrimoine (%)': item.wealthTaxRate || 0,
      'Montant Patrimoine': item.wealthTaxAmount || 0,
      'Total Impôts': item.totalTax || 0,
      'Date Calcul': item.calculationDate || new Date().toLocaleDateString('fr-FR')
    }));

    return exportToExcel(exportData, filename, 'Impôts');
  } catch (error) {
    console.error('Erreur export impôts:', error);
    throw new Error('Erreur lors de l\'export des impôts');
  }
};

/**
 * Export des données de blanchiment au format Excel
 * @param {Array} data - Données de blanchiment
 * @param {string} filename - Nom du fichier (optionnel)
 */
export const exportBlanchiment = (data, filename = 'blanchiment_export.xlsx') => {
  try {
    // Structure des colonnes pour le blanchiment
    const columns = [
      'Date Transaction',
      'Montant',
      'Description',
      'Signalé',
      'Niveau Risque',
      'Seuil Dépassé',
      'Date Analyse',
      'Commentaires'
    ];

    // Transformer les données pour l'export
    const exportData = data.map(item => ({
      'Date Transaction': item.transactionDate || '',
      'Montant': item.amount || 0,
      'Description': item.description || '',
      'Signalé': item.flagged ? 'Oui' : 'Non',
      'Niveau Risque': item.riskLevel || 'Faible',
      'Seuil Dépassé': item.thresholdExceeded ? 'Oui' : 'Non',
      'Date Analyse': item.analysisDate || new Date().toLocaleDateString('fr-FR'),
      'Commentaires': item.comments || ''
    }));

    return exportToExcel(exportData, filename, 'Blanchiment');
  } catch (error) {
    console.error('Erreur export blanchiment:', error);
    throw new Error('Erreur lors de l\'export du blanchiment');
  }
};

/**
 * Export des données d'archives au format Excel
 * @param {Array} data - Données d'archives
 * @param {string} filename - Nom du fichier (optionnel)
 */
export const exportArchives = (data, filename = 'archives_export.xlsx') => {
  try {
    // Structure des colonnes pour les archives
    const columns = [
      'Titre',
      'Type',
      'Description',
      'Date Archive',
      'Archivé Par',
      'Taille',
      'Statut',
      'Chemin Fichier'
    ];

    // Transformer les données pour l'export
    const exportData = data.map(item => ({
      'Titre': item.title || '',
      'Type': item.archiveType || '',
      'Description': item.description || '',
      'Date Archive': item.archivedAt || '',
      'Archivé Par': item.archivedBy || '',
      'Taille': item.fileSize || '',
      'Statut': item.status || 'Archivé',
      'Chemin Fichier': item.fileUrl || ''
    }));

    return exportToExcel(exportData, filename, 'Archives');
  } catch (error) {
    console.error('Erreur export archives:', error);
    throw new Error('Erreur lors de l\'export des archives');
  }
};

/**
 * Export des données de dotations au format Excel
 * @param {Array} data - Données de dotations
 * @param {string} filename - Nom du fichier (optionnel)
 */
export const exportDotations = (data, filename = 'dotations_export.xlsx') => {
  try {
    // Structure des colonnes pour les dotations
    const columns = [
      'Nom Employé',
      'Grade',
      'Salaire Base',
      'Multiplicateur',
      'Prime',
      'Total',
      'Date Rapport',
      'Statut'
    ];

    // Transformer les données pour l'export
    const exportData = data.map(item => ({
      'Nom Employé': item.employeeName || '',
      'Grade': item.grade || '',
      'Salaire Base': item.baseSalary || 0,
      'Multiplicateur': item.multiplier || 1.0,
      'Prime': item.bonus || 0,
      'Total': item.totalAmount || 0,
      'Date Rapport': item.reportDate || '',
      'Statut': item.status || 'Actif'
    }));

    return exportToExcel(exportData, filename, 'Dotations');
  } catch (error) {
    console.error('Erreur export dotations:', error);
    throw new Error('Erreur lors de l\'export des dotations');
  }
};

/**
 * Fonction générique d'export Excel
 * @param {Array} data - Données à exporter
 * @param {string} filename - Nom du fichier
 * @param {string} sheetName - Nom de la feuille
 */
const exportToExcel = (data, filename, sheetName) => {
  try {
    // Créer un nouveau classeur
    const workbook = XLSX.utils.book_new();
    
    // Convertir les données en feuille de calcul
    const worksheet = XLSX.utils.json_to_sheet(data);
    
    // Ajouter la feuille au classeur
    XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
    
    // Ajuster la largeur des colonnes automatiquement
    const colWidths = [];
    const range = XLSX.utils.decode_range(worksheet['!ref']);
    
    for (let C = range.s.c; C <= range.e.c; ++C) {
      let maxWidth = 10;
      for (let R = range.s.r; R <= range.e.r; ++R) {
        const cellAddress = { c: C, r: R };
        const cellRef = XLSX.utils.encode_cell(cellAddress);
        const cell = worksheet[cellRef];
        if (cell && cell.v) {
          const cellValue = cell.v.toString();
          maxWidth = Math.max(maxWidth, cellValue.length);
        }
      }
      colWidths.push({ width: Math.min(maxWidth + 2, 50) });
    }
    worksheet['!cols'] = colWidths;
    
    // Télécharger le fichier
    XLSX.writeFile(workbook, filename);
    
    return {
      success: true,
      message: `Export ${sheetName} réussi : ${filename}`
    };
  } catch (error) {
    console.error('Erreur export Excel:', error);
    throw new Error(`Erreur lors de l'export Excel : ${error.message}`);
  }
};

/**
 * Parser des données collées depuis Excel/CSV
 * @param {string} pastedData - Données collées
 * @param {Array} expectedColumns - Colonnes attendues
 */
export const parseExcelData = (pastedData, expectedColumns = []) => {
  try {
    if (!pastedData || typeof pastedData !== 'string') {
      throw new Error('Données invalides');
    }

    // Diviser en lignes
    const lines = pastedData.trim().split('\n');
    if (lines.length === 0) {
      throw new Error('Aucune donnée trouvée');
    }

    // Traiter chaque ligne (séparateur tabulation ou point-virgule)
    const parsedData = lines.map((line, index) => {
      // Détecter le séparateur (tabulation prioritaire, puis virgule, puis point-virgule)
      let separator = '\t';
      if (!line.includes('\t')) {
        separator = line.includes(';') ? ';' : ',';
      }
      
      const cells = line.split(separator).map(cell => cell.trim().replace(/^"|"$/g, ''));
      
      return {
        rowIndex: index,
        cells: cells,
        cellCount: cells.length
      };
    });

    // Détecter si la première ligne contient des en-têtes
    const hasHeaders = parsedData.length > 1 && 
      parsedData[0].cells.some(cell => isNaN(parseFloat(cell)) && cell.length > 0);

    let headers = [];
    let dataRows = parsedData;

    if (hasHeaders) {
      headers = parsedData[0].cells;
      dataRows = parsedData.slice(1);
    } else if (expectedColumns.length > 0) {
      headers = expectedColumns;
    }

    // Convertir en objets
    const processedData = dataRows.map((row, index) => {
      const rowObject = { _originalRowIndex: index };
      
      row.cells.forEach((cell, cellIndex) => {
        const columnName = headers[cellIndex] || `Colonne_${cellIndex + 1}`;
        
        // Tentative de conversion en nombre si possible
        let value = cell;
        if (cell && !isNaN(parseFloat(cell)) && isFinite(cell)) {
          value = parseFloat(cell);
        }
        
        rowObject[columnName] = value;
      });
      
      return rowObject;
    });

    return {
      success: true,
      data: processedData,
      headers: headers,
      rowCount: processedData.length,
      message: `${processedData.length} ligne(s) traitée(s) avec succès`
    };

  } catch (error) {
    console.error('Erreur parsing données:', error);
    return {
      success: false,
      data: [],
      headers: [],
      rowCount: 0,
      error: error.message
    };
  }
};

/**
 * Formater les données pour le blanchiment
 * @param {Array} rawData - Données brutes parsées
 */
export const formatBlanchimentData = (rawData) => {
  return rawData.map(row => ({
    transactionDate: row['Date Transaction'] || row['Date'] || row['date'] || '',
    amount: parseFloat(row['Montant'] || row['Amount'] || row['montant'] || 0),
    description: row['Description'] || row['Libellé'] || row['description'] || '',
    flagged: false,
    riskLevel: 'low',
    thresholdExceeded: false,
    analysisDate: new Date().toISOString().split('T')[0],
    comments: ''
  }));
};

// Export par défaut
export default {
  exportImpots,
  exportBlanchiment,
  exportArchives,
  exportDotations,
  parseExcelData,
  formatBlanchimentData
};