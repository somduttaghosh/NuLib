!-*-f90-*-
function single_neutrino_emissivity_from_epannhil_given_energyrange( &
     neutrino_species,range_bottom,range_top,eos_variables) result(emissivity)
  
  !taken from BRT06, Bruenn1985 and Pons 1998
  use nulib
  implicit none

  !inputs
  real*8, intent(in) :: eos_variables(total_eos_variables)
  integer, intent(in) :: neutrino_species !one of six, each have different coupling constants
  real*8, intent(in) :: range_bottom !MeV, lower energy of integral
  real*8, intent(in) :: range_top !MeV, upper energy of integral
  
  !output
  real*8 :: emissivity !total emissivity in MeV/cm^3/s

  !function declarations
  real*8 :: epannhil_dQdenu_BRT06
  real*8 :: fermidirac_dimensionless

  !local, GPQ variables
  integer :: i
  real*8 :: nu_energy,nu_energy_x,eta
  real*8 :: range_top_x, range_bottom_x
  real*8 :: preamble

  preamble = 8.0d0*pi**2/(2.0d0*pi*hbarc_mevcm)**6*eos_variables(tempindex)**9*mev_to_erg* &
       Gfermi**2*hbarc_mevcm**2*clight/pi !units (MeV*cm)^-6 * MeV^9 * erg*MeV^-1 * MeV^-4 (MeV*cm)^2 * cm*s^-1 = erg/cm^3/s
  
  range_top_x = range_top/eos_variables(tempindex)
  range_bottom_x = range_bottom/eos_variables(tempindex)
  eta = eos_variables(mueindex)/eos_variables(tempindex)

  emissivity = 0.0d0
  do i=1,4
     nu_energy_x = (range_top_x-range_bottom_x)/2.0d0*GPQ_n4_roots(i)+(range_top_x+range_bottom_x)/2.0d0
     emissivity = emissivity + &
          epannhil_dQdenu_BRT06(nu_energy_x,eta,neutrino_species)* &
          GPQ_n4_weights(i)*nu_energy_x**3
  end do

  emissivity = preamble*emissivity*(range_top_x-range_bottom_x)/ &
       (2.0d0*(range_top-range_bottom)*4.0d0*pi) !ergs/cm^3/s/MeV/srad

end function single_neutrino_emissivity_from_epannhil_given_energyrange

!we do the simpliest thing possible here (BRT06+approximations)
!should improve to include arbitrary degeneracy and better integration (i.e. no BRT06 fits)
function single_neutrino_emissivity_from_NNBrem_given_energyrange( &
     neutrino_species,range_bottom,range_top,eos_variables) result(emissivity)

  use nulib
  implicit none

  !inputs
  real*8, intent(in) :: eos_variables(total_eos_variables)
  integer, intent(in) :: neutrino_species !one of six, each may have different coupling constants
  real*8, intent(in) :: range_bottom !MeV, lower energy of integral
  real*8, intent(in) :: range_top !MeV, upper energy of integral
  
  !output
  real*8 :: emissivity !total emissivity in MeV/cm^3/s

  !function declarations
  !real*8 :: NNBrem_dQdenu_BRT06 ! do not yet need this, but should improve emissivity, so will

  !local, GPQ variables
  integer :: i
  real*8 :: nu_energy,nu_energy_x,eta
  real*8 :: range_top_x, range_bottom_x
  real*8 :: preamble_1,preamble_2

  !this is the total emission rate, with fix from Adam
  preamble_1 = 2.0778d30*0.5d0*(eos_variables(xnindex)**2+eos_variables(xpindex)**2+eos_variables(xnindex)*eos_variables(xpindex)*28.0d0/3.0d0)* &
       (eos_variables(rhoindex)/1.0d14)**2*eos_variables(tempindex)**5.5d0 !erg/cm^3/s
  preamble_2 = 0.234d0

  range_top_x = range_top/eos_variables(tempindex)
  range_bottom_x = range_bottom/eos_variables(tempindex)
  eta = eos_variables(mueindex)/eos_variables(tempindex)

  emissivity = 0.0d0
  do i=1,4
     nu_energy_x = (range_top_x-range_bottom_x)/2.0d0*GPQ_n4_roots(i)+(range_top_x+range_bottom_x)/2.0d0
     emissivity = emissivity + nu_energy_x**2.4d0*exp(-1.1d0*nu_energy_x)*GPQ_n4_weights(i)
  end do

  emissivity = preamble_1*preamble_2*emissivity*(range_top_x-range_bottom_x)/ &
       (2.0d0*(range_top-range_bottom)*4.0d0*pi) !ergs/cm^3/s/MeV/srad

