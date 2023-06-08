# Rainforest Development

This project attempts to document the development of the world's rainforests in a differentiated way since 2010.


## Underlying Data Sources

Land Cover Data Cube
https://deepesdl.readthedocs.io/en/latest/datasets/LC-1x2160x2160-1-0-0-zarr/

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
ZARR_PATH=https://s3.eu-central-1.amazonaws.com/deep-esdl-public/LC-1x2160x2160-1.0.0.zarr
```

ich mache meinen commit