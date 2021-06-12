
rule get_vep_cache:
    output:
        directory("reference/vep/cache")
    params:
        species=config["vep"]["species"],
        build=config["vep"]["build"],
        release=config["vep"]["release"]
    log:
        "logs/vep/cache.log"
    container:
        config["singularity"]["vep"]
    wrapper:
        "v0.75.0/bio/vep/cache"
