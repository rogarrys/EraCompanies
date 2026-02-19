--[[
    EraCompanies — Shared Configuration
    Defines the global namespace, permissions, default grades, and constants.
]]

EraCompanies = EraCompanies or {}
EraCompanies.Config = EraCompanies.Config or {}

-- ─── Company name constraints ───
EraCompanies.Config.NameMin = 3
EraCompanies.Config.NameMax = 24
EraCompanies.Config.WebURL = "https://era-companies-lur6.vercel.app/index.html"

-- ─── Business Sectors ───
EraCompanies.Config.Sectors = {
    "Commerçant",
    "Mécano",
    "Restaurateur",
    "Sécurité",
    "Transport",
    "Médical",
    "Artisan",
    "Légal",
    "Autre",
}

-- ─── Application form ───
EraCompanies.Config.MaxFormFields = 6
EraCompanies.Config.MaxFieldLabelLen = 64
EraCompanies.Config.MaxFieldAnswerLen = 256

-- ─── Anti-spam cooldown (seconds) ───
EraCompanies.Config.Cooldown = 2

-- ─── Bank ───
EraCompanies.Config.MaxBankAmount = 999999999

-- ─── Permission keys ───
EraCompanies.Permissions = {
    "invite",
    "review_apps",
    "msg_access",
    "msg_write",
    "kick",
    "promote",
    "demote",
    "set_grade",
    "edit_grades",
    "bank_deposit",
    "bank_withdraw",
    "rename_company",
}

-- Human-readable labels (French)
EraCompanies.PermissionLabels = {
    invite         = "Inviter des joueurs",
    review_apps    = "Gérer les candidatures",
    msg_access     = "Accéder à la messagerie",
    msg_write      = "Écrire des messages",
    kick           = "Expulser un membre",
    promote        = "Promouvoir un membre",
    demote         = "Rétrograder un membre",
    set_grade      = "Définir le grade d'un membre",
    edit_grades    = "Gérer les grades",
    bank_deposit   = "Déposer en banque",
    bank_withdraw  = "Retirer de la banque",
    rename_company = "Renommer l'entreprise",
}

-- ─── Default system grades ───
-- Owner gets ALL permissions, Membre gets only msg_access
EraCompanies.DefaultGrades = {
    {
        name       = "Patron",
        weight     = 1000,
        is_system  = true,
        permissions = {}, -- Owner bypasses all permission checks
    },
    {
        name       = "Membre",
        weight     = 0,
        is_system  = true,
        permissions = {"msg_access"},
    },
}
