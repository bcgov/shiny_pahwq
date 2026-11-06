# Manual tests for the Toxic Units / Hazard Index tab

Sample files and expected results for trying the tab by hand. The automated tests are in `tests/testthat/test-tu-hi.R`.

The concentrations are made up to reflect plausible levels. They are not real monitoring data.

## Sample files

| File | Scenario | PACs |
| :-- | :-- | --: |
| `background.csv` | Background | 10 |
| `urban.csv` | Urban or industrial | 12 |
| `oil-spill.csv` | Oil spill | 12 |

## Site settings

Set these on the Advanced tab. All other settings stay at their defaults.

| Setting | Freshwater site | Marine site |
| :-- | --: | --: |
| Latitude | 52.60453 | 49.15085 |
| Longitude | -105.28278 | -125.91427 |
| Elevation (m) | 515 | 0 |
| Aquatic environment | Freshwater | Marine |
| Date | 2026-06-21 | 2026-06-21 |
| Water depth (m) | 0.01 | 0.01 |
| DOC (g/m<sup>3</sup>) | 5 | Not used |

Enter the elevation after the location, because setting the location looks it up and replaces the value. The date defaults to June 21 of the current year, so results will differ slightly in other years unless it is set.

## Expected results

Rounded to 3 significant figures, as on the tab.

### Freshwater site

| File | Narcotic TUs | Phototoxic TUs | Narcotic HI | Phototoxic HI |
| :-- | --: | --: | --: | --: |
| `background.csv` | 0.00115 | 0.0493 | 0.00868 | 0.572 |
| `urban.csv` | 0.0507 | 2.15 | 0.381 | 24.9 |
| `oil-spill.csv` | 0.531 | 9.93 | 3.84 | 115 |

### Marine site

| File | Narcotic TUs | Phototoxic TUs | Narcotic HI | Phototoxic HI |
| :-- | --: | --: | --: | --: |
| `background.csv` | 0.00115 | 0.0506 | 0.00868 | 0.587 |
| `urban.csv` | 0.0507 | 2.2 | 0.381 | 25.6 |
| `oil-spill.csv` | 0.531 | 10.1 | 3.84 | 118 |

Narcotic results don't depend on the site, so they are the same in both tables.

## Steps

1. Set the site settings on the Advanced tab.
2. Open the Toxic Units (TU) / Hazard Index (HI) tab and check that the settings card matches.
3. Upload a sample file, check that it fills in the table, and press Calculate.
4. Compare the four sums with the expected results.
5. Download the results. The CSV should have one row per PAC in the sample and a `Total` row.

## Other things to check

- **Stale results:** change the depth or date on the Advanced tab and return. The results should stay the same, with a notice, until Calculate is pressed. A greater depth or a winter date should lower the phototoxic results.
- **Uploading again:** upload the same file twice, editing a value in between. The table should pick up the edit.
- **Clear:** press Clear. The table and upload status should empty, and the same file should upload again.
- **Template:** download the template, fill in some values and upload it.
- **Rejected files:** edit a copy of a sample so that a concentration is `<0.01` or `-1`, a column is renamed, or both `C1-Phenanthrenes` and `C1-Anthracenes` appear. The file should be rejected with a message, leaving the table unchanged.
- **Names not counted:** add a row with an unknown name and a value. It should upload with a notice naming it.
- **Help/About:** check that the TU and HI equations display properly.
