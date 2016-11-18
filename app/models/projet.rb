class Projet < ActiveRecord::Base

  enum statut: [ :prospect, :en_cours, :transmis_pour_instruction, :en_cours_d_instruction ]
  has_one :personne_de_confiance, class_name: "Personne", foreign_key: "projet_id"
  accepts_nested_attributes_for :personne_de_confiance
  has_one :demande
  has_many :intervenants, through: :invitations
  has_many :invitations, dependent: :destroy
  belongs_to :operateur, class_name: 'Intervenant'
  has_many :evenements, -> { order('evenements.quand DESC') }, dependent: :destroy
  has_many :occupants, dependent: :destroy
  has_many :commentaires, -> { order('created_at DESC') }, dependent: :destroy
  has_many :avis_impositions, dependent: :destroy
  has_many :documents, dependent: :destroy

  has_many :projet_aides, dependent: :destroy
  has_many :aides, through: :projet_aides

  validates :numero_fiscal, :reference_avis, :adresse_ligne1, presence: true
  validates_numericality_of :nb_occupants_a_charge, greater_than_or_equal_to: 0, allow_nil: true

  has_many :projet_prestations, dependent: :destroy

  def nb_total_occupants
    nb_occupants = self.occupants.count || 0
    return nb_occupants + self.nb_occupants_a_charge
  end

  def intervenants_disponibles(role: nil)
    Intervenant.pour_departement(self.departement).pour_role(role) - self.intervenants
  end

  def demandeur_principal
    self.occupants.where(demandeur: true).first
  end

  def usager
    occupant = self.demandeur_principal
    occupant.to_s if occupant
  end

  def calcul_revenu_fiscal_reference_total(annee)
    total_revenu_fiscal_reference = 0
    avis_impositions.where(annee: annee).each do |avis_imposition|
      contribuable = ApiParticulier.new.retrouve_contribuable(avis_imposition.numero_fiscal, avis_imposition.reference_avis)
      total_revenu_fiscal_reference += contribuable.revenu_fiscal_reference
    end
    total_revenu_fiscal_reference
  end


  def preeligibilite(annee)
    Tools.calcule_preeligibilite(calcul_revenu_fiscal_reference_total(annee), self.departement, self.nb_total_occupants)
  end

  def transmettre!(instructeur)
    invitation = Invitation.new(projet: self, intermediaire: self.operateur, intervenant: instructeur)
    if invitation.save
      ProjetMailer.mise_en_relation_intervenant(invitation).deliver_later!
      EvenementEnregistreurJob.perform_later(label: 'transmis_instructeur', projet: self, producteur: invitation)
      self.statut = :transmis_pour_instruction
      return self.save
    end
    false
  end

  def adresse
    "#{self.adresse_ligne1}, #{self.code_postal} #{self.ville}"
  end

  def nom_occupants
    self.occupants.map(&:nom).map{|n| n.upcase}.join(' ET ')
  end

  def prenom_occupants
    self.occupants.map(&:prenom).map{|n| n.capitalize}.join(' et ')
  end
end
