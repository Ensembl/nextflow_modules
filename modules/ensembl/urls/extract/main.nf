process URLS_EXTRACT {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), val(url_string)

    output:
    tuple val(meta), env(user), env(host), env(port), emit: connection_info
    tuple val(meta), env(password), emit: optional_password, optional: true
    tuple val(meta), env(database), emit: optional_database, optional: true
    path "versions.yml", emit: versions

    script:

    """
    # Extract and parse the MySQL URL
    url_string="${url_string}"

    # Use regex to extract all components
    if [[ "\$url_string" =~ ^mysql://([^:@]+)(:([^@]*))?@([^:]+):([0-9]+)(/([^/]*)?)?\$ ]]; then
        user="\${BASH_REMATCH[1]}"
        password="\${BASH_REMATCH[3]}"
        host="\${BASH_REMATCH[4]}"
        port="\${BASH_REMATCH[5]}"
        database="\${BASH_REMATCH[7]}"

        # Handle missing password or database
        [ -z "\$password" ] && password=""
        [ -z "\$database" ] && database=""
        export user host port password database
    else
        echo "Invalid MySQL URL format: \$url_string" >&2
        exit 1
    fi

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