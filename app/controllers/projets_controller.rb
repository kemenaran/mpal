class ProjetsController < ApplicationController

  def edit
  end

  def update
    @projet_courant.assign_attributes(projet_params)
    if @projet_courant.save
      redirect_to @projet_courant
    else
      render :edit
    end
  end

  def show
    gon.push({
      latitude: @projet_courant.latitude,
      longitude: @projet_courant.longitude
    })
    case @role_utilisateur
      when :demandeur; @intervenants_disponibles = @projet_courant.intervenants_disponibles(role: :pris)
      when :intervenant; @intervenants_disponibles = @projet_courant.intervenants_disponibles(role: :operateur)
    end
    @commentaire = Commentaire.new(projet: @projet_courant)
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
