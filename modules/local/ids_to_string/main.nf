//
process IDS_TO_STRING {


    conda (params.enable_conda ? "conda-forge::python=3.9.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'quay.io/biocontainers/python:3.9--1' }"

    input:
    someChannel
    output:
    idList

    script:
    def getIdsFromTuples(channel) {
    // Initialize an empty list to store the ids
        def ids = []
    // Iterate through the tuples in the channel
        channel.each { tuple ->
        // Add the id of the current tuple to the list
            ids << tuple.id
    }
        // Join the list of ids into a single string
        return ids.join(' ')
    }
    """
    idList = getIdsFromTuples(someChannel)
    """

}
