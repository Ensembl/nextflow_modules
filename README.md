# nextflow_modules

**`nextflow_modules`** is a centralized repository for reusable Nextflow modules, designed to be shared across multiple pipelines. This approach simplifies maintenance and updates by consolidating modules in one location. The repository adheres to the **nf-core structure** and follows Nextflow's coding conventions, ensuring consistency and compatibility with established standards.

---

## Purpose

A collection of shared Nextflow modules for EBI teams:  
- **Facilitates collaboration** by providing reusable components across teams.  
- **Avoid Duplication** of effort by sharing modules.
- **Simplifies module usage** with tools like `nf-core modules` and `nf-core subworkflows`.  

### Example Usage
```bash
nf-core modules --git-remote git@github.com:Ensembl/nextflow_modules.git install tool/subtool
nf-core subworkflows --git-remote git@github.com:Ensembl/nextflow_modules.git install tool/subtool
```

### Initial Setup
The repository contains a pre-defined structure with some example modules to serve as templates.

### Steps for Adding New Modules
1. Check Existing Modules
   
	Verify if the required module is already available in nf-core modules and can be directly used.

1. Create a New Module```bash
Use nf-core modules create to generate a module template.

	```bash
	nf-core modules create tool/subtool --author '@ensembl-dev' --label process_low --meta
	```

	Note: Module names must only contain lowercase letters. Names with non-lowercase letters (e.g., database/db-factory) will automatically be converted (e.g., database/dbfactory).

1. Add Module Testing
   
	Install **`nf-test`** and create nf-test for testing using stub data.
Utilize data from test-datasets and update the path in the test_config.

1. Update Metadata
   
	Add relevant information in the meta.yml file.

### Module Guidelines
Modules in the repository should:

- Be sensible and scoped to a specific purpose.
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
	Refer to the Meta Map Documentation for additional details.
