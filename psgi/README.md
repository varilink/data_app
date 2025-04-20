# DATA - App

## PSGI Scripts

This directory contains the web application's Perl Web Server Gateway Interface (PSGI) scripts. We use the micro Web Server Gateway Interface application server, uWSGI, which supports Perl via a PSGI compliant interface.

There are two PSGI scripts in this directory as follows:

| Script            | Description                        |
| ----------------- | ---------------------------------- |
| `data-app.psgi`   | Main application PSGI script.      |
| `data-image.psgi` | Script for handling image uploads. |