end function single_neutrino_emissivity_from_NNBrem_given_energyrange

subroutine total_emissivities(neutrino_species,energy_bottom,energy_top, &
    total_emissivity,eos_variables)

  use nulib
  implicit none

  !inputs
  real*8, intent(in) :: eos_variables(total_eos_variables)
  integer, intent(in) :: neutrino_species  !integer 1 through 6
  real*8, intent(in) :: energy_bottom,energy_top !MeV
  
  !outputs
  real*8, intent(out) :: total_emissivity !ergs/cm^-3/s/MeV/srad

  !function declarations
  real*8 :: single_neutrino_emissivity_from_epannhil_given_energyrange
  real*8 :: single_neutrino_emissivity_from_NNBrem_given_energyrange

  total_emissivity = 0.0d0

  if (neutrino_species.eq.1) then
     !add in the electron neutrino emission from ep annihilation
     if (add_nue_emission_epannihil) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_epannhil_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif

     !add in the electron neutrino emission from Nucleon-Nucleon bremsstrahlung
     if (add_nue_emission_NNBrems) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_NNBrem_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif
  endif
     
  if (neutrino_species.eq.2) then
     !add in the electron antineutrino emission from ep annihilation
     if (add_anue_emission_epannihil) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_epannhil_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif

     !add in the electron antineutrino emission from Nucleon-Nucleon bremsstrahlung
     if (add_anue_emission_NNBrems) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_NNBrem_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif
  endif
     
  if (neutrino_species.eq.3) then     
     !add in the mu neutrino emission from ep annihilation
     if (add_numu_emission_epannihil) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_epannhil_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif

     !add in the mu neutrino emission from Nucleon-Nucleon bremsstrahlung
     if (add_numu_emission_NNBrems) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_NNBrem_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif
  endif
     
  if (neutrino_species.eq.4) then     
     !add in the mu antineutrino emission from ep annihilation
     if (add_anumu_emission_epannihil) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_epannhil_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif

     !add in the mu antineutrino emission from Nucleon-Nucleon bremsstrahlung
     if (add_anumu_emission_NNBrems) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_NNBrem_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif
  endif
     
  if (neutrino_species.eq.5) then     
     !add in the tau neutrino emission from ep annihilation
     if (add_nutau_emission_epannihil) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_epannhil_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif

     !add in the tau neutrino emission from Nucleon-Nucleon bremsstrahlung
     if (add_nutau_emission_NNBrems) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_NNBrem_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif
  endif
     
  if (neutrino_species.eq.6) then     
     !add in the tau antineutrino emission from ep annihilation
     if (add_anutau_emission_epannihil) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_epannhil_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif

     !add in the tau antineutrino emission from Nucleon-Nucleon bremsstrahlung
     if (add_anutau_emission_NNBrems) then
        total_emissivity = total_emissivity + & !total emmissivity, dimensions ergs/cm^3/s/MeV/srad
             single_neutrino_emissivity_from_NNBrem_given_energyrange( &
             neutrino_species,energy_bottom,energy_top,eos_variables) !
     endif
  endif
     
end subroutine total_emissivities

subroutine return_emissivity_spectra_given_neutrino_scheme(emissivity_spectra,eos_variables)

  use nulib
  implicit none
  
  !inputs & outputs
  real*8, intent(in) :: eos_variables(total_eos_variables)
  real*8, intent(out) :: emissivity_spectra(number_species,number_groups)  !ergs/cm^3/s/MeV/srad
  
  !locals
  integer :: ns,ng
  real*8 emissivity,energy_top,energy_bottom
  real*8 :: eta

  !function dec
  real*8 :: get_fermi_integral
  
  if (size(emissivity_spectra,1).ne.number_species) then
     stop "return_emissivity_spectra_given_neutrino_scheme:provided array has wrong number of species"
  endif
  if (size(emissivity_spectra,2).ne.number_groups) then
     stop "return_emissivity_spectra_given_neutrino_scheme:provided array has wrong number of groups"
  endif
  
  do ns=1,number_species
     do ng=1,number_groups
        energy_bottom = bin_bottom(ng)
        energy_top = bin_top(ng)
        call total_emissivities(ns,energy_bottom,energy_top,emissivity,eos_variables)
        emissivity_spectra(ns,ng) = emissivity !ergs/cm^3/s/MeV/srad
     enddo
  enddo
  
end subroutine return_emissivity_spectra_given_neutrino_scheme