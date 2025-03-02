<!-- Add a project state badge
See https://github.com/BCDevExchange/Our-Project-Docs/blob/master/discussion/projectstates.md
If you have bcgovr installed and you use RStudio, click the 'Insert BCDevex Badge' Addin. -->
[![img](https://img.shields.io/badge/Lifecycle-Experimental-339999)](https://github.com/bcgov/repomountie/blob/master/doc/lifecycle-badges.md)

# pacwq_shiny

This repository contains code for a Shiny App for calculating water quality
guidelines for phototoxic polycyclic aromatic compounds (PACs). It relies
on the [pahwq](https://bcgov.github.io/pahwq) package for the calculations.

### Instructions

To run the app locally, first install the app:

```r
devtools::install_github("bcgov/shiny_pahwq")
```

Then run the app:

```r
pacwq.shiny:::run_app()
```

#### Deploying the app

Stop the running app, then run:

```r
rsconnect::deployApp()
```

### Project Status

This project is currently under active development.

### Getting Help or Reporting an Issue

To report bugs/issues/feature requests, please file an [issue](https://github.com/bcgov/shiny_pahwq/issues/).

### How to Contribute

If you would like to contribute, please see our [CONTRIBUTING](CONTRIBUTING.md) guidelines.

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

### License

```
Copyright 2024 Province of British Columbia

Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and limitations under the License.
```

---
*This project was created using the [bcgovr](https://github.com/bcgov/bcgovr) package.*
