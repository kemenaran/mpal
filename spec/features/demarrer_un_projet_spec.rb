require 'rails_helper'
require 'support/mpal_helper'
require 'support/api_particulier_helper'
require 'support/api_ban_helper'

feature "Démarrer un projet" do
  before do
    Projet.destroy_all
    Invitation.destroy_all
    Occupant.destroy_all
  end

  scenario "depuis la page d'accueil" do
    visit root_path
    click_on I18n.t('accueil.action')
    expect(page.current_path).to eq(new_session_path)
  end

  scenario "depuis la page de connexion, je recupere mes informations principales" do
    signin(12,15)
    projet = Projet.last
    expect(page.current_path).to eq(etape1_recuperation_infos_demarrage_projet_path(projet))
    expect(page).to have_content("Martin")
    expect(page).to have_content("Pierre")
    expect(page).to have_content("12 rue de la Mare")
    expect(page).to have_content("75010")
    expect(page).to have_content("Paris")
  end

  scenario "depuis la page de connexion, je modifie l'adresse du logement à rénover" do
    signin(12,15)
    projet = Projet.last
    expect(page.current_path).to eq(etape1_recuperation_infos_demarrage_projet_path(projet))
    fill_in :adresse_logement_a_renover, with: "1 place Vendôme, 75001 Paris"
    click_button I18n.t('demarrage_projet.action')
    expect(page.current_path).to eq(etape2_description_projet_path(projet))
    projet = Projet.last
    expect(projet.adresse_ligne1).to eq("12 rue de la Mare")
    expect(projet.code_postal).to eq("75010")
    expect(projet.ville).to eq("Paris")
  end

  scenario "depuis la page de connexion, j'ajoute une personne de confiance" do
    signin(12,15)
    projet = Projet.last
    fill_in :personne_de_confiance_prenom, with: "Frank"
    fill_in :personne_de_confiance_nom, with: "Strazzeri"
    fill_in :personne_de_confiance_tel, with: "0130201040"
    fill_in :personne_de_confiance_email, with: "frank@strazzeri.com"
    fill_in :personne_de_confiance_lien_avec_demandeur, with: "Mon jazzman favori et neanmoins concubin"
    click_button I18n.t('demarrage_projet.action')
    expect(page.current_path).to eq(etape2_description_projet_path(projet))
    
    projet = Projet.last
    expect(projet.personne_de_confiance.prenom).to eq("Frank")
    expect(projet.personne_de_confiance.nom).to eq("Strazzeri")
    expect(projet.personne_de_confiance.tel).to eq("0130201040")
    expect(projet.personne_de_confiance.email).to eq("frank@strazzeri.com")
    expect(projet.personne_de_confiance.lien_avec_demandeur).to eq("Mon jazzman favori et neanmoins concubin")
  end
end
