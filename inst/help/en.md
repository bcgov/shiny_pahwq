This calculator implements the [Phototoxic Target Lipid Model](https://doi.org/10.1002/etc.3601) (PTLM) for the calculation of draft Canadian Water Quality Guidelines for Polycyclic Aromatic Compounds (PAC).

It relies on the [pacwq](https://bcgov.github.io/pahwq) R package, which uses the [Tropospheric Ultraviolet and Visible (TUV) Radiation Model](https://github.com/NCAR/TUV) (Madronich 2021) to calculate the light penetration through water of a given depth at a given location and date, with a specified attenuation coefficient.
This coefficient can be calculated from a Dissolved Organic Carbon concentration.
The light exposure is then used (along with the PAC-specific molar absorption across a range of wavelengths), to calculate the light absorption ($P_{abs}$) of the given PAC at that location.
This is then used to determine the short-term phototoxic guideline of the PAC under those conditions.

By default, the app will run the TUV model for 24 hours on the given day, with one irradiance calculation per hour at each wavelength.
When calculating $P_{abs}$, total light absorption by the given chemical is multiplied by 2 as the standard exposure is 48h for determining the narcotic and phototoxic short-term guidelines.

### Simple and Advanced tabs

Both tabs calculate guidelines for a chemical at a location.
The latitude, longitude, aquatic environment, DOC and chemical carry over when you switch between them.

#### Simple

The Simple tab needs only a location, an aquatic environment, a DOC concentration (freshwater only) and a chemical.
It always uses June 21 of the current year, a water depth of 1 cm, and the default TUV settings described below.
Because of the date, marine water always uses the summer model, and results can shift very slightly from year to year.

#### Advanced

The Advanced tab starts with the same settings as the Simple tab, and every input can be changed, including elevation, date, timezone, water depth, $k_d(\lambda_{ref})$ and $S_k$.
It also shows the TUV results and run parameters, the DOC and depth sensitivity analysis, and the marine model used.
Settings that only exist in the Advanced tab do not affect the Simple tab.

### Toxic Units (TU) and Hazard Index (HI)

This tab calculates narcotic and phototoxic TUs and HIs for a monitoring sample from one site.
The site settings are shown at the top of the tab and should be set to match the sample.
The location, aquatic environment and DOC can be changed on the Simple or Advanced tab, and all other settings on the Advanced tab.

Enter the concentrations (μg/L) or upload them as a CSV file with the columns `pac` and `concentration_ug_L`.
The template has a row for each PAC.
An uploaded file replaces all of the values in the table, which can then be edited.
Blank cells count as 0.
If you substitute a value for non-detects, such as half the detection limit, enter that value.
If the compounds in a homologue group, such as C1-Phenanthrenes/Anthracenes, were reported separately, add their concentrations together and enter the total.

For each PAC, a TU is the concentration divided by the short-term guideline, and an HI is the concentration divided by the long-term guideline.
The results for the sample are the sums over all PACs:

<!-- math in raw html blocks so panache markdown formatter doesn't mess them up -->

```{=html}
$$
  TU
  = \sum_{i=1}^{n}{\text{concentration}_i \over \text{short-term guideline}_i}
  \qquad
  HI = \sum_{i=1}^{n}{\text{concentration}_i \over \text{long-term guideline}_i}
$$
```

### Inputs

#### Location and Date

These determine the location and date for which the TUV model is run to determine irradiance.
The date can be changed in the Advanced tab.

Location is determined by entering latitude and longitude, or by clicking a location on the map.
Elevation is looked up from the location using Natural Resources Canada's [Elevation API](https://natural-resources.canada.ca/science-data/data-analysis/geospatial-data-tools-services/elevation-api).
It can be entered manually in the Advanced tab.

The aquatic environment is selected from the location: marine if it is within one of the marine areas described below, and freshwater otherwise.
It can be changed manually, and is selected again when the location changes.
In marine water, elevation is set to 0 m.

#### Water parameters

These determine the light attenuation through the water at a given depth.
Light attenuation at each wavelength ($k_d(\lambda)$) is calculated from the attenuation coefficient at a reference wavelength ($k_d(\lambda_{ref})$) and the slope of its decrease with wavelength ($S_k$):

```{=html}
$$
  k_d(\lambda) = k_d(\lambda_{ref})e^{-S_k(\lambda-\lambda_{ref})}
$$
```

##### Freshwater

The attenuation coefficient at 305 nm is calculated from the Dissolved Organic Carbon (DOC) concentration using the following equation from [CCME (20XX)], with $S_k = 0.018$ nm<sup>-1</sup>:

```{=html}
$$
  k_{d,305} = a_{305}[DOC]^{b_{305}} + 0.13;
  a_{305} = 1.28 \text{ and } b_{305} = 1.31
$$
```

DOC must be between 0.2 and 61.5 g/m<sup>3</sup>.
A value outside this range is replaced by the nearest limit, and a notice is shown.

Instead of DOC, you can supply $k_d(\lambda_{ref})$ and the reference wavelength at which it was measured in the 'Other TUV parameters' section of the Advanced tab, and $S_k$ can be changed there too.
The default water depth is 0.01 m, which can also be changed in the Advanced tab.

##### Marine water

Light attenuation is calculated from models of $\log_{10}(k_d)$ as a linear function of wavelength, derived from satellite observations for 21 areas: Canada's marine ecoregions, divided into clear and turbid water.
There is a model for each area and season (winter: December to February, spring: March to May, summer: June to August, fall: September to November).
The area is selected from the location and the season from the date.
The areas are shown on the map when marine water is selected.
DOC is not used.

The models are expressed in the form above with a reference wavelength of 375 nm.
They were fitted to visible wavelengths (up to 490 or 555 nm, depending on the area and season) and are extrapolated to shorter wavelengths, down to 280 nm.

- If the location is outside the marine areas, the nearest area within 25 km is used.
  Further away, there is no model.
- Some Arctic areas have no model in winter, as there were no data.
- A warning is shown when a model was derived from data with fewer than 10% valid pixels across the area or over time, as it may not be reliable.
- $k_d(\lambda_{ref})$ and $S_k$ can each be set in the 'Other TUV parameters' section of the Advanced tab to override the model.

In the Advanced tab, the model used is shown with the results, and included in the TUV run parameters and the TUV results download.

#### Other TUV parameters

Irradiance is calculated from 280 to 500 nm by default.
Ozone column and aerosol optical depth are looked up from historic climatology based on the date and location entered.

##### Ozone column (DU)

The app uses monthly ozone column data from 1980-1991 from Fortuin and Kelder (1998), which is bundled with the TUV model.
Based on latitude and longitude and month, the ozone column value is looked up and supplied to the TUV model.
It can be supplied manually in the Advanced tab to override this behaviour.

##### Aerosol optical depth

The app uses average monthly aerosol optical depth data from 2002 to 2023, obtained from NASA MODIS/Aqua satellite data, aggregated to 1 degree latitude and longitude resolution.
If no value is available for a given month, latitude, and longitude, a default value of 0.235 is used.
It can be supplied manually in the Advanced tab to override this behaviour.

### References

[CCME 20XX.
Scientific Criteria Document for the development of the Canadian Water Quality Guidelines for the protection of aquatic life: Polycyclic Aromatic Compounds (PACs) (DRAFT)]

Madronich, S. 2021.
Tropospheric Ultraviolet and Visible Radiation Model (TUV).
Retrieved from: <https://www2.acom.ucar.edu/modeling/tropospheric-ultraviolet-and-visible-tuv-radiation-model>

Paul, J., F.
Fortuin, and H.
Kelder (1998), An ozone climatology based on ozonesonde and satellite measurements, J.
Geophys.
Res., 103(D24), 31709-31734, doi:[10.1029/1998JD200008.](https://doi.org/10.1029/1998JD200008)
