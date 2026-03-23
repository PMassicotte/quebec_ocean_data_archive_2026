# Bonnes pratiques en gestion des données — Québec-Océan 2026

Présentation [Quarto Reveal.js](https://quarto.org/docs/presentations/revealjs/) sur les bonnes pratiques en gestion des données, avec un accent sur la reproductibilité, la réutilisabilité et l'ouverture des données de recherche.

## Aperçu

- **Présentateur :** Philippe Massicotte, Université Laval
- **Date :** 25 mars 2026
- **Événement :** Atelier Québec-Océan

## Prérequis

Ce projet utilise [Nix](https://nixos.org/) pour fournir un environnement de développement entièrement reproductible, incluant R et tous les paquets nécessaires.

```bash
nix develop
```

## Générer la présentation

```bash
quarto render index.qmd
```

La présentation générée sera disponible dans le répertoire `_site/`.

## Structure du projet

```
├── index.qmd          # Source principale de la présentation
├── flake.nix          # Environnement de développement Nix
├── style/             # Thème SCSS personnalisé
├── data/              # Jeux de données exemples
├── img/               # Images et logos
└── _extensions/       # Extensions Quarto
```
