process URLS_GENERATE {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), val(protocol), val(user), val(host), val(port), val(password), val(database)

    output:
    tuple val(meta), env(base_url) , emit: url_sql
    path "versions.yml"           , emit: versions

    script:

    """
    protocol="${protocol}"
    user="${user}"
    host="${host}"
    port="${port}"
    password="${password}"
    database="${database}"

    # Start constructing the URL
    base_url="\${protocol}://\${user}@\${host}:\${port}"

    # Add password if it is not an empty string
    if [ "\$password" != "" ]; then
        base_url="\${protocol}://\${user}:\${password}@\${host}:\${port}"
    fi

    # Add database if it is not an empty string
    if [ "\$database" != "" ]; then
        base_url="\${base_url}/\${database}"
    fi

    export  base_url

    echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
    """
    
    stub:
    """
    host = host.com
    user = user
    port = 3306

    echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
    """
}
