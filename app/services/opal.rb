class Opal
  def initialize(client)
    @client = client
  end

  def creer_dossier(projet, agent_instructeur)
    response = @client.post('/createDossier', body: convertit_projet_en_dossier(projet, agent_instructeur).to_json, verify: false)
    if response.code == 201
      ajoute_id_opal(projet, response.body)
      met_a_jour_statut(projet)
      projet.agent_instructeur = agent_instructeur
      projet.save
    else
      puts "Error: Opal /createDossier failed with #{response}"
      false
    end
  end

  def ajoute_id_opal(projet, reponse)
    opal = JSON.parse(reponse)
    projet.opal_numero = opal["dosNumero"]
    projet.opal_id = opal["dosId"]
  end

  def met_a_jour_statut(projet)
    projet.statut = :en_cours_d_instruction
  end

  def convertit_projet_en_dossier(projet, agent_instructeur)
    {
      "dosNumeroPlateforme": "#{projet.numero_plateforme}",
      "dosDateDepot": Time.now.strftime("%Y-%m-%d"),
      "utiIdClavis": agent_instructeur.clavis_id,
      "demandeur": {
        "dmdNbOccupants": projet.nb_total_occupants,
        "dmdRevenuOccupants": projet.revenu_fiscal_reference_total,
        "qdmId": 29,
        "cadId": 2,
        "personnePhysique": {
          "civId": 4,
          "pphNom": projet.nom_occupants,
          "pphPrenom": projet.prenom_occupants,
          "adressePostale": {
            "payId": 1,
            "adpLigne1": projet.adresse_ligne1,
            "adpLocalite": projet.ville,
            "adpCodePostal": projet.code_postal
          }
        }
      },
      "immeuble": {
        "immAnneeAchevement": projet.annee_construction || 0,
        "ntrId": 1,
        "immSiArretePeril": false,
        "immSiGrilleDegradation": false,
        "immSiInsalubriteAveree": false,
        "immSiDejaSubventionne": false,
        "immSiProcedureInsalubrite": false,
        "adresseGeographique": {
          "adgLigne1": projet.adresse_ligne1,
          "cdpCodePostal": projet.code_postal,
          "comCodeInsee": recupere_com_code_insee(projet),
          "dptNumero": projet.departement
        }
      }
    }
  end

  def recupere_com_code_insee(projet)
    projet.code_insee[2, projet.code_insee.length]
  end
end
