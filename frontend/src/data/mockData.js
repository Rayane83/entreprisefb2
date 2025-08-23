export const mockUser = {
  id: 'mock-user-id',
  name: 'Jean Dupont',
  avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=32&h=32&fit=crop&crop=face',
  role: 'patron', // Can be: staff, patron, co-patron, dot, employe
  entreprise: 'LSPD',
  guild_id: '1404608015230832742'
};

export const mockUserRoles = {
  staff: { name: 'Staff', color: 'hsl(var(--badge-staff))' },
  patron: { name: 'Patron', color: 'hsl(var(--badge-patron))' },
  'co-patron': { name: 'Co-Patron', color: 'hsl(var(--badge-co-patron))' },
  dot: { name: 'DOT', color: 'hsl(var(--badge-dot))' },
  employe: { name: 'Employé', color: 'hsl(var(--badge-employe))' }
};

export const mockTaxBrackets = [
  { id: 1, min: 0, max: 50000, taux: 0.1, sal_min_emp: 5000, sal_max_emp: 15000, sal_min_pat: 8000, sal_max_pat: 25000, pr_min_emp: 0, pr_max_emp: 5000, pr_min_pat: 0, pr_max_pat: 10000 },
  { id: 2, min: 50001, max: 100000, taux: 0.15, sal_min_emp: 8000, sal_max_emp: 20000, sal_min_pat: 12000, sal_max_pat: 30000, pr_min_emp: 2000, pr_max_emp: 8000, pr_min_pat: 3000, pr_max_pat: 15000 },
  { id: 3, min: 100001, max: null, taux: 0.2, sal_min_emp: 12000, sal_max_emp: 25000, sal_min_pat: 18000, sal_max_pat: 40000, pr_min_emp: 5000, pr_max_emp: 12000, pr_min_pat: 8000, pr_max_pat: 20000 }
];

export const mockEmployees = [
  { id: 1, name: 'Pierre Martin', run: 15000, facture: 8000, vente: 12000, ca_total: 35000, salaire: 8500, prime: 2000 },
  { id: 2, name: 'Marie Dubois', run: 20000, facture: 10000, vente: 15000, ca_total: 45000, salaire: 12000, prime: 3500 }
];

export const mockDotationData = {
  solde_actuel: 150000,
  employees: mockEmployees,
  depenses: [
    { id: 1, date: '2024-01-15', justificatif: 'Fournitures bureau', montant: 2500 },
    { id: 2, date: '2024-01-20', justificatif: 'Équipement informatique', montant: 8000 }
  ],
  retraits: [
    { id: 1, date: '2024-01-10', justificatif: 'Avance salaire Pierre', montant: 5000 },
    { id: 2, date: '2024-01-25', justificatif: 'Prime exceptionnelle Marie', montant: 3000 }
  ]
};

export const mockBlanchimentRows = [
  {
    id: '1',
    statut: 'En cours',
    date_recu: '2024-01-15',
    date_rendu: null,
    duree: null,
    groupe: 'Alpha',
    employe: 'Jean Dupont',
    donneur_id: '123456',
    recep_id: '789012',
    somme: 50000,
    entreprise_perc: 15,
    groupe_perc: 5
  },
  {
    id: '2',
    statut: 'Terminé',
    date_recu: '2024-01-10',
    date_rendu: '2024-01-20',
    duree: 10,
    groupe: 'Beta',
    employe: 'Marie Martin',
    donneur_id: '345678',
    recep_id: '901234',
    somme: 75000,
    entreprise_perc: 15,
    groupe_perc: 5
  }
];

export const mockArchives = [
  {
    id: '1',
    type: 'Dotation',
    date: '2024-01-15',
    montant: 125000,
    statut: 'En attente',
    entreprise_key: 'LSPD',
    payload: {
      employees: mockEmployees,
      totals: { ca: 80000, salaires: 20500, primes: 5500 },
      solde_actuel: 150000
    }
  },
  {
    id: '2',
    type: 'Impôt',
    date: '2024-01-10',
    montant: 25000,
    statut: 'Validé',
    entreprise_key: 'LSPD',
    payload: {
      revenus: 250000,
      taux: 0.1
    }
  }
];

export const mockDiscordConfig = {
  principalGuildId: '1404608015230832742',
  dot: {
    guildId: '1404608015230832742'
  },
  enterprises: [
    { key: 'LSPD', name: 'Los Santos Police Department', guildId: '1404608015230832742', role_id: '123456', employee_role_id: '789012' },
    { key: 'EMS', name: 'Emergency Medical Services', guildId: '1404608015230832742', role_id: '234567', employee_role_id: '890123' }
  ]
};

export const mockEnterprises = [
  { id: '1', guild_id: '1404608015230832742', key: 'LSPD', name: 'Los Santos Police Department', role_id: '123456', employee_role_id: '789012' },
  { id: '2', guild_id: '1404608015230832742', key: 'EMS', name: 'Emergency Medical Services', role_id: '234567', employee_role_id: '890123' }
];