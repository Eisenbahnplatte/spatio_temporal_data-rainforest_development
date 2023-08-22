# Rainforest Development

This project attempts to document the development of the world's rainforests in a differentiated way since 2010.


## Underlying Data Sources

Land Cover Data Cube
https://deepesdl.readthedocs.io/en/latest/datasets/LC-1x2160x2160-1-0-0-zarr/
https://s3.eu-central-1.amazonaws.com/deep-esdl-public/LC-1x2160x2160-1.0.0.levels/5.zarr

Earth System Data Cube
https://deepesdl.readthedocs.io/en/latest/datasets/ESDC/

## Setup

### 1. Setup your environment

Download repo and create `.env` file:

```bash
git clone git@github.com:Eisenbahnplatte/spatio_temporal_data-rainforest_development.git # clone the repository
cd spatio_temporal_data-rainforest_development 
vim .env
```

Content of the `.env` file:

```bash
# this path refers to a (preferably local) instance of the loaded ZARR dataset. URL also possible
ZARR_PATH=https://s3.eu-central-1.amazonaws.com/deep-esdl-public/LC-1x2160x2160-1.0.0.levels/5.zarr
```

important! code works only with YAXArrays v0.4.6

# Goals

- [x] Walddifferenz im Vergleich zum Startpunkt 2010 in Bildern visualisieren -> GeoMakie, 3 Klassen -> grün ursprünglicher Wald; blau= neuer Wald; rot = verdrängter Wald (Denis)
- [x] Durch was wird verdrängter Wald ersetzt? -> Balkendiagram
- [ ] Legende (Fabi)
- [ ] Beschreibender Text (Kay)
- [ ] eine nähere beispielhafte Perspektive visualisieren um Änderungen besser zu verdeutlichen (Beispiel: https://www.faszination-regenwald.de/info-center/zerstoerung/flaechenverluste/) 
