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
```

Install Docker

```
docker-compose up
```

Enter Server by clicking on the link in the terminal
To enter the Notebook app, enter the password `supersave_token`

# Goals

- [x] Walddifferenz im Vergleich zum Startpunkt 2010 in Bildern visualisieren -> GeoMakie, 3 Klassen -> grün ursprünglicher Wald; blau= neuer Wald; rot = verdrängter Wald (Denis)
- [x] Durch was wird verdrängter Wald ersetzt? -> Balkendiagram
- [X] Legende (Fabi)
- [ ] Beschreibender Text (Kay)
- [X] eine nähere beispielhafte Perspektive visualisieren um Änderungen besser zu verdeutlichen (Beispiel: https://www.faszination-regenwald.de/info-center/zerstoerung/flaechenverluste/), small soy area und forestloss_region
- [X] Das ganze als persistentes build bauen, am besten mit docker der jupyter life mit Kays finalemr abgabe startet (Fabi, oder Denios wenn er zurück ist)
  - Dazu muss ein persistenter stand gepusht werden, also auch das Manifest (neuer branch release?!)
  - der jupyter server sollte sich dann im browser des hosts auf bel. port öffnen
  - kleine Anleitung schreiben in diese readme hier wie das gehen soll
  - Hintergund dazu: Er hat gesagt wichtig ist dass das ganze funktioniert und auf anderen Maschienen sicher läuft, und ich finde das ist der beste Weg 
