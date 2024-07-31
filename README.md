# nextflow_modules

A collection of Ensembl shared Nextflow modules. 
- For use across teams.
- See: https://nf-co.re/docs/nf-core-tools/custom_remotes
- Modules shared here should adhere to:
	- be sensible 
	- process should be precise in its scope 
	- should not share private information
	- self contained i.e. destinct input/output
	- modules names should be clear and relate to function
	- Modules should try to have tags linked to unique ID, and ideally have first input as a tuple. 
		- See here: https://nf-co.re/docs/contributing/components/meta_map
		- We expect to have a 'meta map' as first value of the tuple.
	```
	process SOME_MODULE{
		tag "$meta.accession"
	...
	}
	```


E.g of install
```
nf-core modules --git-remote git@github.com:Ensembl/nextflow_modules.gi install tool/subtool
nf-core subworkflows --git-remote git@github.com:Ensembl/nextflow_modules.git install tool/subtool
```
