# Ensembl Nextflow modules

**`nextflow_modules`** is a centralized repository for reusable Nextflow modules, designed to be shared across multiple pipelines. This approach simplifies maintenance and updates by consolidating modules in one location. The repository adheres to the [nf-core structure](https://nf-co.re/docs/contributing/pipelines/pipeline_file_structure) and follows Nextflow's coding conventions, ensuring consistency and compatibility with established standards.

---

## Purpose

A collection of shared Nextflow modules for Ensembl teams:  
- **Facilitates collaboration** by providing reusable components across teams.  
- **Simplifies module usage** with tools like `nf-core modules` and `nf-core subworkflows`.  
- **Avoid Duplication** of effort by sharing modules.

### Example Usage
```bash
nf-core modules --git-remote git@github.com:Ensembl/nextflow_modules.git install tool/subtool
nf-core subworkflows --git-remote git@github.com:Ensembl/nextflow_modules.git install tool/subtool
```

### Initial Setup
The repository contains a *pre-defined structure (see above)* with some example modules to serve as templates.

### Steps for Adding New Modules
1. Check Existing Modules
   
	Verify if the required module is already available in nf-core modules and can be directly used.

2. Create a New Module
   
	Use `nf-core modules create` to generate a module template.

	```bash
	nf-core modules create tool/subtool --author '@ensembl-dev' --label process_low --meta
	```

	> _Note:_ Module names must only contain lowercase letters and we must not use the same name for another module. Names with non-lowercase letters (e.g., database/db-factory) will automatically be converted (e.g., database/dbfactory).

3. Add Module Testing
   
	Install **`nf-test`** and create nf-test for testing using stub data. If required utilize data from [test-datasets](https://github.com/nf-core/test-datasets/tree/modules/data) and update the path in the [test_config](https://github.com/Ensembl/nextflow_modules/blob/main/tests/config/test_data.config).

	> _Note:_ We have only added minimum tests. You should add more tests as per your module's functionality.

4. Update Metadata
   
	Add relevant information in the `meta.yml` file.

### Module Guidelines
Modules in the repository should:

- Be sensible and scoped to a specific purpose.
- Be scoped to run only a single tool or functionality.
- Avoid sharing private information.
- Be self-contained, with distinct input and output.
- Have clear and descriptive names that reflect their functionality.
- Include tags linked to unique IDs and ideally have the first input as a tuple.

	```bash
	process SOME_MODULE {
    	    tag "$meta.id"
 	   ...
	}
	```
	Refer to the [Meta Map Documentation](https://nf-co.re/docs/contributing/components/meta_map) for additional details.
