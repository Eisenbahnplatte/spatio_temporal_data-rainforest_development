# Rainforest Development

This project attempts to document the development of South America's rainforests in a differentiated way since 2010.

## Setup

### 1. Requirements

**Docker:** v20.10 or higher

### 2. Setup your environment

1. **Clone the repository**
```bash
git clone git@github.com:Eisenbahnplatte/spatio_temporal_data-rainforest_development.git
```

2. **Start the Jupiter Server**

```
cd spatio_temporal_data-rainforest_development 
docker-compose up
```

3. **Enter Server**
- by clicking on the link in the terminal
- to enter the Notebook app, type the password `supersave_token`

1. **Open Jupyter Notebook**
- open `final_notebook.ipynb` and execute command by command
   

## Underlying Data Sources

Land Cover Data Cube: https://s3.eu-central-1.amazonaws.com/deep-esdl-public/LC-1x2160x2160-1.0.0.levels/5.zarr
(levels from 0 to 5 possible, can be selected in the first command of final_notebook.ipynb)