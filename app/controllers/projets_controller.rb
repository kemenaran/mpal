class ProjetsController < ApplicationController
  def edit
    @projet = Projet.find(params[:id])
  end

  def update
    @projet = Projet.find(params[:id])
    @projet.assign_attributes(projet_params)
    if @projet.save
      redirect_to @projet
    else
      render :edit
    end
  end

  def show
    @projet = Projet.find(params[:id])
    if session[:numero_fiscal] != @projet.numero_fiscal
      redirect_to new_session_path, alert: t('sessions.access_forbidden')
    else
      gon.push({
        latitude: @projet.latitude,
        longitude: @projet.longitude
      })
      @profil = @projet.usager
      @intervenants_departement = Intervenant.pour_departement(@projet.departement) - @projet.intervenants
    end
  end

  private
  def projet_params
    service_adresse = ApiBan.new
    adresse = service_adresse.precise(params[:projet][:adresse])
    attributs = params.require(:projet).permit(:description, :email, :tel)
    attributs = attributs.merge(adresse) if adresse
    attributs
  end
end
